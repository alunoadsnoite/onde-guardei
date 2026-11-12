import 'package:onde_guardei/ui/catalog_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onde_guardei/domain/models.dart';

String dateText(BuildContext context, DateTime date) =>
    MaterialLocalizations.of(context).formatCompactDate(date.toLocal());

String itemCount(BuildContext context, int count) =>
    context.strings.text(count == 1 ? '{0} objeto' : '{0} objetos', [count]);

String placeCount(BuildContext context, int count) =>
    context.strings.text(count == 1 ? '{0} local' : '{0} locais', [count]);

String itemTitle(BuildContext context, StoredItem item) =>
    item.name.isEmpty ? context.strings.text('Objeto sem nome') : item.name;

String placePath(BuildContext context, Catalog catalog, String? id) {
  if (id == null) return context.strings.text('Sem local definido');
  final path = catalog.pathSegments(id);
  return path.isEmpty
      ? context.strings.text('Local desconhecido')
      : path.join(' › ');
}

void message(BuildContext context, String text) => ScaffoldMessenger.of(
  context,
).showSnackBar(SnackBar(content: Text(context.strings.text(text))));

String errorText(Object error) => switch (error) {
  FormatException(:final message) => message,
  PlatformException(code: 'files' || 'busy', message: final String message) =>
    message,
  _ =>
    'Não foi possível concluir. Seus cadastros anteriores foram preservados. Tente novamente.',
};

Future<bool> confirm(
  BuildContext context,
  String title,
  String text,
  String action,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.strings.text(title)),
        content: Text(context.strings.text(text)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.strings.text('Cancelar')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.strings.text(action)),
          ),
        ],
      ),
    ) ??
    false;
