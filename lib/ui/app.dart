import 'package:onde_guardei/ui/catalog_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:onde_guardei/domain/repository.dart';
import 'package:onde_guardei/ui/home.dart';

const nativeFiles = MethodChannel('br.com.valdenor.ondeguardei/files');

/// Versão mostrada ao usuário. Mantenha em sincronia com `pubspec.yaml`.
const appVersion = '0.4.0';
const appName = 'Onde Guardei?';

ThemeData appTheme([Brightness brightness = Brightness.light]) {
  const green = Color(0xFF234B40);
  final generated = ColorScheme.fromSeed(
    seedColor: green,
    brightness: brightness,
  );
  final colors = brightness == Brightness.light
      ? generated.copyWith(
          primary: green,
          surface: const Color(0xFFF7F5EF),
          onSurface: const Color(0xFF263C35),
          surfaceContainerLowest: Colors.white,
          secondaryContainer: const Color(0xFFE8EDE5),
          onSecondaryContainer: green,
        )
      : generated;

  return ThemeData(
    useMaterial3: true,
    colorScheme: colors,
    scaffoldBackgroundColor: colors.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: colors.surface,
      foregroundColor: colors.onSurface,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.surfaceContainerLowest,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  );
}

Future<ThemeMode> readThemeMode() async {
  try {
    final saved = await nativeFiles.invokeMethod<String>('readThemeMode');
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == saved,
      orElse: () => ThemeMode.system,
    );
  } on PlatformException {
    return ThemeMode.system;
  } on MissingPluginException {
    return ThemeMode.system;
  }
}

Future<AppLanguage> readAppLanguage() async {
  try {
    return AppLanguage.parse(
      await nativeFiles.invokeMethod<String>('readLanguage'),
    );
  } on PlatformException {
    return AppLanguage.portuguese;
  } on MissingPluginException {
    return AppLanguage.portuguese;
  }
}

final supportedCatalogLocales = AppLanguage.values.map(
  (language) => language.locale,
);
const catalogLocalizations = [
  CatalogStrings.delegate,
  ...GlobalMaterialLocalizations.delegates,
];

class OndeGuardeiApp extends StatefulWidget {
  final CatalogRepository repository;
  final ThemeMode initialThemeMode;
  final AppLanguage initialLanguage;
  const OndeGuardeiApp({
    super.key,
    required this.repository,
    this.initialThemeMode = ThemeMode.system,
    this.initialLanguage = AppLanguage.portuguese,
  });

  @override
  State<OndeGuardeiApp> createState() => _OndeGuardeiAppState();
}

class _OndeGuardeiAppState extends State<OndeGuardeiApp> {
  late ThemeMode themeMode = widget.initialThemeMode;
  late AppLanguage language = widget.initialLanguage;

  Future<void> setLanguage(AppLanguage value) async {
    await nativeFiles.invokeMethod<void>('writeLanguage', value.tag);
    if (mounted) setState(() => language = value);
  }

  Future<void> setThemeMode(ThemeMode value) async {
    await nativeFiles.invokeMethod<void>('writeThemeMode', value.name);
    if (mounted) setState(() => themeMode = value);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: appName,
    locale: language.locale,
    supportedLocales: supportedCatalogLocales,
    localizationsDelegates: catalogLocalizations,
    debugShowCheckedModeBanner: false,
    theme: appTheme(),
    darkTheme: appTheme(Brightness.dark),
    themeMode: themeMode,
    home: Home(
      widget.repository,
      themeMode: themeMode,
      onThemeChanged: setThemeMode,
      language: language,
      onLanguageChanged: setLanguage,
    ),
  );
}
