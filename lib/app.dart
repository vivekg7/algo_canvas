import 'package:flutter/material.dart';
import 'package:algo_canvas/screens/home_screen.dart';
import 'package:algo_canvas/theme/theme_controller.dart';

class AlgoCanvasApp extends StatelessWidget {
  const AlgoCanvasApp({super.key, required this.themeController});

  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    return ThemeControllerScope(
      controller: themeController,
      child: ListenableBuilder(
        listenable: themeController,
        builder: (context, _) {
          return MaterialApp(
            title: 'Algo Canvas',
            theme: themeController.lightTheme,
            darkTheme: themeController.darkTheme,
            themeMode: themeController.themeMode,
            debugShowCheckedModeBanner: false,
            home: HomeScreen(themeController: themeController),
          );
        },
      ),
    );
  }
}
