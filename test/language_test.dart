import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onde_guardei/domain/models.dart';
import 'package:onde_guardei/domain/repository.dart';
import 'package:onde_guardei/ui/app.dart';

class MemoryRepository extends CatalogRepository {
  MemoryRepository(super.directory);

  @override
  Future<void> saveLanguage(String tag) async => languageTag = tag;
}

void main() {
  test('restores the saved language from disk', () async {
    final directory = await Directory.systemTemp.createTemp(
      'onde-language-disk',
    );
    addTearDown(() => directory.delete(recursive: true));
    final first = CatalogRepository(directory);
    await first.loadLanguage();
    expect(first.languageTag, isNull);
    await first.saveLanguage('en-US');
    await first.saveLanguage('es');
    final second = CatalogRepository(directory);
    await second.loadLanguage();
    expect(second.languageTag, 'es');
  });

  testWidgets('switches languages and honors the saved choice on startup', (
    tester,
  ) async {
    final directory = Directory.systemTemp.createTempSync('onde-language');
    addTearDown(() => directory.deleteSync(recursive: true));
    final first = MemoryRepository(directory);
    final now = DateTime.now();
    first.data = Catalog(
      items: [
        StoredItem(
          id: 'test',
          name: 'Chave da garagem',
          createdAt: now,
          updatedAt: now,
        ),
      ],
    );
    await tester.pumpWidget(OndeGuardeiApp(repository: first));
    await tester.pumpAndSettle();
    expect(find.text('Guardar objeto'), findsOneWidget);

    Future<void> choose(
      String menu,
      String label,
      String language,
      String tag,
    ) async {
      await tester.tap(find.byTooltip(menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      await tester.tap(find.text(language));
      await tester.pumpAndSettle();
      expect(first.languageTag, tag);
      await tester.pumpAndSettle();
    }

    await choose('Configurações e backup', 'Idioma', 'English (US)', 'en-US');
    expect(find.text('Store item'), findsOneWidget);
    await choose('Settings and backup', 'Language', 'Español', 'es');
    expect(find.text('Lugares'), findsOneWidget);
    expect(find.text('Chave da garagem'), findsOneWidget);

    final second = MemoryRepository(directory)
      ..languageTag = first.languageTag
      ..data = first.data;
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(OndeGuardeiApp(repository: second));
    await tester.pumpAndSettle();
    expect(find.text('Lugares'), findsOneWidget);
    expect(find.text('Chave da garagem'), findsOneWidget);
  });
}
