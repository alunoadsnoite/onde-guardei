import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

enum AppLanguage {
  portuguese('pt-BR', 'Português (Brasil)', Locale('pt', 'BR')),
  english('en-US', 'English', Locale('en', 'US')),
  spanish('es-ES', 'Español', Locale('es', 'ES'));

  const AppLanguage(this.tag, this.label, this.locale);

  final String tag;
  final String label;
  final Locale locale;

  static AppLanguage parse(String? tag) => values.firstWhere(
    (language) => language.tag == tag,
    orElse: () => portuguese,
  );
}

class CatalogStrings {
  const CatalogStrings(this.locale);

  static const delegate = _CatalogStringsDelegate();
  static final _placeholder = RegExp(r'\{(\d+)\}');
  final Locale locale;

  String text(String source, [List<Object> args = const []]) {
    final pair = _translations[source];
    final template = switch (locale.languageCode) {
      'en' => pair?.$1 ?? source,
      'es' => pair?.$2 ?? source,
      _ => source,
    };
    return template.replaceAllMapped(_placeholder, (match) {
      final index = int.parse(match[1]!);
      return index < args.length ? args[index].toString() : match[0]!;
    });
  }
}

extension CatalogLocalization on BuildContext {
  CatalogStrings get strings =>
      Localizations.of<CatalogStrings>(this, CatalogStrings) ??
      const CatalogStrings(Locale('pt', 'BR'));
}

class _CatalogStringsDelegate extends LocalizationsDelegate<CatalogStrings> {
  const _CatalogStringsDelegate();

  @override
  bool isSupported(Locale locale) => AppLanguage.values.any(
    (language) => language.locale.languageCode == locale.languageCode,
  );

  @override
  Future<CatalogStrings> load(Locale locale) =>
      SynchronousFuture(CatalogStrings(locale));

  @override
  bool shouldReload(_CatalogStringsDelegate old) => false;
}

const _translations = <String, (String, String)>{
  "A foto escolhida não está mais disponível. Selecione-a novamente.": (
    "The selected photo is no longer available. Select it again.",
    "La foto elegida ya no está disponible. Selecciónala de nuevo.",
  ),
  "A foto não está disponível. Selecione-a novamente.": (
    "The photo is unavailable. Select it again.",
    "La foto no está disponible. Selecciónala de nuevo.",
  ),
  "A organização dos locais contém um ciclo ou local ausente.": (
    "The location hierarchy has a loop or a missing location.",
    "La jerarquía de lugares tiene un ciclo o falta un lugar.",
  ),
  "Adicione um nome ou uma foto para guardar este objeto.": (
    "Add a name or photo to save this item.",
    "Añade un nombre o una foto para guardar este objeto.",
  ),
  "Ampliar foto de {0}": ("Enlarge photo of {0}", "Ampliar foto de {0}"),
  "Anotações": ("Notes", "Notas"),
  "Aparência": ("Appearance", "Apariencia"),
  "Automático": ("Automatic", "Automático"),
  "Backup salvo com os cadastros e as fotos.": (
    "Backup saved with items, locations and photos.",
    "Copia guardada con los objetos, lugares y fotos.",
  ),
  "Backup salvo, mas {0} foto(s) não estavam no aparelho e ficaram de fora.": (
    "Backup saved. Missing photos left out: {0}.",
    "Copia guardada. Fotos ausentes que quedaron fuera: {0}.",
  ),
  "Buscar por nome, local ou anotação": (
    "Search by name, location or note",
    "Buscar por nombre, lugar o nota",
  ),
  "Buscar por parte do caminho": (
    "Search by part of the location path",
    "Buscar por parte de la ruta",
  ),
  "Cadastrado em {0}": ("Added on {0}", "Registrado el {0}"),
  "Cadastre seu primeiro objeto com uma foto, um nome ou os dois. Depois, conte onde ele fica.": (
    "Save your first item with a photo, a name or both. Then add where it is.",
    "Guarda tu primer objeto con una foto, un nombre o ambos. Luego indica dónde está.",
  ),
  "Cadastro de objeto inválido.": (
    "Invalid item record.",
    "Registro de objeto no válido.",
  ),
  "Cancelar": ("Cancel", "Cancelar"),
  "Catálogo restaurado, com as fotos.": (
    "Catalog restored, including photos.",
    "Catálogo restaurado, incluidas las fotos.",
  ),
  "Claro": ("Light", "Claro"),
  "Como você organiza sua casa?": (
    "How do you organize your home?",
    "¿Cómo organizas tu casa?",
  ),
  "Configurações e backup": (
    "Settings and backup",
    "Ajustes y copias de seguridad",
  ),
  "Continuar cadastro não salvo": (
    "Continue unsaved item",
    "Continuar el registro sin guardar",
  ),
  "Criar backup com fotos": ("Back up with photos", "Crear copia con fotos"),
  "Criar local": ("Add location", "Añadir lugar"),
  "Crie um cômodo, depois um móvel ou uma caixa dentro dele. Exemplo: quarto › armário › caixa azul.": (
    "Add a room, then furniture or a box inside it. Example: bedroom › closet › blue box.",
    "Añade una habitación y luego un mueble o una caja dentro. Ejemplo: dormitorio › armario › caja azul.",
  ),
  "Cuidando do seu catálogo…": (
    "Working on your catalog…",
    "Procesando tu catálogo…",
  ),
  "Dentro de qual local?": ("Inside which location?", "¿Dentro de qué lugar?"),
  "Desenvolvedor": ("Developer", "Desarrollador"),
  "Detalhes que ajudam você a lembrar": (
    "Details to help you remember",
    "Detalles que te ayuden a recordar",
  ),
  "Dispensar aviso": ("Dismiss notice", "Cerrar aviso"),
  "Dê um nome a este local.": (
    "Give this location a name.",
    "Ponle un nombre a este lugar.",
  ),
  "Editar local": ("Edit location", "Editar lugar"),
  "Editar objeto": ("Edit item", "Editar objeto"),
  "Editar {0}": ("Edit {0}", "Editar {0}"),
  "Encontre o que você guardou.": (
    "Find what you put away.",
    "Encuentra lo que guardaste.",
  ),
  "Enviar e-mail": ("Send email", "Enviar correo"),
  "Escolha uma foto de até 15 MB.": (
    "Choose a photo up to 15 MB.",
    "Elige una foto de hasta 15 MB.",
  ),
  "Escolher backup": ("Choose backup", "Elegir copia de seguridad"),
  "Escolher foto": ("Choose photo", "Elegir foto"),
  "Escuro": ("Dark", "Oscuro"),
  "Este arquivo não é um backup do Onde Guardei?.": (
    "This file is not an Onde Guardei? backup.",
    "Este archivo no es una copia de Onde Guardei?.",
  ),
  "Este arquivo não é um backup válido do Onde Guardei?.": (
    "This file is not a valid Onde Guardei? backup.",
    "Este archivo no es una copia válida de Onde Guardei?.",
  ),
  "Este backup está sem alguma das fotos e não pode ser restaurado.": (
    "Some photos are missing from this backup, so it cannot be restored.",
    "Faltan algunas fotos en esta copia, así que no se puede restaurar.",
  ),
  "Este backup está sem as fotos e não pode ser restaurado.": (
    "This backup is missing its photos and cannot be restored.",
    "Faltan las fotos en esta copia y no se puede restaurar.",
  ),
  "Este catálogo excede o limite de 70 MB de fotos por backup nesta versão.": (
    "This catalog exceeds the 70 MB photo limit per backup in this version.",
    "Este catálogo supera el límite de 70 MB de fotos por copia en esta versión.",
  ),
  "Ex.: cabo, Dell, computador": (
    "Example: cable, Dell, computer",
    "Ejemplo: cable, Dell, ordenador",
  ),
  "Ex.: carregador do notebook": (
    "Example: laptop charger",
    "Ejemplo: cargador del portátil",
  ),
  "Ex.: chave, gaveta ou reserva": (
    "Example: key, drawer or spare",
    "Ejemplo: llave, cajón o repuesto",
  ),
  "Excluir": ("Delete", "Eliminar"),
  "Excluir este objeto?": ("Delete this item?", "¿Eliminar este objeto?"),
  "Excluir local": ("Delete location", "Eliminar lugar"),
  "Excluir local?": ("Delete location?", "¿Eliminar el lugar?"),
  "Excluir objeto": ("Delete item", "Eliminar objeto"),
  "Fechar": ("Close", "Cerrar"),
  "Fica na raiz da casa": (
    "At the top level of the home",
    "Está en el nivel principal de la casa",
  ),
  "Foto indisponível.": ("Photo unavailable.", "Foto no disponible."),
  "Foto opcional do objeto ou de onde ele fica": (
    "Optional photo of the item or its location",
    "Foto opcional del objeto o de dónde está",
  ),
  "Guardar e sair": ("Save draft and leave", "Guardar borrador y salir"),
  "Guardar objeto": ("Save item", "Guardar objeto"),
  "Idioma": ("Language", "Idioma"),
  "Já há uma seleção de arquivo aberta.": (
    "A file picker is already open.",
    "Ya hay un selector de archivos abierto.",
  ),
  "Licenças": ("Licenses", "Licencias"),
  "Limpar busca": ("Clear search", "Borrar búsqueda"),
  "Locais": ("Locations", "Lugares"),
  "Locais com objetos ou outros locais dentro precisam ser esvaziados primeiro.":
      (
        "Empty this location of items and other locations before deleting it.",
        "Retira los objetos y otros lugares de este lugar antes de eliminarlo.",
      ),
  "Local atualizado.": ("Location updated.", "Lugar actualizado."),
  "Local desconhecido": ("Unknown location", "Lugar desconocido"),
  "Local inválido ou repetido.": (
    "Invalid or duplicate location.",
    "Lugar no válido o duplicado.",
  ),
  "Mova os objetos e os locais de dentro antes de excluir este local.": (
    "Move the items and locations inside this location before deleting it.",
    "Mueve los objetos y lugares que hay dentro antes de eliminar este lugar.",
  ),
  "Mudanças de lugar": ("Location history", "Historial de lugares"),
  "Mudei de lugar": ("I moved it", "Lo cambié de sitio"),
  "Na raiz da casa": (
    "At the top level of the home",
    "En el nivel principal de la casa",
  ),
  "Nada encontrado por aqui.": ("Nothing found here.", "No se encontró nada."),
  "Nome de foto inválido.": (
    "Invalid photo name.",
    "Nombre de foto no válido.",
  ),
  "Nome do local": ("Location name", "Nombre del lugar"),
  "Nome do objeto": ("Item name", "Nombre del objeto"),
  "Novo local": ("New location", "Nuevo lugar"),
  "Não conseguimos abrir seu catálogo.": (
    "We couldn't open your catalog.",
    "No pudimos abrir tu catálogo.",
  ),
  "Não foi possível abrir a câmera ou as fotos. Verifique a permissão nas configurações do Android.": (
    "Could not open the camera or photos. Check permissions in Android settings.",
    "No se pudieron abrir la cámara o las fotos. Comprueba el permiso en los ajustes de Android.",
  ),
  "Não foi possível abrir o e-mail": (
    "Could not open email",
    "No se pudo abrir el correo",
  ),
  "Não foi possível abrir o seletor de arquivos.": (
    "Could not open the file picker.",
    "No se pudo abrir el selector de archivos.",
  ),
  "Não foi possível abrir os dados. Seus arquivos foram preservados; não reinstale o aplicativo.": (
    "Could not open your data. Your files were preserved. Keep the app installed.",
    "No se pudieron abrir los datos. Tus archivos se conservaron. Mantén la app instalada.",
  ),
  "Não foi possível concluir. Seus cadastros anteriores foram preservados. Tente novamente.": (
    "Could not finish. Your existing records were preserved. Try again.",
    "No se pudo completar. Se conservaron tus registros. Inténtalo de nuevo.",
  ),
  "Não foi possível copiar a foto para o aplicativo.": (
    "Could not copy the photo to the app.",
    "No se pudo copiar la foto a la app.",
  ),
  "Não foi possível copiar o backup.": (
    "Could not copy the backup.",
    "No se pudo copiar la copia de seguridad.",
  ),
  "Não foi possível criar o backup porque uma foto não está no aparelho. Selecione novamente ou remova as fotos indisponíveis dos cadastros e tente outra vez.": (
    "Could not create a backup because a photo is missing from the device. Select the missing photos again or remove them from their records and retry.",
    "No se pudo crear la copia porque falta una foto en el dispositivo. Vuelve a seleccionar las fotos que faltan o quítalas de sus registros e inténtalo de nuevo.",
  ),
  "Não foi possível recuperar a última foto. Você pode selecioná-la novamente.":
      (
        "Could not recover the last photo. You can select it again.",
        "No se pudo recuperar la última foto. Puedes seleccionarla de nuevo.",
      ),
  "Não foi possível salvar a aparência.": (
    "Could not save the appearance setting.",
    "No se pudo guardar la apariencia.",
  ),
  "Não foi possível salvar o idioma.": (
    "Could not save the language setting.",
    "No se pudo guardar el idioma.",
  ),
  "O arquivo excede o limite de 100 MB.": (
    "The file exceeds the 100 MB limit.",
    "El archivo supera el límite de 100 MB.",
  ),
  "O backup está corrompido e não pôde ser lido. Tente outro arquivo.": (
    "The backup is corrupted and could not be read. Try a different file.",
    "La copia está dañada y no se pudo leer. Prueba con otro archivo.",
  ),
  "O backup substituirá os objetos e locais atuais. Crie um backup antes se quiser guardar os dados que estão aqui.": (
    "The backup will replace your current items and locations. Make a backup first if you want to keep your current data.",
    "La copia sustituirá tus objetos y lugares actuales. Haz una copia primero si quieres conservar los datos actuales.",
  ),
  "O cadastro será removido do seu catálogo.": (
    "The item will be removed from your catalog.",
    "El objeto se eliminará de tu catálogo.",
  ),
  "O catálogo funciona sem conta e sem internet. Fotos e textos ficam no aparelho. Guarde um backup fora do app antes de trocar de celular ou desinstalar.\n\nCódigo aberto • licença MIT": (
    "The catalog works offline without an account. Photos and text stay on your device. Keep a backup outside the app before switching phones or uninstalling.\n\nOpen source • MIT license",
    "El catálogo funciona sin cuenta y sin conexión. Las fotos y los textos se guardan en el dispositivo. Guarda una copia fuera de la app antes de cambiar de teléfono o desinstalarla.\n\nCódigo abierto • licencia MIT",
  ),
  "O que você escreveu será guardado como rascunho para continuar depois.": (
    "Your changes will be saved as a draft so you can finish later.",
    "Tus cambios se guardarán como borrador para que puedas continuar más tarde.",
  ),
  "ONDE ESTÁ": ("WHERE IT IS", "DÓNDE ESTÁ"),
  "Objeto não encontrado.": ("Item not found.", "No se encontró el objeto."),
  "Objeto sem nome": ("Unnamed item", "Objeto sin nombre"),
  "Objetos": ("Items", "Objetos"),
  "Onde Guardei? — dúvida ou sugestão": (
    "Onde Guardei? — question or suggestion",
    "Onde Guardei? — pregunta o sugerencia",
  ),
  "Onde fica?": ("Where is it?", "¿Dónde está?"),
  "Opcional se você adicionar uma foto": (
    "Optional if you add a photo",
    "Opcional si añades una foto",
  ),
  "Os arquivos foram preservados. Não reinstale o app; tente abrir novamente.": (
    "Your files were preserved. Keep the app installed and try opening it again.",
    "Tus archivos se conservaron. Mantén la app instalada e intenta abrirla de nuevo.",
  ),
  "Palavras para encontrar": ("Search keywords", "Palabras clave"),
  "Quarto, armário, caixa azul…": (
    "Bedroom, closet, blue box…",
    "Dormitorio, armario, caja azul…",
  ),
  "Recuperamos a versão anterior dos seus cadastros. Crie um backup.": (
    "We recovered the previous version of your records. Create a backup.",
    "Recuperamos la versión anterior de tus registros. Crea una copia de seguridad.",
  ),
  "Remover foto": ("Remove photo", "Quitar foto"),
  "Restaurar backup": ("Restore backup", "Restaurar copia"),
  "Restaurar catálogo?": ("Restore catalog?", "¿Restaurar el catálogo?"),
  "Sair do cadastro?": ("Leave this form?", "¿Salir del formulario?"),
  "Salvar local": ("Save location", "Guardar lugar"),
  "Seguir a aparência do aparelho": (
    "Follow the device appearance",
    "Seguir la apariencia del dispositivo",
  ),
  "Selecionado": ("Selected", "Seleccionado"),
  "Sem local definido": ("No location set", "Sin lugar definido"),
  "Seu objeto": ("Your item", "Tu objeto"),
  "Sobre e suporte": ("About and support", "Acerca de y asistencia"),
  "Tentar novamente": ("Try again", "Inténtalo de nuevo"),
  "Tente outra palavra ou escolha outro local.": (
    "Try another word or choose another location.",
    "Prueba con otra palabra o elige otro lugar.",
  ),
  "Tirar foto": ("Take photo", "Hacer foto"),
  "Um lugar para lembrar.": ("A place to remember.", "Un lugar para recordar."),
  "Uma foto do backup excede 15 MB.": (
    "A photo in the backup exceeds 15 MB.",
    "Una foto de la copia supera los 15 MB.",
  ),
  "Versão de arquivo não suportada.": (
    "Unsupported file version.",
    "Versión de archivo no compatible.",
  ),
  "{0} locais": ("{0} locations", "{0} lugares"),
  "{0} local": ("{0} location", "{0} lugar"),
  "{0} objeto": ("{0} item", "{0} objeto"),
  "{0} objeto, incluindo os locais de dentro": (
    "{0} item, including nested locations",
    "{0} objeto, incluidos los lugares que hay dentro",
  ),
  "{0} objetos": ("{0} items", "{0} objetos"),
  "{0} objetos, incluindo os locais de dentro": (
    "{0} items, including nested locations",
    "{0} objetos, incluidos los lugares que hay dentro",
  ),
  "{0} · antes: {1}": ("{0} · before: {1}", "{0} · antes: {1}"),
  "Última alteração em {0}": ("Last changed on {0}", "Último cambio el {0}"),
};
