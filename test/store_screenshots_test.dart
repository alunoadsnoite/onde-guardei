import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onde_guardei/domain/models.dart';
import 'package:onde_guardei/domain/repository.dart';
import 'package:onde_guardei/ui/app.dart';

void main() {
  testWidgets('render store screenshots with synthetic data', (tester) async {
    tester.view.physicalSize = const Size(720, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final previousShadows = debugDisableShadows;
    debugDisableShadows = false;
    addTearDown(() => debugDisableShadows = previousShadows);
    final font = File(Platform.environment['STORE_SCREENSHOT_FONT']!);
    await tester.runAsync(() async {
      final fontLoader = FontLoader('Roboto')
        ..addFont(Future.value(ByteData.sublistView(await font.readAsBytes())));
      await fontLoader.load();
      final icons = File('${font.parent.path}/MaterialIcons-Regular.otf');
      final iconLoader = FontLoader(
        'MaterialIcons',
      )..addFont(Future.value(ByteData.sublistView(await icons.readAsBytes())));
      await iconLoader.load();
    });
    final directory = await tester.runAsync(
      () => Directory.systemTemp.createTemp('onde-store-'),
    );
    final repo = CatalogRepository(directory!);
    await tester.runAsync(repo.load);
    final key = GlobalKey();
    Future<void> capture(String name) async {
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: OndeGuardeiApp(repository: repo),
        ),
      );
      await tester.pumpAndSettle();
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await tester.runAsync(
        () => boundary.toImage(pixelRatio: 2),
      );
      await tester.runAsync(() async {
        final bytes = await image!.toByteData(format: ui.ImageByteFormat.png);
        for (final locale in ['pt-BR', 'en-US']) {
          final file = File(
            'fastlane/metadata/android/$locale/images/phoneScreenshots/$name.png',
          );
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
        }
      });
      image!.dispose();
    }

    await capture('1-empty-catalog');
    final date = DateTime(2026, 1, 1);
    repo.data = Catalog(
      places: [
        const Place(id: 'room', name: 'Quarto'),
        const Place(id: 'drawer', name: 'Gaveta', parentId: 'room'),
      ],
      items: [
        StoredItem(
          id: 'keys',
          name: 'Chave reserva',
          placeId: 'drawer',
          createdAt: date,
          updatedAt: date,
        ),
        StoredItem(
          id: 'cable',
          name: 'Cabo de carregamento',
          placeId: 'drawer',
          createdAt: date,
          updatedAt: date,
        ),
      ],
    );
    repo.notifyListeners();
    await capture('2-illustrative-catalog');
    await tester.pumpWidget(const SizedBox());
    repo.dispose();
    await tester.runAsync(() => directory.delete(recursive: true));
    debugDisableShadows = previousShadows;
  }, skip: Platform.environment['GENERATE_STORE_SCREENSHOTS'] != '1');
}
