import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';
import 'package:algo_canvas/algorithms/fractals/mandelbrot.dart';

class JuliaAlgorithm extends Algorithm {
  int _maxIter = 50;
  int _resolution = 120;
  double _cx = -0.7;
  double _cy = 0.27015;

  @override
  String get name => 'Julia Set';
  @override
  String get description => 'Fixed c parameter variant of Mandelbrot. Each c gives a unique fractal.';
  @override
  AlgorithmCategory get category => AlgorithmCategory.fractals;

  @override
  Future<List<AlgorithmState>> generate() async {
    final w = _resolution;
    final h = (_resolution * 3 ~/ 4).clamp(30, 300);
    final maxIter = _maxIter;
    final cx = _cx, cy = _cy;
    final states = <MandelbrotState>[];

    for (var iter = 5; iter <= maxIter; iter += (iter < 20 ? 5 : 10)) {
      final pixels = List<int>.filled(w * h, 0);
      for (var py = 0; py < h; py++) {
        for (var px = 0; px < w; px++) {
          var x = -2.0 + 4.0 * px / w;
          var y = -1.5 + 3.0 * py / h;
          var i = 0;
          while (x * x + y * y <= 4 && i < iter) {
            final xTemp = x * x - y * y + cx;
            y = 2 * x * y + cy;
            x = xTemp;
            i++;
          }
          pixels[py * w + px] = i;
        }
      }
      states.add(MandelbrotState(
        pixels: pixels, width: w, height: h, maxIter: iter, currentIter: iter,
        description: 'Julia Set (c = $cx + ${cy}i) — $iter iterations',
      ));
    }

    return states;
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) =>
      _JuliaPainter(state: state as MandelbrotState, brightness: Theme.of(context).brightness);

  @override
  Widget? buildControls({required VoidCallback onChanged}) =>
      _Ctrl(maxIter: _maxIter, resolution: _resolution, cx: _cx, cy: _cy,
        onChanged: (i, r, cx, cy) { _maxIter = i; _resolution = r; _cx = cx; _cy = cy; onChanged(); });
}

class _JuliaPainter extends CustomPainter {
  _JuliaPainter({required this.state, required this.brightness});
  final MandelbrotState state;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = size.width / state.width;
    final cellH = size.height / state.height;
    for (var py = 0; py < state.height; py++) {
      for (var px = 0; px < state.width; px++) {
        final iter = state.pixels[py * state.width + px];
        final color = iter >= state.maxIter ? Colors.black
            : HSVColor.fromAHSV(1, (iter / state.maxIter * 360 * 3) % 360, 0.85, 0.95).toColor();
        canvas.drawRect(Rect.fromLTWH(px * cellW, py * cellH, cellW + 0.5, cellH + 0.5), Paint()..color = color);
      }
    }
  }
  @override bool shouldRepaint(covariant _JuliaPainter old) => old.state != state;
}

class _Ctrl extends StatefulWidget {
  const _Ctrl({required this.maxIter, required this.resolution, required this.cx, required this.cy, required this.onChanged});
  final int maxIter, resolution; final double cx, cy;
  final void Function(int, int, double, double) onChanged;
  @override State<_Ctrl> createState() => _CtrlState();
}
class _CtrlState extends State<_Ctrl> {
  late double _iter, _res, _cx, _cy;
  @override void initState() { super.initState(); _iter = widget.maxIter.toDouble(); _res = widget.resolution.toDouble(); _cx = widget.cx; _cy = widget.cy; }
  void _emit() => widget.onChanged(_iter.round(), _res.round(), _cx, _cy);
  @override Widget build(BuildContext context) {
    final ts = Theme.of(context).textTheme.bodySmall;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Row(children: [
        Text('c real: ${_cx.toStringAsFixed(2)}', style: ts),
        Expanded(child: Slider(value: _cx, min: -1.5, max: 1.5, divisions: 60,
          onChanged: (v) => setState(() => _cx = v), onChangeEnd: (_) => _emit())),
        Text('c imag: ${_cy.toStringAsFixed(2)}', style: ts),
        Expanded(child: Slider(value: _cy, min: -1.5, max: 1.5, divisions: 60,
          onChanged: (v) => setState(() => _cy = v), onChangeEnd: (_) => _emit())),
      ]),
      Row(children: [
        Text('Iter: ${_iter.round()}', style: ts),
        Expanded(child: Slider(value: _iter, min: 20, max: 200, divisions: 18,
          onChanged: (v) => setState(() => _iter = v), onChangeEnd: (_) => _emit())),
        Text('Res: ${_res.round()}', style: ts),
        Expanded(child: Slider(value: _res, min: 60, max: 300, divisions: 24,
          onChanged: (v) => setState(() => _res = v), onChangeEnd: (_) => _emit())),
      ]),
    ]);
  }
}
