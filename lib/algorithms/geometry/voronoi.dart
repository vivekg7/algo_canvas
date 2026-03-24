import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';

class VoronoiState extends AlgorithmState {
  const VoronoiState({
    required this.sites,
    required this.cellColors,
    required this.gridW,
    required this.gridH,
    this.grid,
    this.currentSite,
    required super.description,
  });

  final List<(double, double)> sites;
  final List<Color> cellColors;
  final int gridW;
  final int gridH;

  /// Grid of site indices (flattened). null means not yet computed.
  final List<int>? grid;
  final int? currentSite;
}

class VoronoiAlgorithm extends Algorithm {
  int _siteCount = 15;

  @override
  String get name => 'Voronoi Diagram';
  @override
  String get description => 'Partition plane into regions closest to each site. Brute-force O(n×pixels).';
  @override
  AlgorithmCategory get category => AlgorithmCategory.computationalGeometry;

  @override
  Future<List<AlgorithmState>> generate() async {
    final random = Random();
    final n = _siteCount;
    final sites = List.generate(n, (_) => (random.nextDouble(), random.nextDouble()));
    const gridW = 80, gridH = 60;

    // Generate distinct colors
    final colors = List.generate(n, (i) {
      final hue = (i * 360 / n) % 360;
      return HSVColor.fromAHSV(1, hue, 0.6, 0.85).toColor();
    });

    final states = <VoronoiState>[];

    states.add(VoronoiState(
      sites: sites, cellColors: colors, gridW: gridW, gridH: gridH,
      description: 'Voronoi: $n sites, computing nearest for each pixel',
    ));

    // Compute Voronoi by brute force
    final grid = List.filled(gridW * gridH, 0);
    for (var y = 0; y < gridH; y++) {
      for (var x = 0; x < gridW; x++) {
        final px = x / gridW;
        final py = y / gridH;
        var minDist = double.infinity;
        var nearest = 0;
        for (var i = 0; i < n; i++) {
          final dx = px - sites[i].$1;
          final dy = py - sites[i].$2;
          final dist = dx * dx + dy * dy;
          if (dist < minDist) { minDist = dist; nearest = i; }
        }
        grid[y * gridW + x] = nearest;
      }

      // Emit every few rows
      if (y % 5 == 0) {
        states.add(VoronoiState(
          sites: sites, cellColors: colors, gridW: gridW, gridH: gridH,
          grid: List.of(grid), currentSite: null,
          description: 'Computing row ${y + 1}/$gridH',
        ));
      }
    }

    states.add(VoronoiState(
      sites: sites, cellColors: colors, gridW: gridW, gridH: gridH,
      grid: grid,
      description: 'Voronoi diagram complete — $n regions',
    ));

    return states;
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) =>
      _VoronoiPainter(state: state as VoronoiState, brightness: Theme.of(context).brightness);

  @override
  Widget? buildControls({required VoidCallback onChanged}) =>
      _Ctrl(count: _siteCount, onChanged: (v) { _siteCount = v; onChanged(); });
}

class _VoronoiPainter extends CustomPainter {
  _VoronoiPainter({required this.state, required this.brightness});

  final VoronoiState state;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final isDark = brightness == Brightness.dark;

    if (state.grid != null) {
      final cellW = size.width / state.gridW;
      final cellH = size.height / state.gridH;

      for (var y = 0; y < state.gridH; y++) {
        for (var x = 0; x < state.gridW; x++) {
          final siteIdx = state.grid![y * state.gridW + x];
          final color = state.cellColors[siteIdx].withValues(
            alpha: isDark ? 0.5 : 0.4,
          );
          canvas.drawRect(
            Rect.fromLTWH(x * cellW, y * cellH, cellW + 0.5, cellH + 0.5),
            Paint()..color = color,
          );
        }
      }
    }

    // Draw sites
    for (var i = 0; i < state.sites.length; i++) {
      final (sx, sy) = state.sites[i];
      canvas.drawCircle(
        Offset(sx * size.width, sy * size.height),
        5,
        Paint()..color = isDark ? Colors.white : Colors.black,
      );
      canvas.drawCircle(
        Offset(sx * size.width, sy * size.height),
        3,
        Paint()..color = state.cellColors[i],
      );
    }
  }

  @override
  bool shouldRepaint(covariant _VoronoiPainter oldDelegate) =>
      oldDelegate.state != state;
}

class _Ctrl extends StatefulWidget {
  const _Ctrl({required this.count, required this.onChanged});
  final int count; final ValueChanged<int> onChanged;
  @override State<_Ctrl> createState() => _CtrlState();
}
class _CtrlState extends State<_Ctrl> {
  late double _v;
  @override void initState() { super.initState(); _v = widget.count.toDouble(); }
  @override Widget build(BuildContext context) => Row(children: [
    Text('Sites: ${_v.round()}', style: Theme.of(context).textTheme.bodySmall),
    Expanded(child: Slider(value: _v, min: 3, max: 30, divisions: 27,
      onChanged: (v) => setState(() => _v = v), onChangeEnd: (v) => widget.onChanged(v.round()))),
  ]);
}
