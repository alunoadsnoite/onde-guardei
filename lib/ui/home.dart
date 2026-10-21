import 'dart:io';
import 'package:flutter/material.dart';
import 'package:onde_guardei/domain/models.dart';
import 'package:onde_guardei/domain/repository.dart';
import 'package:onde_guardei/ui/editing.dart';
import 'package:onde_guardei/ui/app.dart';
import 'package:onde_guardei/ui/helpers.dart';
import 'package:onde_guardei/ui/widgets.dart';

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
  final search = TextEditingController();
  CatalogRepository get repo => widget.repo;

  @override
  void initState() {
    super.initState();
    refreshDraft();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
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

  /// Escolhe um local como filtro e limpa a busca, mantendo os dois campos
  /// em sincronia com o que está na tela.
  void filterByPlace(String? id, {bool clearSearch = true}) {
    if (clearSearch) search.clear();
    setState(() {
      filter = id;
      if (clearSearch) query = '';
      tab = 0;
    });
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
        final result = await repo.exportBackup();
        temporary = result.file;
        final saved = await nativeFiles.invokeMethod<bool>('exportBackup', {
          'path': temporary.path,
          'name':
              'Onde-Guardei-${DateTime.now().toIso8601String().substring(0, 10)}.ondeguardei.json',
        });
        if (saved == true && mounted) {
          message(
            context,
            result.missingPhotos > 0
                ? 'Backup salvo, mas ${result.missingPhotos} foto(s) não estavam no aparelho e ficaram de fora.'
                : 'Backup salvo com os cadastros e as fotos.',
          );
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
      final places = repo.data.sortedPlaces();
      final counts = repo.data.itemsByPlace();
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
                    applicationName: appName,
                    applicationVersion: appVersion,
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
                                color: Color(0xFF263C35),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${repo.data.items.length} objetos · ${repo.data.places.length} locais',
                              style: const TextStyle(color: Color(0xFF234B40)),
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: search,
                              onChanged: (value) =>
                                  setState(() => query = value),
                              decoration: InputDecoration(
                                hintText: 'Buscar objeto, palavra ou local',
                                prefixIcon: const Icon(Icons.search),
                                labelText: 'O que você está procurando?',
                                suffixIcon: query.isEmpty
                                    ? null
                                    : IconButton(
                                        tooltip: 'Limpar busca',
                                        icon: const Icon(Icons.close),
                                        onPressed: () {
                                          search.clear();
                                          setState(() => query = '');
                                        },
                                      ),
                              ),
                            ),
                            if (activeFilter != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: InputChip(
                                  label: Text(repo.data.path(activeFilter)),
                                  onDeleted: () =>
                                      filterByPlace(null, clearSearch: false),
                                ),
                              ),
                            if (repo.recoveryNotice != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        repo.recoveryNotice!,
                                        style: const TextStyle(
                                          color: Color(0xFF95462D),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Dispensar aviso',
                                      visualDensity: VisualDensity.compact,
                                      icon: const Icon(Icons.close, size: 20),
                                      onPressed: repo.dismissNotice,
                                    ),
                                  ],
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
                    final count = counts[p.id] ?? 0;
                    return Card(
                      color: Colors.white,
                      elevation: 0,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: const Icon(
                          Icons.location_on_outlined,
                          color: Color(0xFF234B40),
                        ),
                        title: Text(
                          p.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${repo.data.path(p.id)}\n$count ${count == 1 ? 'objeto' : 'objetos'}, incluindo os locais de dentro',
                        ),
                        isThreeLine: true,
                        onTap: () => filterByPlace(p.id),
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
                backgroundColor: Color(0xFF234B40),
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add),
                label: Text(tab == 0 ? 'Guardar objeto' : 'Criar local'),
              ),
      );
    },
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
                child: PhotoView(repo, item.photo, cacheWidth: 240),
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
                      color: Color(0xFF263C35),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    repo.data.path(item.placeId),
                    style: const TextStyle(color: Color(0xFF234B40)),
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
              child: Icon(Icons.chevron_right, color: Color(0xFF234B40)),
            ),
          ],
        ),
      ),
    ),
  );
}
