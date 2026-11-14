import 'package:flutter/material.dart';

const supportedLocales = [Locale('pt', 'BR'), Locale('en', 'US'), Locale('es')];

const languageLabels = ['Português (Brasil)', 'English (US)', 'Español'];

Locale localeFromTag(String? tag) => supportedLocales.firstWhere(
  (locale) => locale.toLanguageTag() == tag,
  orElse: () => supportedLocales.first,
);

class Strings {
  final int _index;
  const Strings._(this._index);

  factory Strings.of(BuildContext context) =>
      Strings.forLocale(Localizations.localeOf(context));

  factory Strings.forLocale(Locale locale) =>
      Strings._(switch (locale.languageCode) {
        'en' => 1,
        'es' => 2,
        _ => 0,
      });

  String get restoreTitle => const [
    'Restaurar catálogo?',
    'Restore catalog?',
    '¿Restaurar el catálogo?',
  ][_index];
  String get restoreWarning => const [
    'O backup substituirá os objetos e locais atuais. Crie um backup antes se quiser guardar os dados que estão aqui.',
    'The backup will replace your current items and places. Create a backup first if you want to keep your current data.',
    'La copia sustituirá los objetos y lugares actuales. Crea una copia primero si quieres conservar tus datos.',
  ][_index];
  String get chooseBackup =>
      const ['Escolher backup', 'Choose backup', 'Elegir copia'][_index];
  String get restored => const [
    'Catálogo restaurado, com as fotos.',
    'Catalog restored with photos.',
    'Catálogo restaurado con las fotos.',
  ][_index];
  String get backupSaved => const [
    'Backup salvo com os cadastros e as fotos.',
    'Backup saved with records and photos.',
    'Copia guardada con los registros y las fotos.',
  ][_index];
  String get createBackup => const [
    'Criar backup com fotos',
    'Create backup with photos',
    'Crear copia con fotos',
  ][_index];
  String get restoreBackup =>
      const ['Restaurar backup', 'Restore backup', 'Restaurar copia'][_index];
  String get working => const [
    'Cuidando do seu catálogo…',
    'Working on your catalog…',
    'Procesando tu catálogo…',
  ][_index];
  String get headline => const [
    'Encontre o que você guardou.',
    'Find what you put away.',
    'Encuentra lo que guardaste.',
  ][_index];
  String get clearSearch =>
      const ['Limpar busca', 'Clear search', 'Borrar búsqueda'][_index];
  String get dismissNotice =>
      const ['Dispensar aviso', 'Dismiss notice', 'Descartar aviso'][_index];
  String get resumeDraft => const [
    'Continuar cadastro não salvo',
    'Continue unsaved entry',
    'Continuar registro sin guardar',
  ][_index];
  String get emptyTitle => const [
    'Um lugar para lembrar.',
    'A place to help you remember.',
    'Un lugar para recordar.',
  ][_index];
  String get noResults => const [
    'Nada encontrado por aqui.',
    'Nothing found.',
    'No se encontraron resultados.',
  ][_index];
  String get emptyHint => const [
    'Cadastre seu primeiro objeto com uma foto, um nome ou os dois. Depois, conte onde ele fica.',
    'Add your first item with a photo, a name, or both. Then say where it is kept.',
    'Registra tu primer objeto con una foto, un nombre o ambos. Luego indica dónde está.',
  ][_index];
  String get searchAgain => const [
    'Tente outra palavra ou escolha outro local.',
    'Try another word or choose another place.',
    'Prueba otra palabra o elige otro lugar.',
  ][_index];
  String get placesTitle => const [
    'Como você organiza sua casa?',
    'How do you organize your home?',
    '¿Cómo organizas tu casa?',
  ][_index];
  String get placesHint => const [
    'Crie um cômodo, depois um móvel ou uma caixa dentro dele. Exemplo: quarto › armário › caixa azul.',
    'Create a room, then add a piece of furniture or a box inside it. Example: bedroom › closet › blue box.',
    'Crea una habitación y luego un mueble o una caja dentro. Ejemplo: dormitorio › armario › caja azul.',
  ][_index];
  String get storeItem =>
      const ['Guardar objeto', 'Store item', 'Guardar objeto'][_index];
  String get createPlace =>
      const ['Criar local', 'Create place', 'Crear lugar'][_index];
  String get items => const ['Objetos', 'Items', 'Objetos'][_index];
  String get places => const ['Locais', 'Places', 'Lugares'][_index];
  String get cancel => const ['Cancelar', 'Cancel', 'Cancelar'][_index];
  String get genericError => const [
    'Não foi possível concluir. Seus cadastros anteriores foram preservados. Tente novamente.',
    'Could not complete the action. Your existing records were preserved. Try again.',
    'No se pudo completar la acción. Se conservaron tus registros anteriores. Inténtalo de nuevo.',
  ][_index];
  String get cameraError => const [
    'Não foi possível abrir a câmera ou as fotos. Verifique a permissão nas configurações do Android.',
    'Could not open the camera or photos. Check permissions in Android settings.',
    'No se pudo abrir la cámara o las fotos. Comprueba el permiso en la configuración de Android.',
  ][_index];
  String get itemRequired => const [
    'Adicione um nome ou uma foto para guardar este objeto.',
    'Add a name or a photo to store this item.',
    'Añade un nombre o una foto para guardar este objeto.',
  ][_index];
  String get leaveEditor => const [
    'Sair do cadastro?',
    'Leave this entry?',
    '¿Salir del registro?',
  ][_index];
  String get draftNotice => const [
    'O que você escreveu será guardado como rascunho para continuar depois.',
    'Your changes will be saved as a draft so you can continue later.',
    'Tus cambios se guardarán como borrador para que puedas continuar más tarde.',
  ][_index];
  String get saveAndExit =>
      const ['Guardar e sair', 'Save and exit', 'Guardar y salir'][_index];
  String get editItem =>
      const ['Editar objeto', 'Edit item', 'Editar objeto'][_index];
  String get takePhoto =>
      const ['Tirar foto', 'Take photo', 'Tomar foto'][_index];
  String get choosePhoto =>
      const ['Escolher foto', 'Choose photo', 'Elegir foto'][_index];
  String get removePhoto =>
      const ['Remover foto', 'Remove photo', 'Quitar foto'][_index];
  String get itemName =>
      const ['Nome do objeto', 'Item name', 'Nombre del objeto'][_index];
  String get itemHint => const [
    'Ex.: carregador do notebook',
    'E.g. laptop charger',
    'Ej.: cargador del portátil',
  ][_index];
  String get optionalName => const [
    'Opcional se você adicionar uma foto',
    'Optional if you add a photo',
    'Opcional si añades una foto',
  ][_index];
  String get keywords => const [
    'Palavras para encontrar',
    'Search keywords',
    'Palabras para buscar',
  ][_index];
  String get keywordsHint => const [
    'Ex.: cabo, Dell, computador',
    'E.g. cable, Dell, computer',
    'Ej.: cable, Dell, computadora',
  ][_index];
  String get notes => const ['Anotações', 'Notes', 'Notas'][_index];
  String get notesHint => const [
    'Detalhes que ajudam você a lembrar',
    'Details to help you remember',
    'Detalles que te ayudan a recordar',
  ][_index];
  String get itemMissing => const [
    'Objeto não encontrado.',
    'Item not found.',
    'Objeto no encontrado.',
  ][_index];
  String get yourItem => const ['Seu objeto', 'Your item', 'Tu objeto'][_index];
  String get deleteItem =>
      const ['Excluir objeto', 'Delete item', 'Eliminar objeto'][_index];
  String get deleteItemTitle => const [
    'Excluir este objeto?',
    'Delete this item?',
    '¿Eliminar este objeto?',
  ][_index];
  String get deleteItemHint => const [
    'O cadastro será removido do seu catálogo.',
    'The item will be removed from your catalog.',
    'El objeto se eliminará de tu catálogo.',
  ][_index];
  String get delete => const ['Excluir', 'Delete', 'Eliminar'][_index];
  String get photoUnavailable => const [
    'Foto indisponível.',
    'Photo unavailable.',
    'Foto no disponible.',
  ][_index];
  String get locationHeading =>
      const ['ONDE ESTÁ', 'WHERE IT IS', 'DÓNDE ESTÁ'][_index];
  String get moved =>
      const ['Mudei de lugar', 'I moved it', 'Lo cambié de lugar'][_index];
  String get moves => const [
    'Mudanças de lugar',
    'Location history',
    'Historial de ubicaciones',
  ][_index];
  String get editPlace =>
      const ['Editar local', 'Edit place', 'Editar lugar'][_index];
  String get deletePlace =>
      const ['Excluir local', 'Delete place', 'Eliminar lugar'][_index];
  String get deletePlaceTitle =>
      const ['Excluir local?', 'Delete place?', '¿Eliminar el lugar?'][_index];
  String get deletePlaceHint => const [
    'Locais com objetos ou outros locais dentro precisam ser esvaziados primeiro.',
    'Empty places that contain items or other places before deleting them.',
    'Vacía primero los lugares que contienen objetos u otros lugares.',
  ][_index];
  String get placeName =>
      const ['Nome do local', 'Place name', 'Nombre del lugar'][_index];
  String get placeHint => const [
    'Quarto, armário, caixa azul…',
    'Bedroom, closet, blue box…',
    'Dormitorio, armario, caja azul…',
  ][_index];
  String get placeRequired => const [
    'Dê um nome a este local.',
    'Give this place a name.',
    'Dale un nombre a este lugar.',
  ][_index];
  String get topLevel => const [
    'Fica na raiz da casa',
    'At the top level of the home',
    'En el nivel principal de la casa',
  ][_index];
  String get savePlace =>
      const ['Salvar local', 'Save place', 'Guardar lugar'][_index];
  String get where =>
      const ['Onde fica?', 'Where is it kept?', '¿Dónde está?'][_index];
  String get inside => const [
    'Dentro de qual local?',
    'Inside which place?',
    '¿Dentro de qué lugar?',
  ][_index];
  String get noPlace => const [
    'Sem local definido',
    'No place selected',
    'Sin lugar definido',
  ][_index];
  String get rootPlace => const [
    'Na raiz da casa',
    'At the top level of the home',
    'En el nivel principal de la casa',
  ][_index];
  String get newPlace =>
      const ['Novo local', 'New place', 'Nuevo lugar'][_index];
  String get unknownPlace => const [
    'Local desconhecido',
    'Unknown place',
    'Lugar desconocido',
  ][_index];
  String get unnamedItem =>
      const ['Objeto sem nome', 'Unnamed item', 'Objeto sin nombre'][_index];
  String get recoverPhoto => const [
    'Não foi possível recuperar a última foto. Você pode selecioná-la novamente.',
    'Could not recover the last photo. You can select it again.',
    'No se pudo recuperar la última foto. Puedes seleccionarla de nuevo.',
  ][_index];
  String get openFailed => const [
    'Não conseguimos abrir seu catálogo.',
    'Could not open your catalog.',
    'No se pudo abrir tu catálogo.',
  ][_index];
  String get filesPreserved => const [
    'Os arquivos foram preservados. Não reinstale o app; tente abrir novamente.',
    'Your files were preserved. Try opening the app again without reinstalling.',
    'Se conservaron tus archivos. Intenta abrir la aplicación de nuevo sin reinstalarla.',
  ][_index];
  String get retry =>
      const ['Tentar novamente', 'Try again', 'Reintentar'][_index];
  String get language => const ['Idioma', 'Language', 'Idioma'][_index];
  String get languageSaveFailed => const [
    'Não foi possível salvar o idioma. Tente novamente.',
    'Could not save the language. Try again.',
    'No se pudo guardar el idioma. Inténtalo de nuevo.',
  ][_index];
  String get invalidPhotoName => const [
    'Nome de foto inválido.',
    'Invalid photo filename.',
    'Nombre de archivo de foto no válido.',
  ][_index];
  String get recoveredCatalog => const [
    'Recuperamos a versão anterior dos seus cadastros. Crie um backup.',
    'The previous version of your records was recovered. Create a backup.',
    'Se recuperó la versión anterior de tus registros. Crea una copia.',
  ][_index];
  String get dataOpenError => const [
    'Não foi possível abrir os dados. Seus arquivos foram preservados; não reinstale o aplicativo.',
    'Could not open the data. Your files were preserved. Keep the app installed.',
    'No se pudieron abrir los datos. Se conservaron tus archivos. Mantén la aplicación instalada.',
  ][_index];
  String get placeNotEmpty => const [
    'Mova os objetos e os locais de dentro antes de excluir este local.',
    'Move the items and places inside before deleting this place.',
    'Mueve los objetos y lugares que contiene antes de eliminar este lugar.',
  ][_index];
  String get photoMissing => const [
    'A foto não está disponível. Selecione-a novamente.',
    'The photo is unavailable. Select it again.',
    'La foto no está disponible. Selecciónala de nuevo.',
  ][_index];
  String get chosenPhotoMissing => const [
    'A foto escolhida não está mais disponível. Selecione-a novamente.',
    'The selected photo is no longer available. Select it again.',
    'La foto elegida ya no está disponible. Selecciónala de nuevo.',
  ][_index];
  String get photoLimit => const [
    'Escolha uma foto de até 15 MB.',
    'Choose a photo up to 15 MB.',
    'Elige una foto de hasta 15 MB.',
  ][_index];
  String get copyPhotoFailed => const [
    'Não foi possível copiar a foto para o aplicativo.',
    'Could not copy the photo into the app.',
    'No se pudo copiar la foto a la aplicación.',
  ][_index];
  String get backupPhotoMissing => const [
    'Não foi possível criar o backup porque uma foto não está no aparelho. Selecione novamente ou remova as fotos indisponíveis dos cadastros e tente outra vez.',
    'Could not create the backup because a photo is missing. Select it again or remove unavailable photos from your records and retry.',
    'No se pudo crear la copia porque falta una foto. Selecciónala de nuevo o quita las fotos no disponibles de los registros y vuelve a intentarlo.',
  ][_index];
  String get backupPhotosLimit => const [
    'Este catálogo excede o limite de 70 MB de fotos por backup nesta versão.',
    'This catalog exceeds the 70 MB photo limit per backup in this version.',
    'Este catálogo supera el límite de 70 MB de fotos por copia en esta versión.',
  ][_index];
  String get fileLimit => const [
    'O arquivo excede o limite de 100 MB.',
    'The file exceeds the 100 MB limit.',
    'El archivo supera el límite de 100 MB.',
  ][_index];
  String get invalidBackup => const [
    'Este arquivo não é um backup válido do Onde Guardei?.',
    'This file is not a valid Onde Guardei? backup.',
    'Este archivo no es una copia válida de Onde Guardei?.',
  ][_index];
  String get notBackup => const [
    'Este arquivo não é um backup do Onde Guardei?.',
    'This file is not an Onde Guardei? backup.',
    'Este archivo no es una copia de Onde Guardei?.',
  ][_index];
  String get corruptBackup => const [
    'O backup está corrompido e não pôde ser lido. Tente outro arquivo.',
    'The backup is corrupted and could not be read. Try another file.',
    'La copia está dañada y no se pudo leer. Prueba con otro archivo.',
  ][_index];
  String get backupNoPhotos => const [
    'Este backup está sem as fotos e não pode ser restaurado.',
    'This backup is missing its photos and cannot be restored.',
    'A esta copia le faltan las fotos y no se puede restaurar.',
  ][_index];
  String get backupMissingSomePhotos => const [
    'Este backup está sem alguma das fotos e não pode ser restaurado.',
    'This backup is missing one or more photos and cannot be restored.',
    'A esta copia le faltan una o más fotos y no se puede restaurar.',
  ][_index];
  String get backupPhotoLimit => const [
    'Uma foto do backup excede 15 MB.',
    'A photo in the backup exceeds 15 MB.',
    'Una foto de la copia supera los 15 MB.',
  ][_index];
  String get unsupportedVersion => const [
    'Versão de arquivo não suportada.',
    'Unsupported file version.',
    'Versión de archivo no compatible.',
  ][_index];
  String get invalidPlace => const [
    'Local inválido ou repetido.',
    'Invalid or duplicate place.',
    'Lugar no válido o duplicado.',
  ][_index];
  String get invalidHierarchy => const [
    'A organização dos locais contém um ciclo ou local ausente.',
    'The place hierarchy has a loop or a missing place.',
    'La jerarquía contiene un ciclo o le falta un lugar.',
  ][_index];
  String get invalidItem => const [
    'Cadastro de objeto inválido.',
    'Invalid item record.',
    'Registro de objeto no válido.',
  ][_index];
  String get appearance =>
      const ['Aparência', 'Appearance', 'Apariencia'][_index];
  String get light => const ['Claro', 'Light', 'Claro'][_index];
  String get dark => const ['Escuro', 'Dark', 'Oscuro'][_index];
  String get automatic =>
      const ['Automático', 'Automatic', 'Automático'][_index];
  String get followAppearance => const [
    'Seguir a aparência do aparelho',
    'Follow device appearance',
    'Seguir la apariencia del dispositivo',
  ][_index];
  String get appearanceError => const [
    'Não foi possível salvar a aparência.',
    'Could not save appearance.',
    'No se pudo guardar la apariencia.',
  ][_index];
  String get support => const [
    'Sobre e suporte',
    'About and support',
    'Acerca de y soporte',
  ][_index];
  String get developer =>
      const ['Desenvolvedor', 'Developer', 'Desarrollador'][_index];
  String get sendEmail =>
      const ['Enviar e-mail', 'Send email', 'Enviar correo'][_index];
  String get licenses => const ['Licenças', 'Licenses', 'Licencias'][_index];
  String get close => const ['Fechar', 'Close', 'Cerrar'][_index];
  String get supportSubject => const [
    'Onde Guardei? — dúvida ou sugestão',
    'Onde Guardei? — question or suggestion',
    'Onde Guardei? — pregunta o sugerencia',
  ][_index];
  String get emailError => const [
    'Não foi possível abrir o e-mail',
    'Could not open email',
    'No se pudo abrir el correo',
  ][_index];
  String get settingsMenu => const [
    'Configurações e backup',
    'Settings and backup',
    'Configuración y copias',
  ][_index];
  String get searchExample => const [
    'Ex.: chave, gaveta ou reserva',
    'E.g. key, drawer, or spare',
    'Ej.: llave, cajón o repuesto',
  ][_index];
  String get searchFields => const [
    'Buscar por nome, local ou anotação',
    'Search by name, place, or note',
    'Buscar por nombre, lugar o nota',
  ][_index];
  String get optionalPhoto => const [
    'Foto opcional do objeto ou de onde ele fica',
    'Optional photo of the item or where it is kept',
    'Foto opcional del objeto o del lugar donde está',
  ][_index];
  String get placeUpdated => const [
    'Local atualizado.',
    'Location updated.',
    'Ubicación actualizada.',
  ][_index];
  String get searchPath => const [
    'Buscar por parte do caminho',
    'Search by part of the path',
    'Buscar por parte de la ruta',
  ][_index];
  String get supportBody => const [
    'O catálogo funciona sem conta e sem internet. Fotos e textos ficam no aparelho. Guarde um backup fora do app antes de trocar de celular ou desinstalar.\n\nCódigo aberto • licença MIT',
    'The catalog works without an account or internet. Photos and text stay on your device. Save a backup outside the app before changing devices or uninstalling.\n\nOpen source • MIT license',
    'El catálogo funciona sin cuenta ni internet. Las fotos y los textos quedan en tu dispositivo. Guarda una copia fuera de la aplicación antes de cambiar de dispositivo o desinstalarla.\n\nCódigo abierto • licencia MIT',
  ][_index];

  String backupMissing(int count) => [
    count == 1
        ? 'Backup salvo sem uma foto indisponível.'
        : 'Backup salvo sem $count fotos indisponíveis.',
    count == 1
        ? 'Backup saved without one unavailable photo.'
        : 'Backup saved without $count unavailable photos.',
    count == 1
        ? 'Copia guardada sin una foto no disponible.'
        : 'Copia guardada sin $count fotos no disponibles.',
  ][_index];

  String itemCount(int count) => [
    count == 1 ? '$count objeto' : '$count objetos',
    count == 1 ? '$count item' : '$count items',
    count == 1 ? '$count objeto' : '$count objetos',
  ][_index];

  String placeCount(int count) => [
    count == 1 ? '$count local' : '$count locais',
    count == 1 ? '$count place' : '$count places',
    count == 1 ? '$count lugar' : '$count lugares',
  ][_index];

  String nestedCount(int count) => [
    '${itemCount(count)}, incluindo os locais de dentro',
    '${itemCount(count)}, including nested places',
    '${itemCount(count)}, incluidos los lugares interiores',
  ][_index];

  String editNamed(String name) =>
      ['Editar $name', 'Edit $name', 'Editar $name'][_index];
  String enlargePhoto(String name) => [
    'Ampliar foto de $name',
    'Enlarge photo of $name',
    'Ampliar foto de $name',
  ][_index];
  String createdAt(String date) =>
      ['Cadastrado em $date', 'Added on $date', 'Registrado el $date'][_index];
  String updatedAt(String date) => [
    'Última alteração em $date',
    'Last changed on $date',
    'Último cambio el $date',
  ][_index];
  String previousPlace(String date, String place) => [
    '$date · antes: $place',
    '$date · previously: $place',
    '$date · antes: $place',
  ][_index];
}
