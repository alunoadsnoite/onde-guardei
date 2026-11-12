import 'package:onde_guardei/ui/catalog_strings.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onde_guardei/domain/models.dart';
import 'package:onde_guardei/domain/repository.dart';
import 'package:onde_guardei/ui/editing.dart';
import 'package:onde_guardei/ui/app.dart';
import 'package:onde_guardei/ui/helpers.dart';
import 'package:onde_guardei/ui/widgets.dart';

const developerEmail = 'valdenor.sa@proton.me';

class Home extends StatefulWidget {
  final CatalogRepository repo;
  final ThemeMode themeMode;
  final AppLanguage language;
  final Future<void> Function(AppLanguage) onLanguageChanged;
  final Future<void> Function(ThemeMode) onThemeChanged;
  const Home(
    this.repo, {
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
    required this.language,
    required this.onLanguageChanged,
  });
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

  Future<void> chooseAppearance() async {
    final selected = await showDialog<ThemeMode>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(context.strings.text('Aparência')),
        children: [
          RadioGroup<ThemeMode>(
            groupValue: widget.themeMode,
            onChanged: (value) => Navigator.pop(context, value),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile(
                  title: Text(context.strings.text('Claro')),
                  value: ThemeMode.light,
                ),
                RadioListTile(
                  title: Text(context.strings.text('Escuro')),
                  value: ThemeMode.dark,
                ),
                RadioListTile(
                  title: Text(context.strings.text('Automático')),
                  subtitle: Text(
                    context.strings.text('Seguir a aparência do aparelho'),
                  ),
                  value: ThemeMode.system,
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (!mounted || selected == null || selected == widget.themeMode) return;
    try {
      await widget.onThemeChanged(selected);
    } catch (_) {
      if (mounted) message(context, 'Não foi possível salvar a aparência.');
    }
  }

  Future<void> chooseLanguage() async {
    final selected = await showDialog<AppLanguage>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(context.strings.text('Idioma')),
        children: [
          RadioGroup<AppLanguage>(
            groupValue: widget.language,
            onChanged: (value) => Navigator.pop(context, value),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final language in AppLanguage.values)
                  RadioListTile<AppLanguage>(
                    value: language,
                    title: Text(language.label),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    if (!mounted || selected == null || selected == widget.language) return;
    try {
      await widget.onLanguageChanged(selected);
    } catch (_) {
      if (mounted) message(context, 'Não foi possível salvar o idioma.');
    }
  }

  void showSupport() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.strings.text('Sobre e suporte')),
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('$appName · $appVersion'),
            const SizedBox(height: 12),
            Text(context.strings.text('Desenvolvedor')),
            const Text('Valdenor Tavares'),
            const SelectableText(developerEmail),
            TextButton.icon(
              onPressed: emailDeveloper,
              icon: const Icon(Icons.email_outlined),
              label: Text(context.strings.text('Enviar e-mail')),
            ),
            const SizedBox(height: 12),
            Text(
              context.strings.text(
                'O catálogo funciona sem conta e sem internet. Fotos e textos ficam no aparelho. Guarde um backup fora do app antes de trocar de celular ou desinstalar.\n\nCódigo aberto • licença MIT',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => showLicensePage(
              context: context,
              applicationName: appName,
              applicationVersion: appVersion,
            ),
            child: Text(context.strings.text('Licenças')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.strings.text('Fechar')),
          ),
        ],
      ),
    );
  }

  Future<void> emailDeveloper() async {
    try {
      final opened = await nativeFiles.invokeMethod<bool>('openEmail', {
        'address': developerEmail,
        'subject': context.strings.text('Onde Guardei? — dúvida ou sugestão'),
      });
      if (opened == true) return;
    } on PlatformException {
      // O endereço continua disponível para copiar na tela de suporte.
    } on MissingPluginException {
      // O envio está disponível apenas no Android.
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.strings.text('Não foi possível abrir o e-mail')),
        content: const SelectableText(developerEmail),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.strings.text('Fechar')),
          ),
        ],
      ),
    );
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
                ? context.strings.text(
                    'Backup salvo, mas {0} foto(s) não estavam no aparelho e ficaram de fora.',
                    [result.missingPhotos],
                  )
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
      final colors = Theme.of(context).colorScheme;
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
              tooltip: context.strings.text('Configurações e backup'),
              enabled: !working,
              onSelected: (value) {
                if (value == 'export') {
                  backup(false);
                }
                if (value == 'import') {
                  backup(true);
                }
                if (value == 'appearance') chooseAppearance();
                if (value == 'about') showSupport();
                if (value == 'language') chooseLanguage();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'language',
                  child: Text(context.strings.text('Idioma')),
                ),
                PopupMenuItem(
                  value: 'export',
                  child: Text(context.strings.text('Criar backup com fotos')),
                ),
                PopupMenuItem(
                  value: 'import',
                  child: Text(context.strings.text('Restaurar backup')),
                ),
                PopupMenuItem(
                  value: 'appearance',
                  child: Text(context.strings.text('Aparência')),
                ),
                PopupMenuItem(
                  value: 'about',
                  child: Text(context.strings.text('Sobre e suporte')),
                ),
              ],
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: working
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 20),
                      Text(context.strings.text('Cuidando do seu catálogo…')),
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
                            Text(
                              context.strings.text(
                                'Encontre o que você guardou.',
                              ),
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: colors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${itemCount(context, repo.data.items.length)} · ${placeCount(context, repo.data.places.length)}',
                              style: TextStyle(color: colors.primary),
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: search,
                              onChanged: (value) =>
                                  setState(() => query = value),
                              decoration: InputDecoration(
                                hintText: context.strings.text(
                                  'Ex.: chave, gaveta ou reserva',
                                ),
                                prefixIcon: const Icon(Icons.search),
                                labelText: context.strings.text(
                                  'Buscar por nome, local ou anotação',
                                ),
                                suffixIcon: query.isEmpty
                                    ? null
                                    : IconButton(
                                        tooltip: context.strings.text(
                                          'Limpar busca',
                                        ),
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
                                        context.strings.text(
                                          repo.recoveryNotice!,
                                        ),
                                        style: TextStyle(color: colors.error),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: context.strings.text(
                                        'Dispensar aviso',
                                      ),
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
                                  label: Text(
                                    context.strings.text(
                                      'Continuar cadastro não salvo',
                                    ),
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
                              ? context.strings.text('Um lugar para lembrar.')
                              : context.strings.text(
                                  'Nada encontrado por aqui.',
                                ),
                          text: repo.data.items.isEmpty
                              ? context.strings.text(
                                  'Cadastre seu primeiro objeto com uma foto, um nome ou os dois. Depois, conte onde ele fica.',
                                )
                              : context.strings.text(
                                  'Tente outra palavra ou escolha outro local.',
                                ),
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
              ? EmptyState(
                  icon: Icons.home_outlined,
                  title: context.strings.text('Como você organiza sua casa?'),
                  text: context.strings.text(
                    'Crie um cômodo, depois um móvel ou uma caixa dentro dele. Exemplo: quarto › armário › caixa azul.',
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                  itemCount: places.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final p = places[index];
                    final count = counts[p.id] ?? 0;
                    return Card(
                      color: colors.surfaceContainerLowest,
                      elevation: 0,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: Icon(
                          Icons.location_on_outlined,
                          color: colors.primary,
                        ),
                        title: Text(
                          p.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${repo.data.path(p.id)}\n${context.strings.text(count == 1 ? '{0} objeto, incluindo os locais de dentro' : '{0} objetos, incluindo os locais de dentro', [count])}',
                        ),
                        isThreeLine: true,
                        onTap: () => filterByPlace(p.id),
                        trailing: IconButton(
                          tooltip: context.strings.text('Editar {0}', [p.name]),
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
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.inventory_2_outlined),
              selectedIcon: const Icon(Icons.inventory_2),
              label: context.strings.text('Objetos'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: context.strings.text('Locais'),
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
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                icon: const Icon(Icons.add),
                label: Text(
                  tab == 0
                      ? context.strings.text('Guardar objeto')
                      : context.strings.text('Criar local'),
                ),
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
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerLowest,
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
                      itemTitle(context, item),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      placePath(context, repo.data, item.placeId),
                      style: TextStyle(color: colors.primary),
                    ),
                    if (item.keywords.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          item.keywords,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Icon(Icons.chevron_right, color: colors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
