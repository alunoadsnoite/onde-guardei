// Repositório: leitura/escrita do catálogo, fotos, rascunhos, backup/restore.
// Mantém o estado em disco e notifica os listeners da UI.

import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:onde_guardei/domain/models.dart';

class CatalogRepository extends ChangeNotifier {
  final Directory directory;
  Catalog data = const Catalog();
  String? recoveryNotice;
  bool _mainTrusted = true;
  Future<void> _tail = Future.value();
  CatalogRepository(this.directory);
  File get _file => File('${directory.path}/catalog.json');
  File get _previous => File('${directory.path}/catalog.previous.json');
  File photoFile(String name) {
    if (!Catalog.validPhoto(name)) {
      throw const FormatException('Nome de foto inválido.');
    }
    return File('${directory.path}/photos/$name');
  }

  Future<void> load() async {
    await Directory('${directory.path}/photos').create(recursive: true);
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
    notifyListeners();
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
    if (await original.length() > 15 * 1024 * 1024) {
      throw const FormatException('Escolha uma foto de até 15 MB.');
    }
    final name = '${newId()}.img';
    await original.copy(photoFile(name).path);
    return name;
  }

  Future<void> saveDraft(Map<String, dynamic>? draft) async {
    final f = File('${directory.path}/draft.json');
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
      return jsonDecode(
            await File('${directory.path}/draft.json').readAsString(),
          )
          as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<File> exportBackup() => _queue(() async {
    final photos = data.items.map((i) => i.photo).whereType<String>().toSet();
    var size = 0;
    for (final name in photos) {
      size += await photoFile(name).length();
    }
    if (size > 70 * 1024 * 1024) {
      throw const FormatException(
        'Este catálogo excede o limite de 70 MB de fotos por backup nesta versão.',
      );
    }
    final file = File('${directory.path}/backup-${newId()}.ondeguardei.json');
    final out = file.openWrite();
    try {
      out.write(
        '{"format":"onde-guardei-backup","version":1,"catalog":${jsonEncode(data.toJson())},"photos":{',
      );
      var first = true;
      for (final name in photos) {
        if (!first) out.write(',');
        first = false;
        out.write(
          '${jsonEncode(name)}:${jsonEncode(base64Encode(await photoFile(name).readAsBytes()))}',
        );
      }
      out.write('}}');
      await out.flush();
    } finally {
      await out.close();
    }
    return file;
  });
  Future<void> restoreBackup(File file) => _queue(() async {
    if (await file.length() > 100 * 1024 * 1024) {
      throw const FormatException('O arquivo excede o limite de 100 MB.');
    }
    final j = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    if (j['format'] != 'onde-guardei-backup' || j['version'] != 1) {
      throw const FormatException(
        'Este arquivo não é um backup do Onde Guardei?.',
      );
    }
    final restored = Catalog.fromJson(
      Map<String, dynamic>.from(j['catalog'] as Map),
    );
    final images = Map<String, dynamic>.from(j['photos'] as Map);
    final mapping = <String, String>{};
    final created = <File>[];
    try {
      for (final old
          in restored.items.map((i) => i.photo).whereType<String>().toSet()) {
        if (images[old] is! String) {
          throw const FormatException('O backup está sem uma das fotos.');
        }
        final bytes = base64Decode(images[old] as String);
        if (bytes.length > 15 * 1024 * 1024) {
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
