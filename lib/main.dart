import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'catalog.dart';

const forest = Color(0xFF234B40);
const paper = Color(0xFFF7F5EF);
const ink = Color(0xFF263C35);
const nativeFiles = MethodChannel('br.com.valdenor.ondeguardei/files');

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
    final root = await getApplicationSupportDirectory();
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
                            color: forest,
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

ThemeData appTheme() => ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: paper,
  colorScheme: ColorScheme.fromSeed(
    seedColor: forest,
    primary: forest,
    surface: paper,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: paper,
    foregroundColor: ink,
    centerTitle: false,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(48, 52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
);

class OndeGuardeiApp extends StatelessWidget {
  final CatalogRepository repository;
  const OndeGuardeiApp({super.key, required this.repository});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Onde Guardei?',
    debugShowCheckedModeBanner: false,
    theme: appTheme(),
    home: Home(repository),
  );
}

String dateText(DateTime date) {
  final d = date.toLocal();
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

void message(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
String errorText(Object e) => e is FormatException
    ? e.message
    : 'Não foi possível concluir. Seus cadastros anteriores foram preservados. Tente novamente.';
Future<bool> confirm(
  BuildContext context,
  String title,
  String text,
  String action,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;

class Home extends StatefulWidget {
  final CatalogRepository repo;
  const Home(this.repo, {super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int tab = 0;
  String query = '';
  String? filter;
  bool working = false;
  Map<String, dynamic>? draft;
  CatalogRepository get repo => widget.repo;
  @override
  void initState() {
    super.initState();
    refreshDraft();
  }

  Future<void> refreshDraft() async {
    final d = await repo.readDraft();
    if (mounted) setState(() => draft = d);
  }

  Future<void> edit({Map<String, dynamic>? saved}) async {
    saved ??= draft;
    final existing = repo.data.items
        .where((i) => i.id == saved?['id'])
        .firstOrNull;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ItemEditor(repo, item: existing, draft: saved),
      ),
    );
    await refreshDraft();
  }

  Future<void> backup(bool restore) async {
    if (working) return;
    if (restore &&
        !await confirm(
          context,
          'Restaurar catálogo?',
          'O backup substituirá os objetos e locais atuais. Crie um backup antes se quiser guardar os dados que estão aqui.',
          'Escolher backup',
        )) {
      return;
    }
    if (!mounted) return;
    setState(() => working = true);
    File? temporary;
    try {
      if (restore) {
        final path = await nativeFiles.invokeMethod<String>('importBackup');
        if (path == null) return;
        temporary = File(path);
        await repo.restoreBackup(temporary);
        await repo.saveDraft(null);
        await refreshDraft();
        if (mounted) {
          setState(() => filter = null);
          message(context, 'Catálogo restaurado, com as fotos.');
        }
      } else {
        temporary = await repo.exportBackup();
        final saved = await nativeFiles.invokeMethod<bool>('exportBackup', {
          'path': temporary.path,
          'name':
              'Onde-Guardei-${DateTime.now().toIso8601String().substring(0, 10)}.ondeguardei.json',
        });
        if (saved == true && mounted) {
          message(context, 'Backup salvo com os cadastros e as fotos.');
        }
      }
    } catch (e) {
      if (mounted) message(context, errorText(e));
    } finally {
      if (temporary != null && await temporary.exists()) {
        await temporary.delete();
      }
      if (mounted) setState(() => working = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: repo,
    builder: (context, _) {
      final activeFilter = repo.data.places.any((p) => p.id == filter)
          ? filter
          : null;
      final items = repo.data.search(query, placeId: activeFilter);
      final places = [...repo.data.places]
        ..sort(
          (a, b) => normalize(
            repo.data.path(a.id),
          ).compareTo(normalize(repo.data.path(b.id))),
        );
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Onde Guardei?',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          actions: [
            PopupMenuButton<String>(
              tooltip: 'Backup e informações',
              enabled: !working,
              onSelected: (value) {
                if (value == 'export') {
                  backup(false);
                }
                if (value == 'import') {
                  backup(true);
                }
                if (value == 'about') {
                  showAboutDialog(
                    context: context,
                    applicationName: 'Onde Guardei?',
                    applicationVersion: '0.1.0',
                    applicationLegalese:
                        'Seu catálogo de objetos e locais da casa.\nFunciona sem conta e sem internet.\nFotos e textos ficam no seu aparelho.\nGuarde um backup fora do app antes de trocar de celular ou desinstalar.\n\nCódigo aberto • licença MIT',
                  );
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'export',
                  child: Text('Criar backup com fotos'),
                ),
                PopupMenuItem(value: 'import', child: Text('Restaurar backup')),
                PopupMenuItem(
                  value: 'about',
                  child: Text('Sobre e privacidade'),
                ),
              ],
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: working
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 20),
                      Text('Cuidando do seu catálogo…'),
                    ],
                  ),
                )
              : tab == 0
              ? CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Encontre o que você guardou.',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: ink,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${repo.data.items.length} objetos · ${repo.data.places.length} locais',
                              style: const TextStyle(color: forest),
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              onChanged: (value) =>
                                  setState(() => query = value),
                              decoration: const InputDecoration(
                                hintText: 'Buscar objeto, palavra ou local',
                                prefixIcon: Icon(Icons.search),
                                labelText: 'O que você está procurando?',
                              ),
                            ),
                            if (activeFilter != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: InputChip(
                                  label: Text(repo.data.path(activeFilter)),
                                  onDeleted: () =>
                                      setState(() => filter = null),
                                ),
                              ),
                            if (repo.recoveryNotice != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Text(
                                  repo.recoveryNotice!,
                                  style: const TextStyle(
                                    color: Color(0xFF95462D),
                                  ),
                                ),
                              ),
                            if (draft != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: OutlinedButton.icon(
                                  onPressed: () => edit(saved: draft),
                                  icon: const Icon(Icons.edit_note),
                                  label: const Text(
                                    'Continuar cadastro não salvo',
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                    if (items.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: EmptyState(
                          icon: repo.data.items.isEmpty
                              ? Icons.inventory_2_outlined
                              : Icons.search_off,
                          title: repo.data.items.isEmpty
                              ? 'Um lugar para lembrar.'
                              : 'Nada encontrado por aqui.',
                          text: repo.data.items.isEmpty
                              ? 'Cadastre seu primeiro objeto com uma foto, um nome ou os dois. Depois, conte onde ele fica.'
                              : 'Tente outra palavra ou escolha outro local.',
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        sliver: SliverList.separated(
                          itemCount: items.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) => ObjectTile(
                            repo,
                            items[index],
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    ItemDetail(repo, items[index].id),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                )
              : places.isEmpty
              ? const EmptyState(
                  icon: Icons.home_outlined,
                  title: 'Como você organiza sua casa?',
                  text:
                      'Crie um cômodo, depois um móvel ou uma caixa dentro dele. Exemplo: quarto › armário › caixa azul.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                  itemCount: places.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final p = places[index];
                    final count = repo.data.search('', placeId: p.id).length;
                    return Card(
                      color: Colors.white,
                      elevation: 0,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: const Icon(
                          Icons.location_on_outlined,
                          color: forest,
                        ),
                        title: Text(
                          p.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${repo.data.path(p.id)}\n$count objetos, incluindo os locais de dentro',
                        ),
                        isThreeLine: true,
                        onTap: () => setState(() {
                          filter = p.id;
                          query = '';
                          tab = 0;
                        }),
                        trailing: IconButton(
                          tooltip: 'Editar ${p.name}',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute<String>(
                              builder: (_) => PlaceEditor(repo, place: p),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (value) => setState(() => tab = value),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'Objetos',
            ),
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Locais',
            ),
          ],
        ),
        floatingActionButton: working
            ? null
            : FloatingActionButton.extended(
                onPressed: () async {
                  if (tab == 0) {
                    await edit();
                  } else {
                    if (mounted) {
                      await Navigator.push(
                        context,
                        MaterialPageRoute<String>(
                          builder: (_) => PlaceEditor(repo),
                        ),
                      );
                    }
                  }
                },
                backgroundColor: forest,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add),
                label: Text(tab == 0 ? 'Guardar objeto' : 'Criar local'),
              ),
      );
    },
  );
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, text;
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.text,
  });
  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: forest.withValues(alpha: .08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: forest),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w700,
              color: ink,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
        ],
      ),
    ),
  );
}

class PhotoView extends StatelessWidget {
  final CatalogRepository repo;
  final String? photo;
  const PhotoView(this.repo, this.photo, {super.key});
  @override
  Widget build(BuildContext context) => photo == null
      ? const ColoredBox(
          color: Color(0xFFE8EDE5),
          child: Center(
            child: Icon(Icons.inventory_2_outlined, color: forest, size: 38),
          ),
        )
      : Image.file(
          repo.photoFile(photo!),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const Center(
            child: Icon(Icons.broken_image_outlined, color: forest),
          ),
        );
}

class ObjectTile extends StatelessWidget {
  final CatalogRepository repo;
  final StoredItem item;
  final VoidCallback onTap;
  const ObjectTile(this.repo, this.item, {super.key, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 76,
                height: 84,
                child: PhotoView(repo, item.photo),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    repo.data.path(item.placeId),
                    style: const TextStyle(color: forest),
                  ),
                  if (item.keywords.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        item.keywords,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Icon(Icons.chevron_right, color: forest),
            ),
          ],
        ),
      ),
    ),
  );
}

class PlacePicker extends StatefulWidget {
  final CatalogRepository repo;
  final String? excluded;
  const PlacePicker(this.repo, {super.key, this.excluded});
  @override
  State<PlacePicker> createState() => _PlacePickerState();
}

class _PlacePickerState extends State<PlacePicker> {
  String query = '';
  bool allowed(Place p) {
    var current = p.id;
    final seen = <String>{};
    while (seen.add(current)) {
      if (current == widget.excluded) return false;
      final parent = widget.repo.data.places
          .where((p) => p.id == current)
          .firstOrNull
          ?.parentId;
      if (parent == null) break;
      current = parent;
    }
    return normalize(widget.repo.data.path(p.id)).contains(normalize(query));
  }

  @override
  Widget build(BuildContext context) {
    final places = widget.repo.data.places.where(allowed).toList()
      ..sort(
        (a, b) =>
            widget.repo.data.path(a.id).compareTo(widget.repo.data.path(b.id)),
      );
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.excluded == null ? 'Onde fica?' : 'Dentro de qual local?',
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: TextField(
                onChanged: (s) => setState(() => query = s),
                decoration: const InputDecoration(
                  labelText: 'Buscar local',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    leading: const Icon(Icons.home_outlined),
                    title: Text(
                      widget.excluded == null
                          ? 'Sem local definido'
                          : 'Na raiz da casa',
                    ),
                    onTap: () => Navigator.pop(context, ''),
                  ),
                  ...places.map(
                    (p) => ListTile(
                      leading: const Icon(Icons.folder_outlined),
                      title: Text(p.name),
                      subtitle: Text(widget.repo.data.path(p.id)),
                      onTap: () => Navigator.pop(context, p.id),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: widget.excluded != null
          ? null
          : FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: const Text('Novo local'),
              onPressed: () async {
                final id = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(builder: (_) => PlaceEditor(widget.repo)),
                );
                if (id != null && context.mounted) Navigator.pop(context, id);
              },
            ),
    );
  }
}

class PlaceEditor extends StatefulWidget {
  final CatalogRepository repo;
  final Place? place;
  const PlaceEditor(this.repo, {super.key, this.place});
  @override
  State<PlaceEditor> createState() => _PlaceEditorState();
}

class _PlaceEditorState extends State<PlaceEditor> {
  final form = GlobalKey<FormState>();
  late final TextEditingController name = TextEditingController(
    text: widget.place?.name,
  );
  late String? parent = widget.place?.parentId;
  bool saving = false;
  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.place == null ? 'Criar local' : 'Editar local'),
      actions: [
        if (widget.place != null)
          IconButton(
            tooltip: 'Excluir local',
            icon: const Icon(Icons.delete_outline),
            onPressed: saving
                ? null
                : () async {
                    if (!await confirm(
                      context,
                      'Excluir local?',
                      'Locais com objetos ou outros locais dentro precisam ser esvaziados primeiro.',
                      'Excluir',
                    )) {
                      return;
                    }
                    try {
                      await widget.repo.deletePlace(widget.place!.id);
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      if (context.mounted) message(context, errorText(e));
                    }
                  },
          ),
      ],
    ),
    body: SafeArea(
      child: Form(
        key: form,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Icon(Icons.folder_copy_outlined, size: 56, color: forest),
            const SizedBox(height: 24),
            TextFormField(
              controller: name,
              autofocus: widget.place == null,
              maxLength: 100,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nome do local',
                hintText: 'Quarto, armário, caixa azul…',
              ),
              validator: (s) => s == null || s.trim().isEmpty
                  ? 'Dê um nome a este local.'
                  : null,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.account_tree_outlined),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  parent == null
                      ? 'Fica na raiz da casa'
                      : widget.repo.data.path(parent),
                ),
              ),
              onPressed: saving
                  ? null
                  : () async {
                      final id = await Navigator.push<String>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlacePicker(
                            widget.repo,
                            excluded: widget.place?.id ?? 'new',
                          ),
                        ),
                      );
                      if (id != null && mounted) {
                        setState(() => parent = id.isEmpty ? null : id);
                      }
                    },
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: const Text('Salvar local'),
              onPressed: saving
                  ? null
                  : () async {
                      if (!form.currentState!.validate()) return;
                      setState(() => saving = true);
                      final id = widget.place?.id ?? newId();
                      try {
                        await widget.repo.savePlace(
                          Place(
                            id: id,
                            name: name.text.trim(),
                            parentId: parent,
                          ),
                        );
                        if (context.mounted) Navigator.pop(context, id);
                      } catch (e) {
                        if (context.mounted) message(context, errorText(e));
                      } finally {
                        if (mounted) setState(() => saving = false);
                      }
                    },
            ),
          ],
        ),
      ),
    ),
  );
}

class ItemEditor extends StatefulWidget {
  final CatalogRepository repo;
  final StoredItem? item;
  final Map<String, dynamic>? draft;
  const ItemEditor(this.repo, {super.key, this.item, this.draft});
  @override
  State<ItemEditor> createState() => _ItemEditorState();
}

class _ItemEditorState extends State<ItemEditor> {
  final form = GlobalKey<FormState>();
  late final name = TextEditingController(
    text: widget.draft?['name'] as String? ?? widget.item?.name ?? '',
  );
  late final notes = TextEditingController(
    text: widget.draft?['notes'] as String? ?? widget.item?.notes ?? '',
  );
  late final keywords = TextEditingController(
    text: widget.draft?['keywords'] as String? ?? widget.item?.keywords ?? '',
  );
  late final id =
      widget.item?.id ?? (widget.draft?['id'] as String? ?? newId());
  late String? photo = widget.draft?['photo'] as String? ?? widget.item?.photo;
  late String? place =
      widget.draft?['placeId'] as String? ?? widget.item?.placeId;
  bool busy = false, saved = false;
  @override
  void initState() {
    super.initState();
    if (!widget.repo.data.places.any((p) => p.id == place)) place = null;
  }

  @override
  void dispose() {
    name.dispose();
    notes.dispose();
    keywords.dispose();
    super.dispose();
  }

  Map<String, dynamic> get draft => {
    'id': id,
    'name': name.text,
    'notes': notes.text,
    'keywords': keywords.text,
    'photo': photo,
    'placeId': place,
  };
  Future<void> pick(ImageSource source) async {
    setState(() => busy = true);
    try {
      await widget.repo.saveDraft(draft);
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 82,
      );
      if (file != null) {
        final selected = await widget.repo.copyPhoto(file.path);
        photo = selected;
        await widget.repo.saveDraft(draft);
        if (mounted) setState(() {});
      }
    } catch (e) {
      if (mounted) {
        message(
          context,
          e is PlatformException
              ? 'Não foi possível abrir a câmera ou as fotos. Verifique a permissão nas configurações do Android.'
              : errorText(e),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    if (name.text.trim().isEmpty && photo == null) {
      message(
        context,
        'Adicione um nome ou uma foto para guardar este objeto.',
      );
      return;
    }
    setState(() => busy = true);
    try {
      final now = DateTime.now().toUtc();
      await widget.repo.saveItem(
        StoredItem(
          id: id,
          name: name.text,
          notes: notes.text,
          keywords: keywords.text,
          photo: photo,
          placeId: place,
          createdAt: widget.item?.createdAt ?? now,
          updatedAt: now,
        ),
      );
      await widget.repo.saveDraft(null);
      if (mounted) {
        setState(() => saved = true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (e) {
      if (mounted) message(context, errorText(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<bool> leave() async {
    if (saved) return true;
    if (busy) return false;
    if (name.text.isEmpty &&
        notes.text.isEmpty &&
        keywords.text.isEmpty &&
        photo == null) {
      return true;
    }
    if (await confirm(
      context,
      'Sair do cadastro?',
      'O que você escreveu será guardado como rascunho para continuar depois.',
      'Guardar e sair',
    )) {
      await widget.repo.saveDraft(draft);
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: saved,
    onPopInvokedWithResult: (didPop, _) async {
      if (didPop) return;
      if (await leave() && context.mounted) {
        setState(() => saved = true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) Navigator.pop(context);
        });
      }
    },
    child: Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? 'Guardar objeto' : 'Editar objeto'),
      ),
      body: SafeArea(
        child: Form(
          key: form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: SizedBox(
                  height: 190,
                  child: PhotoView(widget.repo, photo),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  OutlinedButton.icon(
                    onPressed: busy ? null : () => pick(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Tirar foto'),
                  ),
                  OutlinedButton.icon(
                    onPressed: busy ? null : () => pick(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Escolher foto'),
                  ),
                  if (photo != null)
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => setState(() => photo = null),
                      child: const Text('Remover foto'),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: name,
                maxLength: 120,
                decoration: const InputDecoration(
                  labelText: 'Nome do objeto',
                  hintText: 'Ex.: carregador do notebook',
                  helperText: 'Opcional se você adicionar uma foto',
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.location_on_outlined),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(widget.repo.data.path(place)),
                ),
                onPressed: busy
                    ? null
                    : () async {
                        final selected = await Navigator.push<String>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlacePicker(widget.repo),
                          ),
                        );
                        if (selected != null && mounted) {
                          setState(
                            () => place = selected.isEmpty ? null : selected,
                          );
                        }
                      },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: keywords,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Palavras para encontrar',
                  hintText: 'Ex.: cabo, Dell, computador',
                ),
                textCapitalization: TextCapitalization.none,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: notes,
                maxLength: 3000,
                minLines: 3,
                maxLines: 8,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Anotações',
                  hintText: 'Detalhes que ajudam você a lembrar',
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                key: const ValueKey('save-item'),
                onPressed: busy ? null : save,
                icon: busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: const Text('Guardar objeto'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class ItemDetail extends StatelessWidget {
  final CatalogRepository repo;
  final String id;
  const ItemDetail(this.repo, this.id, {super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: repo,
    builder: (context, _) {
      final i = repo.data.items.where((i) => i.id == id).firstOrNull;
      if (i == null) {
        return const Scaffold(
          body: Center(child: Text('Objeto não encontrado.')),
        );
      }
      return Scaffold(
        appBar: AppBar(
          title: const Text('Seu objeto'),
          actions: [
            IconButton(
              tooltip: 'Editar objeto',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ItemEditor(repo, item: i),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Excluir objeto',
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                if (!await confirm(
                  context,
                  'Excluir este objeto?',
                  'O cadastro será removido do seu catálogo.',
                  'Excluir',
                )) {
                  return;
                }
                try {
                  await repo.deleteItem(id);
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) message(context, errorText(e));
                }
              },
            ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            children: [
              if (i.photo != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Semantics(
                    label: 'Ampliar foto de ${i.title}',
                    button: true,
                    child: InkWell(
                      onTap: () => showDialog<void>(
                        context: context,
                        builder: (context) => Dialog.fullscreen(
                          child: Scaffold(
                            appBar: AppBar(title: Text(i.title)),
                            body: Center(
                              child: InteractiveViewer(
                                minScale: .5,
                                maxScale: 5,
                                child: Image.file(
                                  repo.photoFile(i.photo!),
                                  errorBuilder: (_, _, _) =>
                                      const Text('Foto indisponível.'),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: AspectRatio(
                          aspectRatio: 4 / 3,
                          child: PhotoView(repo, i.photo),
                        ),
                      ),
                    ),
                  ),
                ),
              Text(
                i.title,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: ink,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: forest.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ONDE ESTÁ',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: forest,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      repo.data.path(i.placeId),
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      icon: const Icon(Icons.drive_file_move_outlined),
                      label: const Text('Mudei de lugar'),
                      onPressed: () async {
                        final selected = await Navigator.push<String>(
                          context,
                          MaterialPageRoute(builder: (_) => PlacePicker(repo)),
                        );
                        if (selected == null) return;
                        try {
                          await repo.moveItem(
                            id,
                            selected.isEmpty ? null : selected,
                          );
                        } catch (e) {
                          if (context.mounted) message(context, errorText(e));
                        }
                      },
                    ),
                  ],
                ),
              ),
              if (i.keywords.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  'Palavras para encontrar',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(i.keywords),
              ],
              if (i.notes.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  'Anotações',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  i.notes,
                  style: const TextStyle(fontSize: 17, height: 1.5),
                ),
              ],
              const SizedBox(height: 24),
              Text(
                'Cadastrado em ${dateText(i.createdAt)}',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              if (i.moves.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  'Mudanças de lugar',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                ...i.moves.reversed.map(
                  (m) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.history, color: forest),
                    title: Text(m.to),
                    subtitle: Text('${dateText(m.at)} · antes: ${m.from}'),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}
