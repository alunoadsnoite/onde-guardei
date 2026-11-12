import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onde_guardei/domain/models.dart';
import 'package:onde_guardei/domain/repository.dart';
import 'package:onde_guardei/ui/app.dart';
import 'package:onde_guardei/ui/catalog_strings.dart';
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
  testWidgets('idioma muda a interface e preserva os textos do catálogo', (
    tester,
  ) async {
    final repo = ScreenRepository(Directory.systemTemp);
    addTearDown(repo.dispose);
    repo.data = Catalog(
      items: [
        StoredItem(
          id: 'key',
          name: 'Minha chave',
          notes: 'Perto da porta',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      ],
    );
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    String? savedLanguage;
    messenger.setMockMethodCallHandler(nativeFiles, (call) async {
      switch (call.method) {
        case 'readLanguage':
          return savedLanguage;
        case 'writeLanguage':
          savedLanguage = call.arguments as String;
          return null;
        default:
          return null;
      }
    });
    addTearDown(() => messenger.setMockMethodCallHandler(nativeFiles, null));
    expect(await readAppLanguage(), AppLanguage.portuguese);
    await tester.pumpWidget(OndeGuardeiApp(repository: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Configurações e backup'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Idioma'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(savedLanguage, 'en-US');
    expect(find.text('Items'), findsOneWidget);
    expect(find.text('Save item'), findsOneWidget);
    expect(find.text('Minha chave'), findsOneWidget);
    expect(find.text('No location set'), findsOneWidget);

    await tester.tap(find.byTooltip('Settings and backup'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Español'));
    await tester.pumpAndSettle();
    expect(await readAppLanguage(), AppLanguage.spanish);
    expect(find.text('Guardar objeto'), findsOneWidget);
    expect(repo.data.items.single.notes, 'Perto da porta');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('aparência acompanha o aparelho e guarda os três modos', (
    tester,
  ) async {
    final repo = ScreenRepository(Directory.systemTemp);
    addTearDown(repo.dispose);
    final dispatcher = tester.binding.platformDispatcher;
    dispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(dispatcher.clearPlatformBrightnessTestValue);
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    String? savedMode;
    messenger.setMockMethodCallHandler(nativeFiles, (call) async {
      switch (call.method) {
        case 'readThemeMode':
          return savedMode;
        case 'writeThemeMode':
          savedMode = call.arguments as String;
          return null;
      }
      throw MissingPluginException();
    });
    addTearDown(() => messenger.setMockMethodCallHandler(nativeFiles, null));

    await tester.pumpWidget(OndeGuardeiApp(repository: repo));
    await tester.pumpAndSettle();
    Brightness brightness() =>
        Theme.of(tester.element(find.byType(Home))).brightness;
    expect(brightness(), Brightness.dark);

    Future<void> choose(String label) async {
      await tester.tap(find.byTooltip('Configurações e backup'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aparência'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }

    await choose('Claro');
    expect(await readThemeMode(), ThemeMode.light);
    expect(brightness(), Brightness.light);

    await choose('Escuro');
    expect(await readThemeMode(), ThemeMode.dark);
    expect(brightness(), Brightness.dark);

    dispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pumpAndSettle();
    expect(brightness(), Brightness.dark);
    await choose('Automático');
    expect(await readThemeMode(), ThemeMode.system);
    expect(brightness(), Brightness.light);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('suporte mostra o desenvolvedor e abre um e-mail', (
    tester,
  ) async {
    final repo = ScreenRepository(Directory.systemTemp);
    addTearDown(repo.dispose);
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    MethodCall? emailCall;
    messenger.setMockMethodCallHandler(nativeFiles, (call) async {
      emailCall = call;
      return true;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(nativeFiles, null));

    await tester.pumpWidget(OndeGuardeiApp(repository: repo));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Configurações e backup'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sobre e suporte'));
    await tester.pumpAndSettle();
    expect(find.text('Valdenor Tavares'), findsOneWidget);
    expect(find.text('valdenor.sa@proton.me'), findsOneWidget);
    await tester.tap(find.text('Enviar e-mail'));
    await tester.pumpAndSettle();
    expect(emailCall?.method, 'openEmail');
    expect(emailCall?.arguments['address'], 'valdenor.sa@proton.me');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('busca partes do caminho e destaca o local selecionado', (
    tester,
  ) async {
    final repo = ScreenRepository(Directory.systemTemp)
      ..data = const Catalog(
        places: [
          Place(id: 'quarto', name: 'Quarto'),
          Place(id: 'armario', name: 'Armário', parentId: 'quarto'),
          Place(id: 'gaveta', name: 'Segunda gaveta', parentId: 'armario'),
        ],
      );
    addTearDown(repo.dispose);
    await tester.pumpWidget(
      MaterialApp(home: PlacePicker(repo, selectedId: 'gaveta')),
    );
    await tester.enterText(find.byType(TextField), 'gaveta armario');
    await tester.pumpAndSettle();
    final result = find.widgetWithText(ListTile, 'Segunda gaveta');
    expect(tester.widget<ListTile>(result).selected, isTrue);
    expect(find.widgetWithText(ListTile, 'Armário'), findsNothing);
  });

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
          child: Home(
            repo,
            themeMode: ThemeMode.system,
            onThemeChanged: (_) async {},
            language: AppLanguage.portuguese,
            onLanguageChanged: (_) async {},
          ),
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
