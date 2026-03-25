import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';

class DragonCurveState extends AlgorithmState {
  const DragonCurveState({required this.points, required this.depth, required super.description});
  final List<(double, double)> points;
  final int depth;
}

class DragonCurveAlgorithm extends Algorithm {
  int _maxDepth = 12;

  @override String get name => 'Dragon Curve';
  @override String get description => 'Paper-folding fractal: fold right, unfold, repeat.';
  @override AlgorithmCategory get category => AlgorithmCategory.fractals;

  @override
  Future<List<AlgorithmState>> generate() async {
    final states = <DragonCurveState>[];

    for (var depth = 0; depth <= _maxDepth; depth++) {
      // Generate turns: R=1, L=0
      var turns = <int>[];
      for (var d = 0; d < depth; d++) {
        final newTurns = <int>[];
        newTurns.addAll(turns);
        newTurns.add(1); // R
        for (var i = turns.length - 1; i >= 0; i--) {
          newTurns.add(1 - turns[i]); // flip
        }
        turns = newTurns;
      }

      // Convert turns to points
      const dirs = [(0.0, -1.0), (1.0, 0.0), (0.0, 1.0), (-1.0, 0.0)]; // up, right, down, left
      var dir = 1; // start facing right
      var x = 0.0, y = 0.0;
      final rawPoints = [(x, y)];

      for (final turn in turns) {
        dir = turn == 1 ? (dir + 1) % 4 : (dir + 3) % 4;
        x += dirs[dir].$1;
        y += dirs[dir].$2;
        rawPoints.add((x, y));
      }

      // Normalize to 0..1
      var minX = rawPoints[0].$1, maxX = rawPoints[0].$1;
      var minY = rawPoints[0].$2, maxY = rawPoints[0].$2;
      for (final (px, py) in rawPoints) {
        if (px < minX) minX = px; if (px > maxX) maxX = px;
        if (py < minY) minY = py; if (py > maxY) maxY = py;
      }
      final rangeX = maxX - minX; final rangeY = maxY - minY;
      final range = max(rangeX, rangeY);

      final points = rawPoints.map((p) => (
        0.05 + 0.9 * (p.$1 - minX) / (range > 0 ? range : 1),
        0.05 + 0.9 * (p.$2 - minY) / (range > 0 ? range : 1),
      )).toList();

      states.add(DragonCurveState(
        points: points, depth: depth,
        description: 'Depth $depth: ${rawPoints.length} points',
      ));
    }

    return states;
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) =>
      _DragonPainter(state: state as DragonCurveState, brightness: Theme.of(context).brightness);

  @override
  Widget? buildControls({required VoidCallback onChanged}) =>
      _Ctrl(depth: _maxDepth, onChanged: (v) { _maxDepth = v; onChanged(); });
}

class _DragonPainter extends CustomPainter {
  _DragonPainter({required this.state, required this.brightness});
  final DragonCurveState state;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    if (state.points.length < 2) return;
    final isDark = brightness == Brightness.dark;
    final color = isDark ? const Color(0xFF4CAF50) : const Color(0xFF388E3C);

    final path = Path();
    path.moveTo(state.points[0].$1 * size.width, state.points[0].$2 * size.height);
    for (var i = 1; i < state.points.length; i++) {
      path.lineTo(state.points[i].$1 * size.width, state.points[i].$2 * size.height);
    }
    canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.5);
  }

  @override bool shouldRepaint(covariant _DragonPainter old) => old.state != state;
}

class _Ctrl extends StatefulWidget {
  const _Ctrl({required this.depth, required this.onChanged});
  final int depth; final ValueChanged<int> onChanged;
  @override State<_Ctrl> createState() => _CtrlState();
}
class _CtrlState extends State<_Ctrl> {
  late double _v;
  @override void initState() { super.initState(); _v = widget.depth.toDouble(); }
  @override Widget build(BuildContext context) => Row(children: [
    Text('Depth: ${_v.round()}', style: Theme.of(context).textTheme.bodySmall),
    Expanded(child: Slider(value: _v, min: 0, max: 18, divisions: 18,
      onChanged: (v) => setState(() => _v = v), onChangeEnd: (v) => widget.onChanged(v.round()))),
  ]);
}
