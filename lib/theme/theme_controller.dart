import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:algo_canvas/theme/app_theme.dart';

class ThemeController extends ChangeNotifier {
  ThemeController() {
    _load();
  }

  static const _themeKey = 'theme_mode';
  static const _accentKey = 'accent_color';

  AppThemeMode _mode = AppThemeMode.system;
  AccentColor _accent = AccentColor.deepPurple;

  AppThemeMode get mode => _mode;
  AccentColor get accent => _accent;

  ThemeData get lightTheme => AppTheme.light(_accent.seed);

  ThemeData get darkTheme {
    return _mode == AppThemeMode.amoled
        ? AppTheme.amoled(_accent.seed)
        : AppTheme.dark(_accent.seed);
  }

  ThemeMode get themeMode {
    switch (_mode) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
      case AppThemeMode.amoled:
        return ThemeMode.dark;
    }
  }

  Future<void> setMode(AppThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.name);
  }

  Future<void> setAccent(AccentColor accent) async {
    if (_accent == accent) return;
    _accent = accent;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accentKey, accent.name);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    final storedTheme = prefs.getString(_themeKey);
    if (storedTheme != null) {
      _mode = AppThemeMode.values.firstWhere(
        (m) => m.name == storedTheme,
        orElse: () => AppThemeMode.system,
      );
    }

    final storedAccent = prefs.getString(_accentKey);
    if (storedAccent != null) {
      _accent = AccentColor.values.firstWhere(
        (a) => a.name == storedAccent,
        orElse: () => AccentColor.deepPurple,
      );
    }

    notifyListeners();
  }
}
