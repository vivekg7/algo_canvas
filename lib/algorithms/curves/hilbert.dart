import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';

class CurveState extends AlgorithmState {
  const CurveState({required this.points, required this.depth, required super.description});
  final List<(double, double)> points;
  final int depth;
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
      final n = 1 << depth; // 2^depth
      final points = <(double, double)>[];

      for (var d = 0; d < n * n; d++) {
        final (x, y) = _d2xy(n, d);
        points.add((
          0.05 + 0.9 * x / (n - 1),
          0.05 + 0.9 * y / (n - 1),
        ));
      }

      states.add(CurveState(
        points: points, depth: depth,
        description: 'Order $depth: $n×$n grid, ${points.length} points',
      ));
    }

    return states;
  }

  /// Convert Hilbert distance d to (x, y) in n×n grid.
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
      _CurvePainter(state: state as CurveState, brightness: Theme.of(context).brightness, color: null);

  @override
  Widget? buildControls({required VoidCallback onChanged}) =>
      _Ctrl(depth: _maxDepth, max: 9, onChanged: (v) { _maxDepth = v; onChanged(); });
}

class _CurvePainter extends CustomPainter {
  _CurvePainter({required this.state, required this.brightness, this.color});
  final CurveState state;
  final Brightness brightness;
  final Color? color;

  @override
  void paint(Canvas canvas, Size size) {
    if (state.points.length < 2) return;
    final isDark = brightness == Brightness.dark;
    final lineColor = color ?? (isDark ? const Color(0xFF42A5F5) : const Color(0xFF1976D2));

    final path = Path();
    path.moveTo(state.points[0].$1 * size.width, state.points[0].$2 * size.height);
    for (var i = 1; i < state.points.length; i++) {
      path.lineTo(state.points[i].$1 * size.width, state.points[i].$2 * size.height);
    }

    canvas.drawPath(path, Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = state.points.length > 1000 ? 0.8 : 1.5
      ..strokeJoin = StrokeJoin.round);

    // Draw dots at points if not too many
    if (state.points.length <= 256) {
      for (final (x, y) in state.points) {
        canvas.drawCircle(
          Offset(x * size.width, y * size.height), 2,
          Paint()..color = lineColor,
        );
      }
    }
  }

  @override bool shouldRepaint(covariant _CurvePainter old) => old.state != state;
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
