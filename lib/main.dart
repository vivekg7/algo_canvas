import 'package:flutter/material.dart';
import 'package:algo_canvas/app.dart';
import 'package:algo_canvas/theme/theme_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final themeController = ThemeController();
  runApp(AlgoCanvasApp(themeController: themeController));
}
