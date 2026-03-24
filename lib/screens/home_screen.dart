import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_registry.dart';
import 'package:algo_canvas/screens/settings_screen.dart';
import 'package:algo_canvas/screens/visualizer_screen.dart';
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
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    SettingsScreen(themeController: themeController),
              ),
            ),
          ),
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
