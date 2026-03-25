import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';

class SierpinskiState extends AlgorithmState {
  SierpinskiState({required this.vertices, required this.depth, required super.description});

  /// Flat vertex data: [ax, ay, bx, by, cx, cy, ax, ay, bx, by, cx, cy, ...]
  /// Each triangle = 6 consecutive floats.
  final Float32List vertices;
  final int depth;
  int get triangleCount => vertices.length ~/ 6;

  Path? _cachedPath;
  Size? _cachedSize;

  Path getPath(Size size) {
    if (_cachedPath != null && _cachedSize == size) return _cachedPath!;
    final path = Path();
    for (var i = 0; i < vertices.length; i += 6) {
      path.moveTo(vertices[i] * size.width, vertices[i + 1] * size.height);
      path.lineTo(vertices[i + 2] * size.width, vertices[i + 3] * size.height);
      path.lineTo(vertices[i + 4] * size.width, vertices[i + 5] * size.height);
      path.close();
    }
    _cachedPath = path;
    _cachedSize = size;
    return path;
  }
}

class SierpinskiAlgorithm extends Algorithm {
  int _maxDepth = 6;

  @override String get name => 'Sierpinski Triangle';
  @override String get description => 'Recursively remove center triangle at each level. Self-similar fractal.';
  @override AlgorithmCategory get category => AlgorithmCategory.fractals;

  @override
  Future<List<AlgorithmState>> generate() async {
    final states = <SierpinskiState>[];

    for (var depth = 0; depth <= _maxDepth; depth++) {
      final raw = <double>[];
      _generate(raw, 0.5, 0.02, 0.02, 0.98, 0.98, 0.98, depth);
      states.add(SierpinskiState(
        vertices: Float32List.fromList(raw), depth: depth,
        description: 'Depth $depth: ${raw.length ~/ 6} triangles',
      ));
    }

    return states;
  }

  void _generate(List<double> out,
      double ax, double ay, double bx, double by, double cx, double cy, int depth) {
    if (depth == 0) {
      out.addAll([ax, ay, bx, by, cx, cy]);
      return;
    }
    final abx = (ax + bx) / 2, aby = (ay + by) / 2;
    final bcx = (bx + cx) / 2, bcy = (by + cy) / 2;
    final cax = (cx + ax) / 2, cay = (cy + ay) / 2;
    _generate(out, ax, ay, abx, aby, cax, cay, depth - 1);
    _generate(out, abx, aby, bx, by, bcx, bcy, depth - 1);
    _generate(out, cax, cay, bcx, bcy, cx, cy, depth - 1);
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
    canvas.drawPath(state.getPath(size), Paint()..color = color);
  }

  @override bool shouldRepaint(covariant _SierpinskiPainter old) => !identical(old.state, state);
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
