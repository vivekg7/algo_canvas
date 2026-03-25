import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';

class PythagorasState extends AlgorithmState {
  const PythagorasState({required this.squares, required this.depth, required super.description});
  /// Each square as 4 corners: [(x1,y1), (x2,y2), (x3,y3), (x4,y4)] normalized.
  final List<List<(double, double)>> squares;
  final int depth;
}

class PythagorasTreeAlgorithm extends Algorithm {
  int _maxDepth = 8;

  @override String get name => 'Pythagoras Tree';
  @override String get description => 'Recursive squares forming a fractal tree. Each square spawns two child squares.';
  @override AlgorithmCategory get category => AlgorithmCategory.fractals;

  @override
  Future<List<AlgorithmState>> generate() async {
    final states = <PythagorasState>[];

    for (var depth = 0; depth <= _maxDepth; depth++) {
      final squares = <List<(double, double)>>[];
      // Start with base square
      _generate(squares, (0.4, 0.95), (0.6, 0.95), depth);

      states.add(PythagorasState(
        squares: squares, depth: depth,
        description: 'Depth $depth: ${squares.length} squares',
      ));
    }

    return states;
  }

  void _generate(
    List<List<(double, double)>> out,
    (double, double) bl, (double, double) br, int depth,
  ) {
    final dx = br.$1 - bl.$1;
    final dy = br.$2 - bl.$2;
    final tl = (bl.$1 - dy, bl.$2 + dx);
    final tr = (br.$1 - dy, br.$2 + dx);

    out.add([bl, br, tr, tl]);

    if (depth == 0) return;

    // Peak point (isoceles right triangle on top)
    final midX = (tl.$1 + tr.$1) / 2;
    final midY = (tl.$2 + tr.$2) / 2;
    final peakX = midX - (tr.$2 - tl.$2) / 2;
    final peakY = midY + (tr.$1 - tl.$1) / 2;
    final peak = (peakX, peakY);

    _generate(out, tl, peak, depth - 1);
    _generate(out, peak, tr, depth - 1);
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) =>
      _PythagorasPainter(state: state as PythagorasState, brightness: Theme.of(context).brightness);

  @override
  Widget? buildControls({required VoidCallback onChanged}) =>
      _Ctrl(depth: _maxDepth, onChanged: (v) { _maxDepth = v; onChanged(); });
}

class _PythagorasPainter extends CustomPainter {
  _PythagorasPainter({required this.state, required this.brightness});
  final PythagorasState state;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final isDark = brightness == Brightness.dark;
    final total = state.squares.length;

    for (var i = 0; i < total; i++) {
      final sq = state.squares[i];
      final t = total > 1 ? i / (total - 1) : 0.0;
      final hue = 120 + t * 240; // green → blue → purple
      final color = HSVColor.fromAHSV(0.7, hue % 360, 0.6, isDark ? 0.8 : 0.7).toColor();

      final path = Path();
      path.moveTo(sq[0].$1 * size.width, sq[0].$2 * size.height);
      for (var j = 1; j < 4; j++) {
        path.lineTo(sq[j].$1 * size.width, sq[j].$2 * size.height);
      }
      path.close();

      canvas.drawPath(path, Paint()..color = color);
      canvas.drawPath(path, Paint()
        ..color = isDark ? Colors.white12 : Colors.black12
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5);
    }
  }

  @override bool shouldRepaint(covariant _PythagorasPainter old) => old.state != state;
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
    Expanded(child: Slider(value: _v, min: 0, max: 12, divisions: 12,
      onChanged: (v) => setState(() => _v = v), onChangeEnd: (v) => widget.onChanged(v.round()))),
  ]);
}
