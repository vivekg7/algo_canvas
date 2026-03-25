import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';

class KochState extends AlgorithmState {
  KochState({required this.points, required this.depth, required super.description});
  final Float32List points; // interleaved x,y
  final int depth;
  int get pointCount => points.length ~/ 2;

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

class KochSnowflakeAlgorithm extends Algorithm {
  int _maxDepth = 5;

  @override String get name => 'Koch Snowflake';
  @override String get description => 'Replace each edge with a triangular bump. Infinite perimeter, finite area.';
  @override AlgorithmCategory get category => AlgorithmCategory.fractals;

  @override
  Future<List<AlgorithmState>> generate() async {
    final states = <KochState>[];
    const cx = 0.5, cy = 0.55, r = 0.4;
    final sinPi3 = sin(pi / 3);
    final cosPi3 = cos(pi / 3);

    // Work with List<double> during generation, convert to Float32List at each step
    var raw = <double>[cx, cy - r, cx - r * sinPi3, cy + r * cosPi3, cx + r * sinPi3, cy + r * cosPi3, cx, cy - r];

    states.add(KochState(points: Float32List.fromList(raw), depth: 0, description: 'Depth 0: triangle'));

    for (var depth = 1; depth <= _maxDepth; depth++) {
      final segCount = raw.length ~/ 2 - 1;
      final newRaw = <double>[];

      for (var i = 0; i < segCount; i++) {
        final ax = raw[i * 2], ay = raw[i * 2 + 1];
        final bx = raw[i * 2 + 2], by = raw[i * 2 + 3];
        final dx = bx - ax, dy = by - ay;

        newRaw.addAll([
          ax, ay,
          ax + dx / 3, ay + dy / 3,
          ax + dx / 2 - dy * sinPi3 / 3, ay + dy / 2 + dx * sinPi3 / 3,
          ax + 2 * dx / 3, ay + 2 * dy / 3,
        ]);
      }
      newRaw.addAll([raw[raw.length - 2], raw[raw.length - 1]]);
      raw = newRaw;

      states.add(KochState(
        points: Float32List.fromList(raw), depth: depth,
        description: 'Depth $depth: ${raw.length ~/ 2 - 1} segments',
      ));
    }

    return states;
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) =>
      _KochPainter(state: state as KochState, brightness: Theme.of(context).brightness);

  @override
  Widget? buildControls({required VoidCallback onChanged}) =>
      _Ctrl(depth: _maxDepth, onChanged: (v) { _maxDepth = v; onChanged(); });
}

class _KochPainter extends CustomPainter {
  _KochPainter({required this.state, required this.brightness});
  final KochState state;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    if (state.pointCount < 2) return;
    final isDark = brightness == Brightness.dark;
    final color = isDark ? const Color(0xFF42A5F5) : const Color(0xFF1976D2);

    final path = state.getPath(size);
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.15)..style = PaintingStyle.fill);
    canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.5);
  }

  @override bool shouldRepaint(covariant _KochPainter old) => !identical(old.state, state);
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
    Expanded(child: Slider(value: _v, min: 0, max: 9, divisions: 9,
      onChanged: (v) => setState(() => _v = v), onChangeEnd: (v) => widget.onChanged(v.round()))),
  ]);
}
