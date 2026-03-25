import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';

class BarnsleyFernState extends AlgorithmState {
  const BarnsleyFernState({required this.points, required this.count, required super.description});
  final List<(double, double)> points;
  final int count;
}

class BarnsleyFernAlgorithm extends Algorithm {
  int _totalPoints = 20000;

  @override String get name => 'Barnsley Fern';
  @override String get description => 'Iterated Function System: 4 affine transforms with probabilities create a fern.';
  @override AlgorithmCategory get category => AlgorithmCategory.fractals;
  @override AlgorithmMode get mode => AlgorithmMode.live;

  @override
  AlgorithmState createInitialState() => const BarnsleyFernState(points: [], count: 0, description: 'Barnsley Fern');

  @override
  AlgorithmState? tick(AlgorithmState current) {
    final s = current as BarnsleyFernState;
    if (s.count >= _totalPoints) return null;

    final random = Random();
    final newPoints = List<(double, double)>.of(s.points);
    var x = s.points.isEmpty ? 0.0 : s.points.last.$1 * 5.5 - 2.75;
    var y = s.points.isEmpty ? 0.0 : s.points.last.$2 * 10.0;

    // Generate batch of points
    final batch = min(200, _totalPoints - s.count);
    for (var i = 0; i < batch; i++) {
      final r = random.nextDouble();
      double nx, ny;
      if (r < 0.01) {
        nx = 0; ny = 0.16 * y;
      } else if (r < 0.86) {
        nx = 0.85 * x + 0.04 * y;
        ny = -0.04 * x + 0.85 * y + 1.6;
      } else if (r < 0.93) {
        nx = 0.2 * x - 0.26 * y;
        ny = 0.23 * x + 0.22 * y + 1.6;
      } else {
        nx = -0.15 * x + 0.28 * y;
        ny = 0.26 * x + 0.24 * y + 0.44;
      }
      x = nx; y = ny;
      // Normalize: x is roughly -2.75..2.75, y is 0..10
      newPoints.add(((x + 2.75) / 5.5, 1.0 - y / 10.0));
    }

    final count = s.count + batch;
    return BarnsleyFernState(
      points: newPoints, count: count,
      description: '$count points',
    );
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) =>
      _FernPainter(state: state as BarnsleyFernState, brightness: Theme.of(context).brightness);

  @override
  Widget? buildControls({required VoidCallback onChanged}) =>
      _Ctrl(total: _totalPoints, onChanged: (v) { _totalPoints = v; onChanged(); });
}

class _FernPainter extends CustomPainter {
  _FernPainter({required this.state, required this.brightness});
  final BarnsleyFernState state;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final isDark = brightness == Brightness.dark;
    final color = isDark ? const Color(0xFF4CAF50) : const Color(0xFF2E7D32);

    for (final (x, y) in state.points) {
      canvas.drawRect(
        Rect.fromLTWH(x * size.width, y * size.height, 1.5, 1.5),
        Paint()..color = color,
      );
    }
  }

  @override bool shouldRepaint(covariant _FernPainter old) => old.state != state;
}

class _Ctrl extends StatefulWidget {
  const _Ctrl({required this.total, required this.onChanged});
  final int total; final ValueChanged<int> onChanged;
  @override State<_Ctrl> createState() => _CtrlState();
}
class _CtrlState extends State<_Ctrl> {
  late double _v;
  @override void initState() { super.initState(); _v = widget.total.toDouble(); }
  @override Widget build(BuildContext context) => Row(children: [
    Text('Points: ${_v.round()}', style: Theme.of(context).textTheme.bodySmall),
    Expanded(child: Slider(value: _v, min: 5000, max: 50000, divisions: 45,
      onChanged: (v) => setState(() => _v = v), onChangeEnd: (v) => widget.onChanged(v.round()))),
  ]);
}
