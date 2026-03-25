import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';

class KochState extends AlgorithmState {
  const KochState({
    required this.points,
    required this.depth,
    required super.description,
  });

  final List<(double, double)> points; // normalized 0..1
  final int depth;
}

class KochSnowflakeAlgorithm extends Algorithm {
  int _maxDepth = 5;

  @override
  String get name => 'Koch Snowflake';
  @override
  String get description => 'Replace each edge with a triangular bump. Infinite perimeter, finite area.';
  @override
  AlgorithmCategory get category => AlgorithmCategory.fractals;

  @override
  Future<List<AlgorithmState>> generate() async {
    final states = <KochState>[];

    // Initial equilateral triangle
    const cx = 0.5, cy = 0.55;
    const r = 0.4;
    final p1 = (cx, cy - r);
    final p2 = (cx - r * sin(pi / 3), cy + r * cos(pi / 3));
    final p3 = (cx + r * sin(pi / 3), cy + r * cos(pi / 3));
    var points = [p1, p2, p3, p1]; // closed

    states.add(KochState(points: List.of(points), depth: 0, description: 'Depth 0: triangle'));

    for (var depth = 1; depth <= _maxDepth; depth++) {
      final newPoints = <(double, double)>[];
      for (var i = 0; i < points.length - 1; i++) {
        final (ax, ay) = points[i];
        final (bx, by) = points[i + 1];
        final dx = bx - ax, dy = by - ay;

        final p1 = (ax, ay);
        final p2 = (ax + dx / 3, ay + dy / 3);
        // Peak: rotate 60 degrees
        final peakX = ax + dx / 2 - dy * sin(pi / 3) / 3;
        final peakY = ay + dy / 2 + dx * sin(pi / 3) / 3;
        final p3 = (peakX, peakY);
        final p4 = (ax + 2 * dx / 3, ay + 2 * dy / 3);

        newPoints.addAll([p1, p2, p3, p4]);
      }
      newPoints.add(points.last);
      points = newPoints;

      states.add(KochState(
        points: List.of(points), depth: depth,
        description: 'Depth $depth: ${points.length - 1} segments',
      ));
    }

    return states;
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) =>
      _KochPainter(state: state as KochState, brightness: Theme.of(context).brightness);

  @override
  Widget? buildControls({required VoidCallback onChanged}) =>
      _Ctrl(depth: _maxDepth, onChanged: (v) { _maxDepth = v; onChanged(); });
}

class _KochPainter extends CustomPainter {
  _KochPainter({required this.state, required this.brightness});
  final KochState state;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    if (state.points.length < 2) return;
    final isDark = brightness == Brightness.dark;
    final color = isDark ? const Color(0xFF42A5F5) : const Color(0xFF1976D2);
    final fill = color.withValues(alpha: 0.15);

    final path = Path();
    path.moveTo(state.points[0].$1 * size.width, state.points[0].$2 * size.height);
    for (var i = 1; i < state.points.length; i++) {
      path.lineTo(state.points[i].$1 * size.width, state.points[i].$2 * size.height);
    }

    canvas.drawPath(path, Paint()..color = fill..style = PaintingStyle.fill);
    canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.5);
  }

  @override bool shouldRepaint(covariant _KochPainter old) => old.state != state;
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
    Expanded(child: Slider(value: _v, min: 0, max: 7, divisions: 7,
      onChanged: (v) => setState(() => _v = v), onChangeEnd: (v) => widget.onChanged(v.round()))),
  ]);
}
