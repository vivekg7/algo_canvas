import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';

class SierpinskiState extends AlgorithmState {
  const SierpinskiState({
    required this.triangles,
    required this.depth,
    required super.description,
  });

  /// List of triangles: each is ((x1,y1), (x2,y2), (x3,y3)) normalized 0..1.
  final List<((double, double), (double, double), (double, double))> triangles;
  final int depth;
}

class SierpinskiAlgorithm extends Algorithm {
  int _maxDepth = 6;

  @override
  String get name => 'Sierpinski Triangle';
  @override
  String get description => 'Recursively remove center triangle at each level. Self-similar fractal.';
  @override
  AlgorithmCategory get category => AlgorithmCategory.fractals;

  @override
  Future<List<AlgorithmState>> generate() async {
    final states = <SierpinskiState>[];

    for (var depth = 0; depth <= _maxDepth; depth++) {
      final triangles = <((double, double), (double, double), (double, double))>[];
      _generate(triangles, (0.5, 0.02), (0.02, 0.98), (0.98, 0.98), depth);
      states.add(SierpinskiState(
        triangles: triangles, depth: depth,
        description: 'Depth $depth: ${triangles.length} triangles',
      ));
    }

    return states;
  }

  void _generate(
    List<((double, double), (double, double), (double, double))> out,
    (double, double) a, (double, double) b, (double, double) c, int depth,
  ) {
    if (depth == 0) {
      out.add((a, b, c));
      return;
    }
    final ab = ((a.$1 + b.$1) / 2, (a.$2 + b.$2) / 2);
    final bc = ((b.$1 + c.$1) / 2, (b.$2 + c.$2) / 2);
    final ca = ((c.$1 + a.$1) / 2, (c.$2 + a.$2) / 2);
    _generate(out, a, ab, ca, depth - 1);
    _generate(out, ab, b, bc, depth - 1);
    _generate(out, ca, bc, c, depth - 1);
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) =>
      _SierpinskiPainter(state: state as SierpinskiState, brightness: Theme.of(context).brightness);

  @override
  Widget? buildControls({required VoidCallback onChanged}) =>
      _Ctrl(depth: _maxDepth, onChanged: (v) { _maxDepth = v; onChanged(); });
}

class _SierpinskiPainter extends CustomPainter {
  _SierpinskiPainter({required this.state, required this.brightness});
  final SierpinskiState state;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final isDark = brightness == Brightness.dark;
    final color = isDark ? const Color(0xFF42A5F5) : const Color(0xFF1976D2);

    for (final (a, b, c) in state.triangles) {
      final path = Path()
        ..moveTo(a.$1 * size.width, a.$2 * size.height)
        ..lineTo(b.$1 * size.width, b.$2 * size.height)
        ..lineTo(c.$1 * size.width, c.$2 * size.height)
        ..close();
      canvas.drawPath(path, Paint()..color = color);
    }
  }

  @override bool shouldRepaint(covariant _SierpinskiPainter old) => old.state != state;
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
    Expanded(child: Slider(value: _v, min: 0, max: 10, divisions: 10,
      onChanged: (v) => setState(() => _v = v), onChangeEnd: (v) => widget.onChanged(v.round()))),
  ]);
}
