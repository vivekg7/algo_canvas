import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_registry.dart';
import 'package:algo_canvas/screens/settings_screen.dart';
import 'package:algo_canvas/screens/visualizer_screen.dart';
import 'package:algo_canvas/theme/theme_controller.dart';
import 'package:algo_canvas/widgets/algorithm_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.themeController});

  final ThemeController themeController;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  AlgorithmCategory? _selectedCategory;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Algorithm> get _filtered {
    var results = AlgorithmRegistry.all;

    if (_selectedCategory != null) {
      results = results
          .where((a) => a.category == _selectedCategory)
          .toList();
    }

    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      results = results
          .where((a) =>
              a.name.toLowerCase().contains(q) ||
              a.description.toLowerCase().contains(q) ||
              a.category.label.toLowerCase().contains(q))
          .toList();
    }

    return results;
  }

  /// Categories that actually have registered algorithms.
  Set<AlgorithmCategory> get _availableCategories {
    return AlgorithmRegistry.all.map((a) => a.category).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final colorScheme = Theme.of(context).colorScheme;

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
                    SettingsScreen(themeController: widget.themeController),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search algorithms...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                isDense: true,
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          // Category filter chips
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: const Text('All'),
                      selected: _selectedCategory == null,
                      onSelected: (_) =>
                          setState(() => _selectedCategory = null),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  for (final category in _availableCategories)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        label: Text(category.label),
                        selected: _selectedCategory == category,
                        onSelected: (_) => setState(() {
                          _selectedCategory =
                              _selectedCategory == category ? null : category;
                        }),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Algorithm grid
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'No algorithms found.',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount =
                          _crossAxisCount(constraints.maxWidth);
                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.6,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final algorithm = filtered[index];
                          return AlgorithmCard(
                            algorithm: algorithm,
                            onTap: () =>
                                _openVisualizer(context, algorithm),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
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
