import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';
import 'package:algo_canvas/algorithms/curves/hilbert.dart';

class PeanoCurveAlgorithm extends Algorithm {
  int _maxDepth = 3;

  @override String get name => 'Peano Curve';
  @override String get description => 'The original space-filling curve (1890). 3-ary recursive, visits every cell in a 3ⁿ grid.';
  @override AlgorithmCategory get category => AlgorithmCategory.spaceFillingCurves;

  @override
  Future<List<AlgorithmState>> generate() async {
    final states = <CurveState>[];

    for (var depth = 1; depth <= _maxDepth; depth++) {
      final n = _pow3(depth);
      final points = <(double, double)>[];

      // Generate Peano curve by visiting grid cells in order
      _peanoWalk(points, 0, 0, n, n, false, false);

      // Normalize to 0.05..0.95
      final normalized = points.map((p) => (
        0.05 + 0.9 * p.$1 / (n - 1),
        0.05 + 0.9 * p.$2 / (n - 1),
      )).toList();

      states.add(CurveState(
        points: normalized, depth: depth,
        description: 'Order $depth: $n×$n grid, ${normalized.length} points',
      ));
    }

    return states;
  }

  int _pow3(int n) {
    var r = 1;
    for (var i = 0; i < n; i++) { r *= 3; }
    return r;
  }

  /// Recursive Peano curve walk on a sub-grid.
  /// Visits all cells in the rectangle [x, x+w) × [y, y+h).
  /// flipX/flipY control the traversal direction.
  void _peanoWalk(List<(double, double)> points,
      int x, int y, int w, int h, bool flipX, bool flipY) {
    if (w == 1 && h == 1) {
      points.add((x.toDouble(), y.toDouble()));
      return;
    }

    final sw = w ~/ 3;
    final sh = h ~/ 3;

    // 9 sub-squares visited in Peano order
    // The order snakes: column by column, alternating direction
    for (var col = 0; col < 3; col++) {
      final actualCol = flipX ? (2 - col) : col;
      final colFlipY = (col % 2 == 1) != flipY;

      for (var row = 0; row < 3; row++) {
        final actualRow = colFlipY ? (2 - row) : row;
        final subFlipX = (row % 2 == 1) != flipX;

        _peanoWalk(
          points,
          x + actualCol * sw,
          y + actualRow * sh,
          sw, sh,
          subFlipX,
          colFlipY,
        );
      }
    }
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _CurvePainterGeneric(
      state: state as CurveState,
      brightness: Theme.of(context).brightness,
      color: isDark ? const Color(0xFFEF5350) : const Color(0xFFD32F2F),
    );
  }

  @override
  Widget? buildControls({required VoidCallback onChanged}) =>
      _Ctrl(depth: _maxDepth, onChanged: (v) { _maxDepth = v; onChanged(); });
}

class _CurvePainterGeneric extends CustomPainter {
  _CurvePainterGeneric({required this.state, required this.brightness, required this.color});
  final CurveState state;
  final Brightness brightness;
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

    if (state.points.length <= 81) {
      for (final (x, y) in state.points) {
        canvas.drawCircle(Offset(x * size.width, y * size.height), 2, Paint()..color = color);
      }
    }
  }

  @override bool shouldRepaint(covariant _CurvePainterGeneric old) => old.state != state;
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
    Expanded(child: Slider(value: _v, min: 1, max: 5, divisions: 4,
      onChanged: (v) => setState(() => _v = v), onChangeEnd: (v) => widget.onChanged(v.round()))),
  ]);
}
