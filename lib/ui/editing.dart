import 'package:onde_guardei/ui/catalog_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:onde_guardei/domain/models.dart';
import 'package:onde_guardei/domain/repository.dart';
import 'package:onde_guardei/ui/helpers.dart';
import 'package:onde_guardei/ui/widgets.dart';

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
  late final AppLifecycleListener lifecycle;

  @override
  void initState() {
    super.initState();
    lifecycle = AppLifecycleListener(
      onInactive: () => keepDraft(),
      onHide: () => keepDraft(),
      onPause: () => keepDraft(),
      onDetach: () => keepDraft(),
    );
    if (!widget.repo.data.places.any((p) => p.id == place)) place = null;
  }

  @override
  void dispose() {
    lifecycle.dispose();
    name.dispose();
    notes.dispose();
    keywords.dispose();
    if (!saved) widget.repo.discardPhoto(photo);
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

  bool get blank =>
      name.text.isEmpty &&
      notes.text.isEmpty &&
      keywords.text.isEmpty &&
      photo == null;

  /// Guarda o rascunho sem interromper o usuário, por exemplo quando o
  /// aplicativo vai para segundo plano.
  Future<void> keepDraft() async {
    if (saved || blank) return;
    try {
      await widget.repo.saveDraft(draft);
    } catch (_) {
      // Sem espaço ou arquivo ocupado: o rascunho fica só na tela.
    }
  }

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
        final previous = photo;
        photo = selected;
        await widget.repo.saveDraft(draft);
        if (previous != null && previous != selected) {
          await widget.repo.discardPhoto(previous);
        }
        if (mounted) setState(() {});
      }
    } catch (e) {
      if (mounted) {
        message(
          context,
          e is PlatformException
              ? context.strings.text(
                  'Não foi possível abrir a câmera ou as fotos. Verifique a permissão nas configurações do Android.',
                )
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
    if (blank) return true;
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
        title: Text(
          widget.item == null
              ? context.strings.text('Guardar objeto')
              : context.strings.text('Editar objeto'),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            children: [
              Text(
                context.strings.text(
                  'Foto opcional do objeto ou de onde ele fica',
                ),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: SizedBox(
                  height: 190,
                  child: PhotoView(widget.repo, photo, cacheWidth: 800),
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
                    label: Text(context.strings.text('Tirar foto')),
                  ),
                  OutlinedButton.icon(
                    onPressed: busy ? null : () => pick(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(context.strings.text('Escolher foto')),
                  ),
                  if (photo != null)
                    TextButton(
                      onPressed: busy
                          ? null
                          : () async {
                              final removed = photo;
                              setState(() => photo = null);
                              await widget.repo.discardPhoto(removed);
                              await widget.repo.saveDraft(draft);
                            },
                      child: Text(context.strings.text('Remover foto')),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: name,
                maxLength: 120,
                decoration: InputDecoration(
                  labelText: context.strings.text('Nome do objeto'),
                  hintText: context.strings.text('Ex.: carregador do notebook'),
                  helperText: context.strings.text(
                    'Opcional se você adicionar uma foto',
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.location_on_outlined),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(placePath(context, widget.repo.data, place)),
                ),
                onPressed: busy
                    ? null
                    : () async {
                        final selected = await Navigator.push<String>(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                PlacePicker(widget.repo, selectedId: place),
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
                decoration: InputDecoration(
                  labelText: context.strings.text('Palavras para encontrar'),
                  hintText: context.strings.text('Ex.: cabo, Dell, computador'),
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
                decoration: InputDecoration(
                  labelText: context.strings.text('Anotações'),
                  hintText: context.strings.text(
                    'Detalhes que ajudam você a lembrar',
                  ),
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
                label: Text(context.strings.text('Guardar objeto')),
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
      final colors = Theme.of(context).colorScheme;
      final i = repo.data.items.where((i) => i.id == id).firstOrNull;
      if (i == null) {
        return Scaffold(
          body: Center(
            child: Text(context.strings.text('Objeto não encontrado.')),
          ),
        );
      }
      return Scaffold(
        appBar: AppBar(
          title: Text(context.strings.text('Seu objeto')),
          actions: [
            IconButton(
              tooltip: context.strings.text('Editar objeto'),
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ItemEditor(repo, item: i),
                ),
              ),
            ),
            IconButton(
              tooltip: context.strings.text('Excluir objeto'),
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
                    label: context.strings.text('Ampliar foto de {0}', [
                      itemTitle(context, i),
                    ]),
                    button: true,
                    child: InkWell(
                      onTap: () => showDialog<void>(
                        context: context,
                        builder: (context) => Dialog.fullscreen(
                          child: Scaffold(
                            appBar: AppBar(title: Text(itemTitle(context, i))),
                            body: Center(
                              child: InteractiveViewer(
                                minScale: .5,
                                maxScale: 5,
                                child: Image.file(
                                  repo.photoFile(i.photo!),
                                  cacheWidth: 2000,
                                  errorBuilder: (_, _, _) => Text(
                                    context.strings.text('Foto indisponível.'),
                                  ),
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
                          child: PhotoView(repo, i.photo, cacheWidth: 1200),
                        ),
                      ),
                    ),
                  ),
                ),
              Text(
                itemTitle(context, i),
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.strings.text('ONDE ESTÁ'),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      placePath(context, repo.data, i.placeId),
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      icon: const Icon(Icons.drive_file_move_outlined),
                      label: Text(context.strings.text('Mudei de lugar')),
                      onPressed: () async {
                        final selected = await Navigator.push<String>(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                PlacePicker(repo, selectedId: i.placeId),
                          ),
                        );
                        if (selected == null || !context.mounted) return;
                        final nextPlace = selected.isEmpty ? null : selected;
                        if (nextPlace == i.placeId) return;
                        try {
                          await repo.moveItem(id, nextPlace);
                          if (context.mounted) {
                            message(context, 'Local atualizado.');
                          }
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
                Text(
                  context.strings.text('Palavras para encontrar'),
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(i.keywords),
              ],
              if (i.notes.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  context.strings.text('Anotações'),
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
                context.strings.text('Cadastrado em {0}', [
                  dateText(context, i.createdAt),
                ]),
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
              if (i.updatedAt.isAfter(i.createdAt))
                Text(
                  context.strings.text('Última alteração em {0}', [
                    dateText(context, i.updatedAt),
                  ]),
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              if (i.moves.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  context.strings.text('Mudanças de lugar'),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                ...i.moves.reversed.map(
                  (m) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.history,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(m.to),
                    subtitle: Text(
                      context.strings.text('{0} · antes: {1}', [
                        dateText(context, m.at),
                        m.from,
                      ]),
                    ),
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

class PlaceEditor extends StatefulWidget {
  final CatalogRepository repo;
  final Place? place;
  const PlaceEditor(this.repo, {super.key, this.place});
  @override
  State<PlaceEditor> createState() => _PlaceEditorState();
}

class _PlaceEditorState extends State<PlaceEditor> {
  final form = GlobalKey<FormState>();
  late final name = TextEditingController(text: widget.place?.name);
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
      title: Text(
        widget.place == null
            ? context.strings.text('Criar local')
            : context.strings.text('Editar local'),
      ),
      actions: [
        if (widget.place != null)
          IconButton(
            tooltip: context.strings.text('Excluir local'),
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
            Icon(
              Icons.folder_copy_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: name,
              autofocus: widget.place == null,
              maxLength: 100,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: context.strings.text('Nome do local'),
                hintText: context.strings.text('Quarto, armário, caixa azul…'),
              ),
              validator: (s) => s == null || s.trim().isEmpty
                  ? context.strings.text('Dê um nome a este local.')
                  : null,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.account_tree_outlined),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  parent == null
                      ? context.strings.text('Fica na raiz da casa')
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
                            selectedId: parent,
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
              label: Text(context.strings.text('Salvar local')),
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

class PlacePicker extends StatefulWidget {
  final CatalogRepository repo;
  final String? excluded;
  final String? selectedId;
  const PlacePicker(this.repo, {super.key, this.excluded, this.selectedId});
  @override
  State<PlacePicker> createState() => _PlacePickerState();
}

class _PlacePickerState extends State<PlacePicker> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final catalog = widget.repo.data;
    final words = searchWords(query);
    final places =
        catalog.places.where((place) {
            if (widget.excluded != null &&
                catalog.isInside(place.id, widget.excluded)) {
              return false;
            }
            final path = normalize(catalog.path(place.id));
            return words.every(path.contains);
          }).toList()
          ..sort((a, b) => catalog.path(a.id).compareTo(catalog.path(b.id)));
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.excluded == null
              ? context.strings.text('Onde fica?')
              : context.strings.text('Dentro de qual local?'),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: TextField(
                onChanged: (s) => setState(() => query = s),
                decoration: InputDecoration(
                  labelText: context.strings.text(
                    'Buscar por parte do caminho',
                  ),
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
                          ? context.strings.text('Sem local definido')
                          : context.strings.text('Na raiz da casa'),
                    ),
                    selected: widget.selectedId == null,
                    onTap: () => Navigator.pop(context, ''),
                  ),
                  ...places.map(
                    (p) => ListTile(
                      leading: const Icon(Icons.folder_outlined),
                      title: Text(p.name),
                      subtitle: Text(catalog.path(p.id)),
                      selected: p.id == widget.selectedId,
                      trailing: p.id == widget.selectedId
                          ? Icon(
                              Icons.check,
                              semanticLabel: context.strings.text(
                                'Selecionado',
                              ),
                            )
                          : null,
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
              label: Text(context.strings.text('Novo local')),
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
