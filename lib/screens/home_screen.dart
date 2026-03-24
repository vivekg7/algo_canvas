import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_registry.dart';
import 'package:algo_canvas/screens/visualizer_screen.dart';
import 'package:algo_canvas/theme/app_theme.dart';
import 'package:algo_canvas/theme/theme_controller.dart';
import 'package:algo_canvas/widgets/algorithm_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.themeController});

  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    final algorithms = AlgorithmRegistry.all;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Algo Canvas'),
        actions: [
          _ThemeButton(controller: themeController),
        ],
      ),
      body: algorithms.isEmpty
          ? const Center(child: Text('No algorithms registered yet.'))
          : LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = _crossAxisCount(constraints.maxWidth);
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.6,
                  ),
                  itemCount: algorithms.length,
                  itemBuilder: (context, index) {
                    final algorithm = algorithms[index];
                    return AlgorithmCard(
                      algorithm: algorithm,
                      onTap: () => _openVisualizer(context, algorithm),
                    );
                  },
                );
              },
            ),
    );
  }

  int _crossAxisCount(double width) {
    if (width >= 1200) return 4;
    if (width >= 800) return 3;
    if (width >= 500) return 2;
    return 1;
  }

  void _openVisualizer(BuildContext context, Algorithm algorithm) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VisualizerScreen(algorithm: algorithm),
      ),
    );
  }
}

class _ThemeButton extends StatelessWidget {
  const _ThemeButton({required this.controller});

  final ThemeController controller;

  static const _icons = {
    AppThemeMode.system: Icons.brightness_auto_outlined,
    AppThemeMode.light: Icons.light_mode_outlined,
    AppThemeMode.dark: Icons.dark_mode_outlined,
    AppThemeMode.amoled: Icons.smartphone_outlined,
  };

  static const _labels = {
    AppThemeMode.system: 'System',
    AppThemeMode.light: 'Light',
    AppThemeMode.dark: 'Dark',
    AppThemeMode.amoled: 'AMOLED',
  };

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return PopupMenuButton<AppThemeMode>(
          initialValue: controller.mode,
          onSelected: controller.setMode,
          tooltip: 'Theme',
          icon: Icon(_icons[controller.mode]),
          itemBuilder: (context) => AppThemeMode.values.map((mode) {
            return PopupMenuItem(
              value: mode,
              child: Row(
                children: [
                  Icon(_icons[mode], size: 20),
                  const SizedBox(width: 12),
                  Text(_labels[mode]!),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
