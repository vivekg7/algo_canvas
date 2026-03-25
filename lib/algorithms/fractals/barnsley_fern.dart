import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';

class BarnsleyFernState extends AlgorithmState {
  BarnsleyFernState({
    required this.points,
    required this.count,
    required this.lastX,
    required this.lastY,
    required super.description,
  });

  /// Interleaved normalized x,y. Pre-allocated to max size.
  final Float32List points;
  final int count; // valid point count (points may be larger)
  final double lastX; // raw x for continuing IFS
  final double lastY; // raw y for continuing IFS
}

class BarnsleyFernAlgorithm extends Algorithm {
  int _totalPoints = 20000;

  @override String get name => 'Barnsley Fern';
  @override String get description => 'Iterated Function System: 4 affine transforms with probabilities create a fern.';
  @override AlgorithmCategory get category => AlgorithmCategory.fractals;
  @override AlgorithmMode get mode => AlgorithmMode.live;

  @override
  AlgorithmState createInitialState() {
    return BarnsleyFernState(
      points: Float32List(_totalPoints * 2),
      count: 0, lastX: 0, lastY: 0,
      description: 'Barnsley Fern',
    );
  }

  @override
  AlgorithmState? tick(AlgorithmState current) {
    final s = current as BarnsleyFernState;
    if (s.count >= _totalPoints) return null;

    final random = Random();

    // Copy buffer (fast memcpy for typed arrays)
    final newPts = Float32List(s.points.length);
    newPts.setRange(0, s.count * 2, s.points);

    var x = s.lastX, y = s.lastY;
    final batch = min(200, _totalPoints - s.count);
    var offset = s.count * 2;

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
      newPts[offset++] = (x + 2.75) / 5.5;
      newPts[offset++] = 1.0 - y / 10.0;
    }

    final count = s.count + batch;
    return BarnsleyFernState(
      points: newPts, count: count,
      lastX: x, lastY: y,
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
    if (state.count == 0) return;
    final isDark = brightness == Brightness.dark;
    final color = isDark ? const Color(0xFF4CAF50) : const Color(0xFF2E7D32);

    // Scale points to canvas size
    final scaled = Float32List(state.count * 2);
    for (var i = 0; i < state.count * 2; i += 2) {
      scaled[i] = state.points[i] * size.width;
      scaled[i + 1] = state.points[i + 1] * size.height;
    }

    canvas.drawRawPoints(
      ui.PointMode.points,
      scaled,
      Paint()
        ..color = color
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.square,
    );
  }

  @override bool shouldRepaint(covariant _FernPainter old) => !identical(old.state, state);
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
