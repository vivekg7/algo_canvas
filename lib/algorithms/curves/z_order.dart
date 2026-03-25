import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';
import 'package:algo_canvas/algorithms/curves/hilbert.dart';

class ZOrderCurveAlgorithm extends Algorithm {
  int _maxDepth = 4;

  @override String get name => 'Z-Order (Morton)';
  @override String get description => 'Interleave bits of x,y coordinates. Used in databases and texture mapping.';
  @override AlgorithmCategory get category => AlgorithmCategory.spaceFillingCurves;

  @override
  Future<List<AlgorithmState>> generate() async {
    final states = <CurveState>[];

    for (var depth = 1; depth <= _maxDepth; depth++) {
      final n = 1 << depth;
      final points = <(double, double)>[];

      for (var d = 0; d < n * n; d++) {
        final (x, y) = _decode(d);
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

  /// Decode Morton code to (x, y).
  (int, int) _decode(int z) {
    var x = 0, y = 0;
    for (var i = 0; i < 16; i++) {
      x |= ((z >> (2 * i)) & 1) << i;
      y |= ((z >> (2 * i + 1)) & 1) << i;
    }
    return (x, y);
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _ZPainter(
      state: state as CurveState,
      color: isDark ? const Color(0xFFFFCA28) : const Color(0xFFF9A825),
    );
  }

  @override
  Widget? buildControls({required VoidCallback onChanged}) =>
      _Ctrl(depth: _maxDepth, onChanged: (v) { _maxDepth = v; onChanged(); });
}

class _ZPainter extends CustomPainter {
  _ZPainter({required this.state, required this.color});
  final CurveState state;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (state.points.length < 2) return;
    final path = Path();
    path.moveTo(state.points[0].$1 * size.width, state.points[0].$2 * size.height);
    for (var i = 1; i < state.points.length; i++) {
      path.lineTo(state.points[i].$1 * size.width, state.points[i].$2 * size.height);
    }
    canvas.drawPath(path, Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = state.points.length > 500 ? 0.8 : 1.5
      ..strokeJoin = StrokeJoin.round);

    if (state.points.length <= 256) {
      for (final (x, y) in state.points) {
        canvas.drawCircle(Offset(x * size.width, y * size.height), 2, Paint()..color = color);
      }
    }
  }

  @override bool shouldRepaint(covariant _ZPainter old) => old.state != state;
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
    Text('Order: ${_v.round()}', style: Theme.of(context).textTheme.bodySmall),
    Expanded(child: Slider(value: _v, min: 1, max: 8, divisions: 7,
      onChanged: (v) => setState(() => _v = v), onChangeEnd: (v) => widget.onChanged(v.round()))),
  ]);
}
