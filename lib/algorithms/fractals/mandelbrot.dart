import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';

class MandelbrotState extends AlgorithmState {
  const MandelbrotState({
    required this.pixels,
    required this.width,
    required this.height,
    required this.maxIter,
    required this.currentIter,
    required super.description,
  });

  final List<int> pixels; // iteration count per pixel
  final int width;
  final int height;
  final int maxIter;
  final int currentIter;
}

class MandelbrotAlgorithm extends Algorithm {
  int _maxIter = 50;
  int _resolution = 120;

  @override
  String get name => 'Mandelbrot Set';
  @override
  String get description => 'Iterate z = z² + c and color by escape time. Infinite complexity at every scale.';
  @override
  AlgorithmCategory get category => AlgorithmCategory.fractals;

  @override
  Future<List<AlgorithmState>> generate() async {
    final w = _resolution;
    final h = (_resolution * 3 ~/ 4).clamp(30, 300);
    final maxIter = _maxIter;
    final states = <MandelbrotState>[];

    // Progressive refinement: show at increasing max iterations
    for (var iter = 5; iter <= maxIter; iter += (iter < 20 ? 5 : 10)) {
      final pixels = List<int>.filled(w * h, 0);

      for (var py = 0; py < h; py++) {
        for (var px = 0; px < w; px++) {
          final x0 = -2.5 + 3.5 * px / w;
          final y0 = -1.25 + 2.5 * py / h;
          var x = 0.0, y = 0.0;
          var i = 0;
          while (x * x + y * y <= 4 && i < iter) {
            final xTemp = x * x - y * y + x0;
            y = 2 * x * y + y0;
            x = xTemp;
            i++;
          }
          pixels[py * w + px] = i;
        }
      }

      states.add(MandelbrotState(
        pixels: pixels, width: w, height: h, maxIter: iter, currentIter: iter,
        description: 'Max iterations: $iter',
      ));
    }

    // Final full resolution
    if (states.isEmpty || states.last.maxIter != maxIter) {
      final pixels = List<int>.filled(w * h, 0);
      for (var py = 0; py < h; py++) {
        for (var px = 0; px < w; px++) {
          final x0 = -2.5 + 3.5 * px / w;
          final y0 = -1.25 + 2.5 * py / h;
          var x = 0.0, y = 0.0;
          var i = 0;
          while (x * x + y * y <= 4 && i < maxIter) {
            final xTemp = x * x - y * y + x0;
            y = 2 * x * y + y0;
            x = xTemp;
            i++;
          }
          pixels[py * w + px] = i;
        }
      }
      states.add(MandelbrotState(
        pixels: pixels, width: w, height: h, maxIter: maxIter, currentIter: maxIter,
        description: 'Mandelbrot Set — $maxIter iterations',
      ));
    }

    return states;
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) =>
      _MandelbrotPainter(state: state as MandelbrotState, brightness: Theme.of(context).brightness);

  @override
  Widget? buildControls({required VoidCallback onChanged}) =>
      _Ctrl(maxIter: _maxIter, resolution: _resolution, onChanged: (i, r) { _maxIter = i; _resolution = r; onChanged(); });
}

class _MandelbrotPainter extends CustomPainter {
  _MandelbrotPainter({required this.state, required this.brightness});
  final MandelbrotState state;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / state.width;
    final cellH = size.height / state.height;

    for (var py = 0; py < state.height; py++) {
      for (var px = 0; px < state.width; px++) {
        final iter = state.pixels[py * state.width + px];
        final color = iter >= state.maxIter
            ? Colors.black
            : _iterColor(iter, state.maxIter);
        canvas.drawRect(
          Rect.fromLTWH(px * cellW, py * cellH, cellW + 0.5, cellH + 0.5),
          Paint()..color = color,
        );
      }
    }
  }

  Color _iterColor(int iter, int maxIter) {
    final t = iter / maxIter;
    // Smooth HSV coloring
    final hue = (t * 360 * 3) % 360;
    return HSVColor.fromAHSV(1, hue, 0.85, 0.95).toColor();
  }

  @override
  bool shouldRepaint(covariant _MandelbrotPainter old) => old.state != state;
}

class _Ctrl extends StatefulWidget {
  const _Ctrl({required this.maxIter, required this.resolution, required this.onChanged});
  final int maxIter, resolution;
  final void Function(int, int) onChanged;
  @override State<_Ctrl> createState() => _CtrlState();
}
class _CtrlState extends State<_Ctrl> {
  late double _iter, _res;
  @override void initState() { super.initState(); _iter = widget.maxIter.toDouble(); _res = widget.resolution.toDouble(); }
  @override Widget build(BuildContext context) {
    final ts = Theme.of(context).textTheme.bodySmall;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Row(children: [
        Text('Iterations: ${_iter.round()}', style: ts),
        Expanded(child: Slider(value: _iter, min: 20, max: 200, divisions: 18,
          onChanged: (v) => setState(() => _iter = v), onChangeEnd: (v) => widget.onChanged(v.round(), _res.round()))),
      ]),
      Row(children: [
        Text('Resolution: ${_res.round()}', style: ts),
        Expanded(child: Slider(value: _res, min: 60, max: 300, divisions: 24,
          onChanged: (v) => setState(() => _res = v), onChangeEnd: (v) => widget.onChanged(_iter.round(), v.round()))),
      ]),
    ]);
  }
}
