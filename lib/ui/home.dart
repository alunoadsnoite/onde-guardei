import 'package:onde_guardei/ui/strings.dart';
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
  final Future<void> Function(Locale)? onLanguageChanged;
  final ThemeMode themeMode;
  final Future<void> Function(ThemeMode) onThemeChanged;
  const Home(
    this.repo, {
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
    this.onLanguageChanged,
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
        title: Text(Strings.of(context).appearance),
        children: [
          RadioGroup<ThemeMode>(
            groupValue: widget.themeMode,
            onChanged: (value) => Navigator.pop(context, value),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile(
                  title: Text(Strings.of(context).light),
                  value: ThemeMode.light,
                ),
                RadioListTile(
                  title: Text(Strings.of(context).dark),
                  value: ThemeMode.dark,
                ),
                RadioListTile(
                  title: Text(Strings.of(context).automatic),
                  subtitle: Text(Strings.of(context).followAppearance),
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
      if (mounted) message(context, Strings.of(context).appearanceError);
    }
  }

  void showSupport() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(Strings.of(context).support),
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$appName · $appVersion'),
            const SizedBox(height: 12),
            Text(Strings.of(context).developer),
            Text('Valdenor Tavares'),
            const SelectableText(developerEmail),
            TextButton.icon(
              onPressed: emailDeveloper,
              icon: const Icon(Icons.email_outlined),
              label: Text(Strings.of(context).sendEmail),
            ),
            const SizedBox(height: 12),
            Text(Strings.of(context).supportBody),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => showLicensePage(
              context: context,
              applicationName: appName,
              applicationVersion: appVersion,
            ),
            child: Text(Strings.of(context).licenses),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(Strings.of(context).close),
          ),
        ],
      ),
    );
  }

  Future<void> emailDeveloper() async {
    try {
      final subject = Strings.of(context).supportSubject;
      final opened = await nativeFiles.invokeMethod<bool>('openEmail', {
        'address': developerEmail,
        'subject': subject,
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
        title: Text(Strings.of(context).emailError),
        content: const SelectableText(developerEmail),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(Strings.of(context).close),
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
          Strings.of(context).restoreTitle,
          Strings.of(context).restoreWarning,
          Strings.of(context).chooseBackup,
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
          message(context, Strings.of(context).restored);
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
                ? Strings.of(context).backupMissing(result.missingPhotos)
                : Strings.of(context).backupSaved,
          );
        }
      }
    } catch (e) {
      if (mounted) message(context, errorText(context, e));
    } finally {
      if (temporary != null && await temporary.exists()) {
        await temporary.delete();
      }
      if (mounted) setState(() => working = false);
    }
  }

  Future<void> selectLanguage() async {
    final current = Localizations.localeOf(context);
    final selected = await showDialog<Locale>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(Strings.of(context).language),
        children: [
          for (var index = 0; index < supportedLocales.length; index++)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, supportedLocales[index]),
              child: Semantics(
                selected: current == supportedLocales[index],
                child: Text(languageLabels[index]),
              ),
            ),
        ],
      ),
    );
    if (!mounted || selected == null || selected == current) return;
    try {
      await widget.onLanguageChanged?.call(selected);
    } catch (_) {
      if (mounted) message(context, Strings.of(context).languageSaveFailed);
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
          title: Text(appName, style: TextStyle(fontWeight: FontWeight.w800)),
          actions: [
            PopupMenuButton<String>(
              tooltip: Strings.of(context).settingsMenu,
              enabled: !working,
              onSelected: (value) {
                if (value == 'export') {
                  backup(false);
                }
                if (value == 'import') {
                  backup(true);
                }
                if (value == 'language') selectLanguage();
                if (value == 'appearance') chooseAppearance();
                if (value == 'about') showSupport();
              },
              itemBuilder: (_) => [
                if (widget.onLanguageChanged != null)
                  PopupMenuItem(
                    value: 'language',
                    child: Text(Strings.of(context).language),
                  ),
                PopupMenuItem(
                  value: 'export',
                  child: Text(Strings.of(context).createBackup),
                ),
                PopupMenuItem(
                  value: 'import',
                  child: Text(Strings.of(context).restoreBackup),
                ),
                PopupMenuItem(
                  value: 'appearance',
                  child: Text(Strings.of(context).appearance),
                ),
                PopupMenuItem(
                  value: 'about',
                  child: Text(Strings.of(context).support),
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
                      CircularProgressIndicator(),
                      SizedBox(height: 20),
                      Text(Strings.of(context).working),
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
                              Strings.of(context).headline,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: colors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${Strings.of(context).itemCount(repo.data.items.length)} · ${Strings.of(context).placeCount(repo.data.places.length)}',
                              style: TextStyle(color: colors.primary),
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: search,
                              onChanged: (value) =>
                                  setState(() => query = value),
                              decoration: InputDecoration(
                                hintText: Strings.of(context).searchExample,
                                prefixIcon: const Icon(Icons.search),
                                labelText: Strings.of(context).searchFields,
                                suffixIcon: query.isEmpty
                                    ? null
                                    : IconButton(
                                        tooltip: Strings.of(
                                          context,
                                        ).clearSearch,
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
                                        noticeText(
                                          context,
                                          repo.recoveryNotice!,
                                        ),
                                        style: TextStyle(color: colors.error),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: Strings.of(
                                        context,
                                      ).dismissNotice,
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
                                  label: Text(Strings.of(context).resumeDraft),
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
                              ? Strings.of(context).emptyTitle
                              : Strings.of(context).noResults,
                          text: repo.data.items.isEmpty
                              ? Strings.of(context).emptyHint
                              : Strings.of(context).searchAgain,
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
                  title: Strings.of(context).placesTitle,
                  text: Strings.of(context).placesHint,
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
                          '${repo.data.path(p.id)}\n${Strings.of(context).nestedCount(count)}',
                        ),
                        isThreeLine: true,
                        onTap: () => filterByPlace(p.id),
                        trailing: IconButton(
                          tooltip: Strings.of(context).editNamed(p.name),
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
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: Strings.of(context).items,
            ),
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: Strings.of(context).places,
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
                      ? Strings.of(context).storeItem
                      : Strings.of(context).createPlace,
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
