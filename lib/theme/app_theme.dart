import 'package:flutter/material.dart';

enum AppThemeMode { system, light, dark, amoled }

class AppTheme {
  AppTheme._();

  static const _seedColor = Colors.deepPurple;

  static ThemeData light() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    );
  }

  static ThemeData dark() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );
  }

  static ThemeData amoled() {
    final darkScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
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
