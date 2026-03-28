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

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  AlgorithmCategory? _selectedCategory;
  String _query = '';
  bool _isSearching = false;
  late final AnimationController _staggerController;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _restartStagger() {
    _staggerController.forward(from: 0);
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
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search algorithms...',
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() => _query = value);
                  _restartStagger();
                },
              )
            : const Text('Algo Canvas'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            tooltip: _isSearching ? 'Close search' : 'Search',
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  _query = '';
                  _restartStagger();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
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
                      onSelected: (_) {
                        setState(() => _selectedCategory = null);
                        _restartStagger();
                      },
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  for (final category in _availableCategories)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        avatar: Icon(category.icon, size: 16),
                        label: Text(category.label),
                        selected: _selectedCategory == category,
                        onSelected: (_) {
                          setState(() {
                            _selectedCategory =
                                _selectedCategory == category ? null : category;
                          });
                          _restartStagger();
                        },
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
                      if (crossAxisCount == 1) {
                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) =>
                              _buildItem(filtered, index),
                        );
                      }
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
                        itemBuilder: (context, index) =>
                            _buildItem(filtered, index),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(List<Algorithm> filtered, int index) {
    final algorithm = filtered[index];
    final card = Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AlgorithmCard(
        algorithm: algorithm,
        onTap: () => _openVisualizer(context, algorithm),
      ),
    );
    if (!widget.themeController.animationsEnabled) {
      return card;
    }
    final start = (index.clamp(0, 11) * 0.05);
    final end = (start + 0.4).clamp(0.0, 1.0);
    final animation = CurvedAnimation(
      parent: _staggerController,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(animation),
        child: card,
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
    final screen = VisualizerScreen(algorithm: algorithm);
    if (!widget.themeController.animationsEnabled) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, _, _) => screen,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
      return;
    }
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => screen,
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              )),
              child: child,
            ),
          );
        },
      ),
    );
  }
}
