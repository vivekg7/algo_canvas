import 'dart:typed_data';
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
      final count = n * n;
      final pts = Float32List(count * 2);

      for (var d = 0; d < count; d++) {
        final (x, y) = _decode(d);
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
    return CurvePainter(
      state: state as CurveState,
      brightness: Theme.of(context).brightness,
      color: isDark ? const Color(0xFFFFCA28) : const Color(0xFFF9A825),
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
    Expanded(child: Slider(value: _v, min: 1, max: 8, divisions: 7,
      onChanged: (v) => setState(() => _v = v), onChangeEnd: (v) => widget.onChanged(v.round()))),
  ]);
}
