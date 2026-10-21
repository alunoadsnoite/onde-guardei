import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:onde_guardei/domain/models.dart';
import 'package:onde_guardei/domain/repository.dart';

void main() {
  late Directory root;
  late CatalogRepository repo;
  StoredItem item(String name, {String? id, String? place, String? photo}) =>
      StoredItem(
        id: id ?? newId(),
        name: name,
        placeId: place,
        photo: photo,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );
  setUp(() async {
    root = await Directory.systemTemp.createTemp('onde-test-');
    repo = CatalogRepository(root);
    await repo.load();
  });
  tearDown(() async {
    repo.dispose();
    await root.delete(recursive: true);
  });
  test(
    'busca sem acentos, palavras combinadas e locais descendentes',
    () async {
      final room = Place(id: newId(), name: 'Escritório');
      final box = Place(id: newId(), name: 'Caixa azul', parentId: room.id);
      await repo.savePlace(room);
      await repo.savePlace(box);
      await repo.saveItem(item('Óculos', place: box.id));
      expect(repo.data.search('oculos escritorio', placeId: room.id).length, 1);
      expect(repo.data.search('oculos cozinha'), isEmpty);
    },
  );
  test('busca ignora acentos, cedilha e til extras', () async {
    await repo.saveItem(item('Café com açucar'));
    expect(repo.data.search('cafe acucar').length, 1);
    expect(repo.data.search('CAFE').length, 1);
    expect(repo.data.search('cafe').length, 1);
  });
  test('gravações simultâneas preservam todos os objetos', () async {
    await Future.wait(
      List.generate(12, (i) => repo.saveItem(item('Objeto $i'))),
    );
    final reopened = CatalogRepository(root);
    await reopened.load();
    expect(reopened.data.items.length, 12);
    reopened.dispose();
  });
  test('movimento mantém criação e registra caminhos anteriores', () async {
    final a = Place(id: newId(), name: 'Sala');
    final b = Place(id: newId(), name: 'Quarto');
    await repo.savePlace(a);
    await repo.savePlace(b);
    final obj = item('Chaves', place: a.id);
    await repo.saveItem(obj);
    await repo.moveItem(obj.id, a.id);
    expect(repo.data.items.single.moves, isEmpty);
    await repo.moveItem(obj.id, b.id);
    expect(repo.data.items.single.createdAt, obj.createdAt);
    expect(repo.data.items.single.moves.single.from, 'Sala');
    await repo.savePlace(Place(id: a.id, name: 'Sala nova'));
    expect(repo.data.items.single.moves.single.from, 'Sala');
  });
  test(
    'locais com ciclos e exclusão de local ocupado são rejeitados',
    () async {
      final a = Place(id: newId(), name: 'Sala');
      await repo.savePlace(a);
      await expectLater(
        repo.savePlace(Place(id: a.id, name: 'Sala', parentId: a.id)),
        throwsFormatException,
      );
      await repo.saveItem(item('Livro', place: a.id));
      await expectLater(repo.deletePlace(a.id), throwsFormatException);
      expect(repo.data.places.single.parentId, isNull);
    },
  );
  test(
    'foto é copiada e backup restaura bytes em arquivo independente',
    () async {
      final source = File('${root.path}/original');
      await source.writeAsBytes([1, 2, 3, 4]);
      final photo = await repo.copyPhoto(source.path);
      await source.delete();
      await repo.saveItem(item('', photo: photo));
      final backup = await repo.exportBackup();
      final destination = Directory('${root.path}/restored');
      final other = CatalogRepository(destination);
      await other.load();
      await other.restoreBackup(backup.file);
      final restored = other.data.items.single.photo!;
      expect(restored, isNot(photo));
      expect(await other.photoFile(restored).readAsBytes(), [1, 2, 3, 4]);
      other.dispose();
    },
  );
  test('backup sem foto não substitui catálogo atual', () async {
    final source = File('${root.path}/original');
    await source.writeAsBytes([1]);
    await repo.saveItem(item('Foto', photo: await repo.copyPhoto(source.path)));
    final backup = await repo.exportBackup();
    final j =
        jsonDecode(await backup.file.readAsString()) as Map<String, dynamic>;
    j['photos'] = {};
    await backup.file.writeAsString(jsonEncode(j));
    await expectLater(repo.restoreBackup(backup.file), throwsFormatException);
    expect(repo.data.items.single.name, 'Foto');
    expect(() => repo.photoFile('../segredo'), throwsFormatException);
  });
  test('arquivo corrompido é recusado com mensagem amigável', () async {
    final file = File('${root.path}/quebrado.json');
    await file.writeAsString('isto não é um json');
    await expectLater(
      repo.restoreBackup(file),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'mensagem',
          contains('não é um backup válido'),
        ),
      ),
    );
  });
  test('recupera versão anterior após arquivo ausente ou corrompido', () async {
    await repo.saveItem(item('Primeiro'));
    await repo.saveItem(item('Segundo'));
    await File('${root.path}/catalog.json').delete();
    final recovered = CatalogRepository(root);
    await recovered.load();
    expect(recovered.data.items.single.name, 'Primeiro');
    expect(recovered.recoveryNotice, isNotNull);
    recovered.dispose();
  });
  test('dois arquivos danificados permanecem preservados', () async {
    final file = File('${root.path}/catalog.json');
    await file.writeAsString('danificado');
    await expectLater(repo.load(), throwsFormatException);
    expect(await file.readAsString(), 'danificado');
  });
  test('excluir objeto apaga a foto que ficou sem dono', () async {
    final source = File('${root.path}/original');
    await source.writeAsBytes([9, 9]);
    final photo = await repo.copyPhoto(source.path);
    final obj = item('Com foto', photo: photo);
    await repo.saveItem(obj);
    expect(await repo.photoFile(photo).exists(), isTrue);
    await repo.deleteItem(obj.id);
    expect(await repo.photoFile(photo).exists(), isFalse);
  });
  test('trocar a foto apaga a imagem antiga', () async {
    final source = File('${root.path}/original');
    await source.writeAsBytes([1]);
    final antiga = await repo.copyPhoto(source.path);
    final obj = item('Com foto', photo: antiga);
    await repo.saveItem(obj);
    final nova = await repo.copyPhoto(source.path);
    await repo.saveItem(
      StoredItem(
        id: obj.id,
        name: obj.name,
        photo: nova,
        createdAt: obj.createdAt,
        updatedAt: obj.updatedAt,
      ),
    );
    expect(await repo.photoFile(antiga).exists(), isFalse);
    expect(await repo.photoFile(nova).exists(), isTrue);
  });
  test('foto do rascunho não é apagada pela limpeza', () async {
    final source = File('${root.path}/original');
    await source.writeAsBytes([1]);
    final photo = await repo.copyPhoto(source.path);
    await repo.saveDraft({'id': newId(), 'photo': photo});
    await repo.saveItem(item('Outro objeto'));
    expect(await repo.photoFile(photo).exists(), isTrue);
  });
  test('backup avisa quando uma foto não está no aparelho', () async {
    final source = File('${root.path}/original');
    await source.writeAsBytes([1]);
    final photo = await repo.copyPhoto(source.path);
    await repo.saveItem(item('Com foto', photo: photo));
    await repo.photoFile(photo).delete();
    final backup = await repo.exportBackup();
    expect(backup.missingPhotos, 1);
    final j =
        jsonDecode(await backup.file.readAsString()) as Map<String, dynamic>;
    expect((j['photos'] as Map), isEmpty);
  });
  test('restaurar backup remove as fotos do catálogo anterior', () async {
    final source = File('${root.path}/original');
    await source.writeAsBytes([1]);
    final photo = await repo.copyPhoto(source.path);
    await repo.saveItem(item('Antes', photo: photo));
    final backup = await repo.exportBackup();
    await repo.saveItem(item('Depois do backup'));
    await repo.restoreBackup(backup.file);
    expect(repo.data.items.single.name, 'Antes');
    expect(await repo.photoFile(photo).exists(), isFalse);
  });
  test('caminho, contagem e ordem dos locais', () {
    final quarto = Place(id: newId(), name: 'Quarto');
    final armario = Place(id: newId(), name: 'Armário', parentId: quarto.id);
    final cozinha = Place(id: newId(), name: 'cozinha');
    final catalog = Catalog(
      places: [cozinha, armario, quarto],
      items: [item('Chave', place: armario.id)],
    );
    expect(catalog.path(armario.id), 'Quarto › Armário');
    expect(catalog.path(null), 'Sem local definido');
    expect(catalog.path(newId()), 'Local desconhecido');
    expect(catalog.itemsByPlace()[quarto.id], 1);
    expect(catalog.itemsByPlace()[cozinha.id], 0);
    expect(catalog.sortedPlaces().map((p) => p.name).toList(), [
      'cozinha',
      'Quarto',
      'Armário',
    ]);
  });
}
