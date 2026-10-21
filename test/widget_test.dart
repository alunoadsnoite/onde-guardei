import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onde_guardei/domain/models.dart';
import 'package:onde_guardei/domain/repository.dart';
import 'package:onde_guardei/ui/app.dart';
import 'package:onde_guardei/ui/editing.dart';
import 'package:onde_guardei/ui/home.dart';

class ScreenRepository extends CatalogRepository {
  ScreenRepository(super.directory);
  @override
  Future<Map<String, dynamic>?> readDraft() async => null;
  @override
  Future<void> saveDraft(Map<String, dynamic>? draft) async {}
  @override
  Future<void> saveItem(StoredItem item) async {
    data = Catalog(items: [item]);
    notifyListeners();
  }
}

void main() {
  testWidgets('cadastra objeto e volta para a lista após salvar', (
    tester,
  ) async {
    final directory = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('onde-ui-'),
    ))!;
    final repo = ScreenRepository(directory);
    await tester.runAsync(repo.load);
    await tester.pumpWidget(OndeGuardeiApp(repository: repo));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar objeto'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Chave reserva');
    final button = find.byKey(const ValueKey('save-item'));
    await tester.scrollUntilVisible(
      button,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.runAsync(() async {
      await tester.tap(button);
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();
    expect(repo.data.items.single.name, 'Chave reserva');
    expect(find.text('Chave reserva'), findsOneWidget);
    expect(find.byType(ItemEditor), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    repo.dispose();
    await tester.runAsync(() => directory.delete(recursive: true));
  });
  testWidgets('tela inicial suporta fonte ampliada em telefone estreito', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final directory = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('onde-ui-'),
    ))!;
    final repo = ScreenRepository(directory);
    await tester.runAsync(repo.load);
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme(),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 640),
            textScaler: TextScaler.linear(2),
          ),
          child: Home(repo),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    repo.dispose();
    await tester.runAsync(() => directory.delete(recursive: true));
  });
}
