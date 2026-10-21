import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onde_guardei/domain/repository.dart';
import 'package:onde_guardei/ui/home.dart';

const nativeFiles = MethodChannel('br.com.valdenor.ondeguardei/files');

ThemeData appTheme() => ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: Color(0xFFF7F5EF),
  colorScheme: ColorScheme.fromSeed(
    seedColor: Color(0xFF234B40),
    primary: Color(0xFF234B40),
    surface: Color(0xFFF7F5EF),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFF7F5EF),
    foregroundColor: Color(0xFF263C35),
    centerTitle: false,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(48, 52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
);

class OndeGuardeiApp extends StatelessWidget {
  final CatalogRepository repository;
  const OndeGuardeiApp({super.key, required this.repository});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Onde Guardei?',
    debugShowCheckedModeBanner: false,
    theme: appTheme(),
    home: Home(repository),
  );
}
