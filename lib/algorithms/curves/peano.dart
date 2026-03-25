import 'dart:typed_data';
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
      final rawPoints = <double>[];
      _peanoWalk(rawPoints, 0, 0, n, n, false, false);

      // Normalize to 0.05..0.95
      final pts = Float32List(rawPoints.length);
      for (var i = 0; i < rawPoints.length; i += 2) {
        pts[i] = 0.05 + 0.9 * rawPoints[i] / (n - 1);
        pts[i + 1] = 0.05 + 0.9 * rawPoints[i + 1] / (n - 1);
      }

      states.add(CurveState(
        points: pts, depth: depth,
        description: 'Order $depth: $n×$n grid, ${pts.length ~/ 2} points',
      ));
    }

    return states;
  }

  int _pow3(int n) {
    var r = 1;
    for (var i = 0; i < n; i++) { r *= 3; }
    return r;
  }

  void _peanoWalk(List<double> points,
      int x, int y, int w, int h, bool flipX, bool flipY) {
    if (w == 1 && h == 1) {
      points.add(x.toDouble());
      points.add(y.toDouble());
      return;
    }

    final sw = w ~/ 3;
    final sh = h ~/ 3;

    for (var col = 0; col < 3; col++) {
      final actualCol = flipX ? (2 - col) : col;
      final colFlipY = (col % 2 == 1) != flipY;

      for (var row = 0; row < 3; row++) {
        final actualRow = colFlipY ? (2 - row) : row;
        final subFlipX = (row % 2 == 1) != flipX;

        _peanoWalk(points, x + actualCol * sw, y + actualRow * sh,
            sw, sh, subFlipX, colFlipY);
      }
    }
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CurvePainter(
      state: state as CurveState,
      brightness: Theme.of(context).brightness,
      color: isDark ? const Color(0xFFEF5350) : const Color(0xFFD32F2F),
    );
  }

  @override
  Widget? buildControls({required VoidCallback onChanged}) =>
      _Ctrl(depth: _maxDepth, onChanged: (v) { _maxDepth = v; onChanged(); });
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
    Expanded(child: Slider(value: _v, min: 1, max: 7, divisions: 6,
      onChanged: (v) => setState(() => _v = v), onChangeEnd: (v) => widget.onChanged(v.round()))),
  ]);
}
