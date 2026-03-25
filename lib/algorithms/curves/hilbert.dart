import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';

class CurveState extends AlgorithmState {
  CurveState({required this.points, required this.depth, required super.description});

  /// Interleaved x,y pairs as Float32List. Length = pointCount * 2.
  final Float32List points;
  final int depth;
  int get pointCount => points.length ~/ 2;

  // Path cache
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

class HilbertCurveAlgorithm extends Algorithm {
  int _maxDepth = 5;

  @override String get name => 'Hilbert Curve';
  @override String get description => 'Space-filling curve visiting every cell in a grid. Used in spatial indexing.';
  @override AlgorithmCategory get category => AlgorithmCategory.spaceFillingCurves;

  @override
  Future<List<AlgorithmState>> generate() async {
    final states = <CurveState>[];

    for (var depth = 1; depth <= _maxDepth; depth++) {
      final n = 1 << depth;
      final count = n * n;
      final pts = Float32List(count * 2);

      for (var d = 0; d < count; d++) {
        final (x, y) = _d2xy(n, d);
        pts[d * 2] = 0.05 + 0.9 * x / (n - 1);
        pts[d * 2 + 1] = 0.05 + 0.9 * y / (n - 1);
      }

      states.add(CurveState(
        points: pts, depth: depth,
        description: 'Order $depth: $n×$n grid, $count points',
      ));
    }

    return states;
  }

  (int, int) _d2xy(int n, int d) {
    var x = 0, y = 0;
    var s = 1;
    while (s < n) {
      final rx = 1 & (d ~/ 2);
      final ry = 1 & (d ^ rx);
      if (ry == 0) {
        if (rx == 1) { x = s - 1 - x; y = s - 1 - y; }
        final temp = x; x = y; y = temp;
      }
      x += s * rx;
      y += s * ry;
      d ~/= 4;
      s *= 2;
    }
    return (x, y);
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) =>
      CurvePainter(state: state as CurveState, brightness: Theme.of(context).brightness);

  @override
  Widget? buildControls({required VoidCallback onChanged}) =>
      _Ctrl(depth: _maxDepth, max: 9, onChanged: (v) { _maxDepth = v; onChanged(); });
}

/// Shared painter for all curve algorithms.
class CurvePainter extends CustomPainter {
  CurvePainter({required this.state, required this.brightness, this.color});
  final CurveState state;
  final Brightness brightness;
  final Color? color;

  @override
  void paint(Canvas canvas, Size size) {
    if (state.pointCount < 2) return;
    final isDark = brightness == Brightness.dark;
    final lineColor = color ?? (isDark ? const Color(0xFF42A5F5) : const Color(0xFF1976D2));

    canvas.drawPath(state.getPath(size), Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = state.pointCount > 1000 ? 0.8 : 1.5
      ..strokeJoin = StrokeJoin.round);

    if (state.pointCount <= 256) {
      final pts = state.points;
      final dotPaint = Paint()..color = lineColor;
      for (var i = 0; i < pts.length; i += 2) {
        canvas.drawCircle(Offset(pts[i] * size.width, pts[i + 1] * size.height), 2, dotPaint);
      }
    }
  }

  @override bool shouldRepaint(covariant CurvePainter old) => !identical(old.state, state);
}

class _Ctrl extends StatefulWidget {
  const _Ctrl({required this.depth, required this.max, required this.onChanged});
  final int depth, max; final ValueChanged<int> onChanged;
  @override State<_Ctrl> createState() => _CtrlState();
}
class _CtrlState extends State<_Ctrl> {
  late double _v;
  @override void initState() { super.initState(); _v = widget.depth.toDouble(); }
  @override Widget build(BuildContext context) => Row(children: [
    Text('Order: ${_v.round()}', style: Theme.of(context).textTheme.bodySmall),
    Expanded(child: Slider(value: _v, min: 1, max: widget.max.toDouble(), divisions: widget.max - 1,
      onChanged: (v) => setState(() => _v = v), onChangeEnd: (v) => widget.onChanged(v.round()))),
  ]);
}
