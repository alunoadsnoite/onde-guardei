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
                                  errorBuilder: (_, __, ___) =>
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
                  color: Color(0xFF263C35),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Color(0xFF234B40).withValues(alpha: .08),
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
                        color: Color(0xFF234B40),
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
                          await repo.moveItem(id, selected.isEmpty ? null : selected);
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
                    leading: const Icon(Icons.history, color: Color(0xFF234B40)),
                    title: Text(m.to),
                    subtitle: Text(
                      '${dateText(m.at)} · antes: ${m.from}',
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
  late final name = TextEditingController(
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
            const Icon(Icons.folder_copy_outlined, size: 56, color: Color(0xFF234B40)),
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
