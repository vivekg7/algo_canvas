import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';

class DragonCurveState extends AlgorithmState {
  DragonCurveState({required this.points, required this.depth, required super.description});
  final Float32List points; // interleaved x,y
  final int depth;
  int get pointCount => points.length ~/ 2;

  Path? _cachedPath;
  Size? _cachedSize;

  Path getPath(Size size) {
    if (_cachedPath != null && _cachedSize == size) return _cachedPath!;
    final path = Path();
    if (points.length < 4) return path;
    path.moveTo(points[0] * size.width, points[1] * size.height);
    for (var i = 2; i < points.length; i += 2) {
      path.lineTo(points[i] * size.width, points[i + 1] * size.height);
    }
    _cachedPath = path;
    _cachedSize = size;
    return path;
  }
}

class DragonCurveAlgorithm extends Algorithm {
  int _maxDepth = 12;

  @override String get name => 'Dragon Curve';
  @override String get description => 'Paper-folding fractal: fold right, unfold, repeat.';
  @override AlgorithmCategory get category => AlgorithmCategory.fractals;

  @override
  Future<List<AlgorithmState>> generate() async {
    final states = <DragonCurveState>[];
    const dirX = [0.0, 1.0, 0.0, -1.0];
    const dirY = [-1.0, 0.0, 1.0, 0.0];

    for (var depth = 0; depth <= _maxDepth; depth++) {
      var turns = <int>[];
      for (var d = 0; d < depth; d++) {
        final newTurns = <int>[];
        newTurns.addAll(turns);
        newTurns.add(1);
        for (var i = turns.length - 1; i >= 0; i--) {
          newTurns.add(1 - turns[i]);
        }
        turns = newTurns;
      }

      var dir = 1;
      var x = 0.0, y = 0.0;
      final raw = <double>[x, y];

      for (final turn in turns) {
        dir = turn == 1 ? (dir + 1) % 4 : (dir + 3) % 4;
        x += dirX[dir];
        y += dirY[dir];
        raw.addAll([x, y]);
      }

      // Normalize
      var minX = raw[0], maxX = raw[0], minY = raw[1], maxY = raw[1];
      for (var i = 0; i < raw.length; i += 2) {
        if (raw[i] < minX) { minX = raw[i]; }
        if (raw[i] > maxX) { maxX = raw[i]; }
        if (raw[i + 1] < minY) { minY = raw[i + 1]; }
        if (raw[i + 1] > maxY) { maxY = raw[i + 1]; }
      }
      final range = max(maxX - minX, maxY - minY);
      final r = range > 0 ? range : 1.0;

      final pts = Float32List(raw.length);
      for (var i = 0; i < raw.length; i += 2) {
        pts[i] = 0.05 + 0.9 * (raw[i] - minX) / r;
        pts[i + 1] = 0.05 + 0.9 * (raw[i + 1] - minY) / r;
      }

      states.add(DragonCurveState(
        points: pts, depth: depth,
        description: 'Depth $depth: ${pts.length ~/ 2} points',
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
    if (state.pointCount < 2) return;
    final isDark = brightness == Brightness.dark;
    final color = isDark ? const Color(0xFF4CAF50) : const Color(0xFF388E3C);
    canvas.drawPath(state.getPath(size), Paint()
      ..color = color..style = PaintingStyle.stroke..strokeWidth = 1.5);
  }

  @override bool shouldRepaint(covariant _DragonPainter old) => !identical(old.state, state);
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
