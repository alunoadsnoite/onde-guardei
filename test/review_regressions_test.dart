import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:onde_guardei/domain/models.dart';
import 'package:onde_guardei/domain/repository.dart';

void main() {
  test('review: fallback should preserve previous catalog photo', () async {
    final root = await Directory.systemTemp.createTemp('review-');
    try {
      final repo = CatalogRepository(root);
      await repo.load();
      final source = File('${root.path}/source');
      await source.writeAsBytes([1]);
      final photo = await repo.copyPhoto(source.path);
      final obj = StoredItem(
        id: newId(),
        name: 'Foto',
        photo: photo,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await repo.saveItem(obj);
      await repo.deleteItem(obj.id);
      await File('${root.path}/catalog.json').writeAsString('corrupt');
      final recovered = CatalogRepository(root);
      await recovered.load();
      expect(recovered.data.items.single.photo, photo);
      expect(
        await recovered.photoFile(photo).exists(),
        isTrue,
        reason: 'Fallback references a deleted photo',
      );
    } finally {
      await root.delete(recursive: true);
    }
  });
}
