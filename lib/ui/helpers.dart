import 'package:onde_guardei/domain/models.dart';
import 'package:onde_guardei/ui/strings.dart';
import 'package:flutter/material.dart';

String dateText(BuildContext context, DateTime date) =>
    MaterialLocalizations.of(context).formatCompactDate(date.toLocal());

void message(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

String errorText(BuildContext context, Object error) {
  final strings = Strings.of(context);
  return error is FormatException
      ? _catalogMessage(strings, error.message)
      : strings.genericError;
}

String noticeText(BuildContext context, String notice) =>
    _catalogMessage(Strings.of(context), notice);

String _catalogMessage(Strings strings, String source) => switch (source) {
  'Não foi possível recuperar a última foto. Você pode selecioná-la novamente.' =>
    strings.recoverPhoto,
  'Nome de foto inválido.' => strings.invalidPhotoName,
  'Recuperamos a versão anterior dos seus cadastros. Crie um backup.' =>
    strings.recoveredCatalog,
  'Não foi possível abrir os dados. Seus arquivos foram preservados; não reinstale o aplicativo.' =>
    strings.dataOpenError,
  'Mova os objetos e os locais de dentro antes de excluir este local.' =>
    strings.placeNotEmpty,
  'A foto não está disponível. Selecione-a novamente.' => strings.photoMissing,
  'A foto escolhida não está mais disponível. Selecione-a novamente.' =>
    strings.chosenPhotoMissing,
  'Escolha uma foto de até 15 MB.' => strings.photoLimit,
  'Não foi possível copiar a foto para o aplicativo.' =>
    strings.copyPhotoFailed,
  'Não foi possível criar o backup porque uma foto não está no aparelho. Selecione novamente ou remova as fotos indisponíveis dos cadastros e tente outra vez.' =>
    strings.backupPhotoMissing,
  'Este catálogo excede o limite de 70 MB de fotos por backup nesta versão.' =>
    strings.backupPhotosLimit,
  'O arquivo excede o limite de 100 MB.' => strings.fileLimit,
  'Este arquivo não é um backup válido do Onde Guardei?.' =>
    strings.invalidBackup,
  'Este arquivo não é um backup do Onde Guardei?.' => strings.notBackup,
  'O backup está corrompido e não pôde ser lido. Tente outro arquivo.' =>
    strings.corruptBackup,
  'Este backup está sem as fotos e não pode ser restaurado.' =>
    strings.backupNoPhotos,
  'Este backup está sem alguma das fotos e não pode ser restaurado.' =>
    strings.backupMissingSomePhotos,
  'Uma foto do backup excede 15 MB.' => strings.backupPhotoLimit,
  'Versão de arquivo não suportada.' => strings.unsupportedVersion,
  'Local inválido ou repetido.' => strings.invalidPlace,
  'A organização dos locais contém um ciclo ou local ausente.' =>
    strings.invalidHierarchy,
  'Cadastro de objeto inválido.' => strings.invalidItem,
  _ => strings.genericError,
};

String itemTitle(BuildContext context, StoredItem item) =>
    item.name.isEmpty ? Strings.of(context).unnamedItem : item.name;

String placePath(BuildContext context, Catalog catalog, String? id) {
  final strings = Strings.of(context);
  if (id == null) return strings.noPlace;
  if (!catalog.placeIndex.containsKey(id)) return strings.unknownPlace;
  return catalog.path(id);
}

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
            child: Text(Strings.of(context).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;
