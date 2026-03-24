import 'package:flutter/material.dart';

enum AppThemeMode { system, light, dark, amoled }

enum AccentColor {
  deepPurple('Deep Purple', Colors.deepPurple),
  blue('Blue', Colors.blue),
  teal('Teal', Colors.teal),
  green('Green', Colors.green),
  amber('Amber', Colors.amber),
  orange('Orange', Colors.orange),
  red('Red', Colors.red),
  pink('Pink', Colors.pink),
  indigo('Indigo', Colors.indigo),
  cyan('Cyan', Colors.cyan);

  const AccentColor(this.label, this.seed);
  final String label;
  final Color seed;
}

class AppTheme {
  AppTheme._();

  static ThemeData light(Color seedColor) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    );
  }

  static ThemeData dark(Color seedColor) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );
  }

  static ThemeData amoled(Color seedColor) {
    final darkScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );

    return ThemeData(
      colorScheme: darkScheme.copyWith(
        surface: Colors.black,
        onSurface: Colors.white,
      ),
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFF121212),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xFF121212),
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: Color(0xFF121212),
      ),
      useMaterial3: true,
    );
  }
}
