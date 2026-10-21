// Repositório: leitura/escrita do catálogo, fotos, rascunhos, backup/restore.
// Mantém o estado em disco e notifica os listeners da UI.

import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:onde_guardei/domain/models.dart';

const maxPhotoBytes = 15 * 1024 * 1024;
const maxBackupPhotosBytes = 70 * 1024 * 1024;
const maxBackupFileBytes = 100 * 1024 * 1024;

/// Resultado de uma exportação: o arquivo e a contagem de fotos que não
/// estavam no aparelho e por isso ficaram de fora.
class BackupResult {
  final File file;
  final int missingPhotos;
  const BackupResult(this.file, this.missingPhotos);
}

class CatalogRepository extends ChangeNotifier {
  final Directory directory;
  Catalog data = const Catalog();
  String? recoveryNotice;
  bool _mainTrusted = true;
  Future<void> _tail = Future.value();
  Future<void> _draftTail = Future.value();

  /// Fotos copiadas nesta sessão que ainda não entraram em um cadastro.
  final Set<String> _pendingPhotos = {};

  CatalogRepository(this.directory);
  File get _file => File('${directory.path}/catalog.json');
  File get _previous => File('${directory.path}/catalog.previous.json');
  File get _draftFile => File('${directory.path}/draft.json');
  File photoFile(String name) {
    if (!Catalog.validPhoto(name)) {
      throw const FormatException('Nome de foto inválido.');
    }
    return File('${directory.path}/photos/$name');
  }

  Future<void> load() async {
    await Directory('${directory.path}/photos').create(recursive: true);
    await _removeLeftoverBackups();
    if (!await _file.exists() && !await _previous.exists()) return;
    try {
      data = Catalog.fromJson(
        jsonDecode(await _file.readAsString()) as Map<String, dynamic>,
      );
    } catch (_) {
      try {
        data = Catalog.fromJson(
          jsonDecode(await _previous.readAsString()) as Map<String, dynamic>,
        );
        _mainTrusted = false;
        recoveryNotice =
            'Recuperamos a versão anterior dos seus cadastros. Crie um backup.';
      } catch (_) {
        throw const FormatException(
          'Não foi possível abrir os dados. Seus arquivos foram preservados; não reinstale o aplicativo.',
        );
      }
    }
    notifyListeners();
    if (_mainTrusted) await _removeUnreferencedPhotos();
  }

  /// Apaga backups temporários que ficaram na pasta quando o app foi
  /// fechado no meio de uma exportação.
  Future<void> _removeLeftoverBackups() async {
    try {
      await for (final entry in directory.list()) {
        if (entry is File && entry.path.endsWith('.ondeguardei.json')) {
          await entry.delete();
        }
      }
    } catch (_) {
      // Sem permissões ou pasta ainda vazia: nada a fazer.
    }
  }

  Future<T> _queue<T>(Future<T> Function() action) {
    final next = _tail.then((_) => action());
    _tail = next.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return next;
  }

  Future<void> _persist(Catalog next) async {
    next.validate();
    final text = jsonEncode(next.toJson());
    final temporary = File('${_file.path}.tmp');
    await temporary.writeAsString(text, flush: true);
    if (_mainTrusted && await _file.exists()) {
      final backupTemp = await _file.copy('${_previous.path}.tmp');
      await backupTemp.rename(_previous.path);
    }
    await temporary.rename(_file.path);
    _mainTrusted = true;
    data = next;
    final saved = data.items.map((i) => i.photo).whereType<String>();
    _pendingPhotos.removeAll(saved);
    notifyListeners();
    await _removeUnreferencedPhotos();
  }

  /// Apaga fotos que não são mais usadas por nenhum cadastro nem pelo
  /// rascunho em andamento. Devolve quantas fotos foram removidas.
  Future<int> _removeUnreferencedPhotos() async {
    final folder = Directory('${directory.path}/photos');
    if (!await folder.exists()) return 0;
    final keep = data.items.map((i) => i.photo).whereType<String>().toSet();
    keep.addAll(await _previousPhotos());
    final draft = await readDraft();
    final draftPhoto = draft?['photo'];
    if (draftPhoto is String) keep.add(draftPhoto);
    keep.addAll(_pendingPhotos);
    var removed = 0;
    try {
      await for (final entry in folder.list()) {
        if (entry is! File) continue;
        final name = entry.uri.pathSegments.last;
        if (!Catalog.validPhoto(name) || keep.contains(name)) continue;
        await entry.delete();
        removed++;
      }
    } catch (_) {
      // Sem permissão para limpar: as fotos ficam onde estão.
    }
    return removed;
  }

  /// A cópia de recuperação precisa conservar também seus arquivos de foto.
  Future<Set<String>> _previousPhotos() async {
    if (!await _previous.exists()) return {};
    try {
      final previous = Catalog.fromJson(
        jsonDecode(await _previous.readAsString()) as Map<String, dynamic>,
      );
      return previous.items
          .map((item) => item.photo)
          .whereType<String>()
          .toSet();
    } catch (_) {
      // Não limpe fotos enquanto a cópia de recuperação não puder ser lida.
      final folder = Directory('${directory.path}/photos');
      if (!await folder.exists()) return {};
      return (await folder.list().toList())
          .whereType<File>()
          .map((file) => file.uri.pathSegments.last)
          .toSet();
    }
  }

  Future<void> savePlace(Place place) => _queue(() async {
    await _persist(
      Catalog(
        items: data.items,
        places: [...data.places.where((p) => p.id != place.id), place],
      ),
    );
  });
  Future<void> deletePlace(String id) => _queue(() async {
    if (data.places.any((p) => p.parentId == id) ||
        data.items.any((i) => i.placeId == id)) {
      throw const FormatException(
        'Mova os objetos e os locais de dentro antes de excluir este local.',
      );
    }
    await _persist(
      Catalog(
        items: data.items,
        places: data.places.where((p) => p.id != id).toList(),
      ),
    );
  });
  Future<void> saveItem(StoredItem item) => _queue(() => _saveItem(item));
  Future<void> _saveItem(StoredItem item) async {
    if (item.photo != null && !await photoFile(item.photo!).exists()) {
      throw const FormatException(
        'A foto não está disponível. Selecione-a novamente.',
      );
    }
    final old = data.items.where((i) => i.id == item.id).firstOrNull;
    final moved = old != null && old.placeId != item.placeId;
    final next = StoredItem(
      id: item.id,
      name: item.name.trim(),
      notes: item.notes.trim(),
      keywords: item.keywords.trim(),
      placeId: item.placeId,
      photo: item.photo,
      createdAt: old?.createdAt ?? item.createdAt,
      updatedAt: DateTime.now().toUtc(),
      moves: [
        ...?old?.moves,
        if (moved)
          Move(
            data.path(old.placeId),
            data.path(item.placeId),
            DateTime.now().toUtc(),
          ),
      ],
    );
    await _persist(
      Catalog(
        places: data.places,
        items: [...data.items.where((i) => i.id != item.id), next],
      ),
    );
  }

  Future<void> moveItem(String id, String? placeId) => _queue(() async {
    final i = data.items.firstWhere((i) => i.id == id);
    await _saveItem(
      StoredItem(
        id: i.id,
        name: i.name,
        notes: i.notes,
        keywords: i.keywords,
        photo: i.photo,
        placeId: placeId,
        createdAt: i.createdAt,
        updatedAt: i.updatedAt,
      ),
    );
  });
  Future<void> deleteItem(String id) => _queue(
    () => _persist(
      Catalog(
        places: data.places,
        items: data.items.where((i) => i.id != id).toList(),
      ),
    ),
  );
  Future<String> copyPhoto(String source) async {
    final original = File(source);
    if (!await original.exists()) {
      throw const FormatException(
        'A foto escolhida não está mais disponível. Selecione-a novamente.',
      );
    }
    if (await original.length() > maxPhotoBytes) {
      throw const FormatException('Escolha uma foto de até 15 MB.');
    }
    final name = '${newId()}.img';
    final target = photoFile(name);
    try {
      await original.copy(target.path);
    } catch (_) {
      if (await target.exists()) await target.delete();
      throw const FormatException(
        'Não foi possível copiar a foto para o aplicativo.',
      );
    }
    _pendingPhotos.add(name);
    return name;
  }

  /// Esquece uma foto que o usuário tirou do cadastro e apaga o arquivo,
  /// se mais nada estiver usando ele.
  Future<void> discardPhoto(String? name) async {
    if (name == null || !Catalog.validPhoto(name)) return;
    _pendingPhotos.remove(name);
    if (data.items.any((i) => i.photo == name)) return;
    if ((await _previousPhotos()).contains(name)) return;
    final draft = await readDraft();
    if (draft?['photo'] == name) return;
    final file = photoFile(name);
    if (await file.exists()) await file.delete();
  }

  /// Tira da tela o aviso de recuperação, sem mexer nos dados.
  void dismissNotice() {
    if (recoveryNotice == null) return;
    recoveryNotice = null;
    notifyListeners();
  }

  Future<void> saveDraft(Map<String, dynamic>? draft) {
    final next = _draftTail.then((_) => _writeDraft(draft));
    _draftTail = next.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return next;
  }

  Future<void> _writeDraft(Map<String, dynamic>? draft) async {
    final f = _draftFile;
    if (draft == null) {
      if (await f.exists()) await f.delete();
      return;
    }
    final tmp = File('${f.path}.tmp');
    await tmp.writeAsString(jsonEncode(draft), flush: true);
    await tmp.rename(f.path);
  }

  Future<Map<String, dynamic>?> readDraft() async {
    try {
      return jsonDecode(await _draftFile.readAsString())
          as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<BackupResult> exportBackup() => _queue(() async {
    final wanted = data.items.map((i) => i.photo).whereType<String>().toSet();
    final photos = <String, String>{};
    var size = 0;
    for (final name in wanted) {
      final file = photoFile(name);
      if (!await file.exists()) {
        throw const FormatException(
          'Não foi possível criar o backup porque uma foto não está no aparelho. '
          'Selecione novamente ou remova as fotos indisponíveis dos cadastros e tente outra vez.',
        );
      }
      final bytes = await file.length();
      if (size + bytes > maxBackupPhotosBytes) {
        throw const FormatException(
          'Este catálogo excede o limite de 70 MB de fotos por backup nesta versão.',
        );
      }
      size += bytes;
      photos[name] = base64Encode(await file.readAsBytes());
    }
    final file = File('${directory.path}/backup-${newId()}.ondeguardei.json');
    final out = file.openWrite();
    try {
      out.write(
        '{"format":"onde-guardei-backup","version":1,"catalog":${jsonEncode(data.toJson())},"photos":{',
      );
      var first = true;
      for (final entry in photos.entries) {
        if (!first) out.write(',');
        first = false;
        out.write('${jsonEncode(entry.key)}:${jsonEncode(entry.value)}');
      }
      out.write('}}');
      await out.flush();
    } finally {
      await out.close();
    }
    return BackupResult(file, 0);
  });

  Future<void> restoreBackup(File file) => _queue(() async {
    if (await file.length() > maxBackupFileBytes) {
      throw const FormatException('O arquivo excede o limite de 100 MB.');
    }
    Map<String, dynamic> j;
    try {
      j = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      throw const FormatException(
        'Este arquivo não é um backup válido do Onde Guardei?.',
      );
    }
    if (j['format'] != 'onde-guardei-backup' || j['version'] != 1) {
      throw const FormatException(
        'Este arquivo não é um backup do Onde Guardei?.',
      );
    }
    final Catalog restored;
    try {
      restored = Catalog.fromJson(
        Map<String, dynamic>.from(j['catalog'] as Map),
      );
    } catch (_) {
      throw const FormatException(
        'O backup está corrompido e não pôde ser lido. Tente outro arquivo.',
      );
    }
    final rawPhotos = j['photos'];
    if (rawPhotos is! Map) {
      throw const FormatException(
        'Este backup está sem as fotos e não pode ser restaurado.',
      );
    }
    final images = Map<String, dynamic>.from(rawPhotos);
    final mapping = <String, String>{};
    final created = <File>[];
    try {
      for (final old
          in restored.items.map((i) => i.photo).whereType<String>().toSet()) {
        if (images[old] is! String) {
          throw const FormatException(
            'Este backup está sem alguma das fotos e não pode ser restaurado.',
          );
        }
        final bytes = base64Decode(images[old] as String);
        if (bytes.length > maxPhotoBytes) {
          throw const FormatException('Uma foto do backup excede 15 MB.');
        }
        final name = '${newId()}.img';
        final target = photoFile(name);
        created.add(target);
        await target.writeAsBytes(bytes, flush: true);
        mapping[old] = name;
      }
      await _persist(
        Catalog(
          places: restored.places,
          items: restored.items
              .map(
                (i) => StoredItem(
                  id: i.id,
                  name: i.name,
                  notes: i.notes,
                  keywords: i.keywords,
                  placeId: i.placeId,
                  photo: mapping[i.photo],
                  createdAt: i.createdAt,
                  updatedAt: i.updatedAt,
                  moves: i.moves,
                ),
              )
              .toList(),
        ),
      );
    } catch (_) {
      for (final f in created) {
        if (await f.exists()) await f.delete();
      }
      rethrow;
    }
  });
}
