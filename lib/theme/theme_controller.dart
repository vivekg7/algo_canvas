import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:algo_canvas/theme/app_theme.dart';

class ThemeController extends ChangeNotifier {
  ThemeController() {
    _load();
  }

  static const _key = 'theme_mode';

  AppThemeMode _mode = AppThemeMode.system;
  AppThemeMode get mode => _mode;

  ThemeData get lightTheme => AppTheme.light();

  ThemeData get darkTheme {
    return _mode == AppThemeMode.amoled ? AppTheme.amoled() : AppTheme.dark();
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
    await prefs.setString(_key, mode.name);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);
    if (stored != null) {
      _mode = AppThemeMode.values.firstWhere(
        (m) => m.name == stored,
        orElse: () => AppThemeMode.system,
      );
      notifyListeners();
    }
  }
}
