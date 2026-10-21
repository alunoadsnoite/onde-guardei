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

/// Repositório que guarda o rascunho em memória, para o teste não depender
/// de tempo de disco.
class RecordingRepository extends CatalogRepository {
  RecordingRepository(super.directory);
  Map<String, dynamic>? lastDraft;
  @override
  Future<Map<String, dynamic>?> readDraft() async => null;
  @override
  Future<void> saveDraft(Map<String, dynamic>? draft) async {
    lastDraft = draft;
  }
}

Future<Directory> tempDir() async =>
    (await Directory.systemTemp.createTemp('onde-ui-'));

void main() {
  testWidgets('cadastra objeto e volta para a lista após salvar', (
    tester,
  ) async {
    final directory = (await tester.runAsync(tempDir))!;
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
    final directory = (await tester.runAsync(tempDir))!;
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
  testWidgets('escolher um local limpa o texto da busca', (tester) async {
    final directory = (await tester.runAsync(tempDir))!;
    final repo = ScreenRepository(directory);
    await tester.runAsync(repo.load);
    final quarto = Place(id: newId(), name: 'Quarto');
    repo.data = Catalog(
      places: [quarto],
      items: [
        StoredItem(
          id: newId(),
          name: 'Chave',
          placeId: quarto.id,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        ),
      ],
    );
    repo.notifyListeners();
    await tester.pumpWidget(OndeGuardeiApp(repository: repo));
    await tester.pumpAndSettle();
    final field = find.byType(TextField).first;
    await tester.enterText(field, 'cabo');
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(field).controller?.text, 'cabo');
    await tester.tap(find.text('Locais'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quarto'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(field).controller?.text, isEmpty);
    expect(find.text('Quarto'), findsWidgets);
    await tester.pumpWidget(const SizedBox());
    repo.dispose();
    await tester.runAsync(() => directory.delete(recursive: true));
  });
  testWidgets('rascunho é guardado quando o app vai para segundo plano', (
    tester,
  ) async {
    final directory = (await tester.runAsync(tempDir))!;
    final repo = RecordingRepository(directory);
    await tester.runAsync(repo.load);
    await tester.pumpWidget(OndeGuardeiApp(repository: repo));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar objeto'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Cabo de rede');
    await tester.pumpAndSettle();
    expect(repo.lastDraft, isNull);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();
    expect(repo.lastDraft?['name'], 'Cabo de rede');
    await tester.pumpWidget(const SizedBox());
    repo.dispose();
    await tester.runAsync(() => directory.delete(recursive: true));
  });
}
