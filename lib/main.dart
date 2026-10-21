import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:onde_guardei/ui/app.dart';
import 'package:onde_guardei/domain/repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Bootstrap());
}

class Bootstrap extends StatefulWidget {
  const Bootstrap({super.key});
  @override
  State<Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<Bootstrap> {
  late Future<CatalogRepository> future = open();
  Future<CatalogRepository> open() async {
    final root = Directory(
      (await nativeFiles.invokeMethod<String>('dataDirectory'))!,
    );
    final repo = CatalogRepository(Directory('${root.path}/catalog'));
    await repo.load();
    if (Platform.isAndroid) {
      try {
        final lost = await ImagePicker().retrieveLostData();
        if (lost.files?.isNotEmpty ?? false) {
          final photo = await repo.copyPhoto(lost.files!.first.path);
          final draft = await repo.readDraft() ?? <String, dynamic>{};
          draft['photo'] = photo;
          await repo.saveDraft(draft);
        }
      } catch (_) {
        repo.recoveryNotice ??=
            'Não foi possível recuperar a última foto. Você pode selecioná-la novamente.';
      }
    }
    return repo;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.hasData) return OndeGuardeiApp(repository: snapshot.data!);
      return MaterialApp(
        theme: appTheme(),
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: snapshot.hasError
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.folder_off_outlined,
                            size: 48,
                            color: Color(0xFF234B40),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Não conseguimos abrir seu catálogo.',
                            style: TextStyle(fontSize: 22),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Os arquivos foram preservados. Não reinstale o app; tente abrir novamente.',
                          ),
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: () => setState(() => future = open()),
                            child: const Text('Tentar novamente'),
                          ),
                        ],
                      )
                    : const CircularProgressIndicator(),
              ),
            ),
          ),
        ),
      );
    },
  );
}
