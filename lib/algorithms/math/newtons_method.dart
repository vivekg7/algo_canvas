import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';

class NewtonsMethodState extends AlgorithmState {
  const NewtonsMethodState({
    required this.iterations,
    this.currentX,
    this.completed = false,
    required super.description,
  });

  /// List of (x, fx, tangentSlope) for each iteration.
  final List<(double, double, double)> iterations;
  final double? currentX;
  final bool completed;
}

/// Finds root of f(x) = x³ - 2x - 5 (has root near x ≈ 2.0946).
class NewtonsMethodAlgorithm extends Algorithm {
  double _initialGuess = 4.0;

  @override
  String get name => "Newton's Method";

  @override
  String get description =>
      'Root finding by following tangent lines to converge on f(x) = 0.';

  @override
  AlgorithmCategory get category => AlgorithmCategory.mathSignal;

  static double _f(double x) => x * x * x - 2 * x - 5;
  static double _fPrime(double x) => 3 * x * x - 2;

  @override
  Future<List<AlgorithmState>> generate() async {
    final states = <NewtonsMethodState>[];
    final iterations = <(double, double, double)>[];
    var x = _initialGuess;

    states.add(NewtonsMethodState(
      iterations: List.of(iterations),
      currentX: x,
      description: 'Finding root of f(x) = x³ - 2x - 5, starting at x = ${x.toStringAsFixed(2)}',
    ));

    for (var i = 0; i < 20; i++) {
      final fx = _f(x);
      final fpx = _fPrime(x);

      iterations.add((x, fx, fpx));

      states.add(NewtonsMethodState(
        iterations: List.of(iterations),
        currentX: x,
        description:
            'Iteration ${i + 1}: x = ${x.toStringAsFixed(6)}, f(x) = ${fx.toStringAsFixed(6)}',
      ));

      if (fx.abs() < 1e-10 || fpx.abs() < 1e-15) {
        states.add(NewtonsMethodState(
          iterations: List.of(iterations),
          currentX: x,
          completed: true,
          description: 'Converged! Root ≈ ${x.toStringAsFixed(8)}',
        ));
        return states;
      }

      final xNew = x - fx / fpx;

      states.add(NewtonsMethodState(
        iterations: List.of(iterations),
        currentX: xNew,
        description:
            'x_{${i + 2}} = ${x.toStringAsFixed(4)} - ${fx.toStringAsFixed(4)}/${fpx.toStringAsFixed(4)} = ${xNew.toStringAsFixed(6)}',
      ));

      x = xNew;
    }

    states.add(NewtonsMethodState(
      iterations: List.of(iterations),
      currentX: x,
      completed: true,
      description: 'Root ≈ ${x.toStringAsFixed(8)} after 20 iterations',
    ));

    return states;
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) {
    return _NewtonsPainter(
      state: state as NewtonsMethodState,
      brightness: Theme.of(context).brightness,
    );
  }

  @override
  Widget? buildControls({required VoidCallback onChanged}) {
    return _Controls(
      initialGuess: _initialGuess,
      onChanged: (v) {
        _initialGuess = v;
        onChanged();
      },
    );
  }
}

class _NewtonsPainter extends CustomPainter {
  _NewtonsPainter({required this.state, required this.brightness});

  final NewtonsMethodState state;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final isDark = brightness == Brightness.dark;
    final axisColor = isDark ? Colors.white24 : Colors.black26;
    final curveColor = isDark ? const Color(0xFF42A5F5) : const Color(0xFF1976D2);
    final tangentColor = isDark
        ? const Color(0xFFFFCA28).withValues(alpha: 0.7)
        : const Color(0xFFF9A825).withValues(alpha: 0.7);
    final pointColor = isDark ? const Color(0xFFEF5350) : const Color(0xFFD32F2F);
    final rootColor = isDark ? const Color(0xFF4CAF50) : const Color(0xFF388E3C);

    // Viewport
    const xMin = -2.0;
    const xMax = 5.0;
    const yMin = -20.0;
    const yMax = 80.0;

    double toScreenX(double x) => (x - xMin) / (xMax - xMin) * size.width;
    double toScreenY(double y) => size.height - (y - yMin) / (yMax - yMin) * size.height;

    // Axes
    final zeroY = toScreenY(0);
    final zeroX = toScreenX(0);
    canvas.drawLine(Offset(0, zeroY), Offset(size.width, zeroY),
        Paint()..color = axisColor..strokeWidth = 1);
    canvas.drawLine(Offset(zeroX, 0), Offset(zeroX, size.height),
        Paint()..color = axisColor..strokeWidth = 1);

    // Function curve
    final curvePath = Path();
    var first = true;
    for (var px = 0.0; px <= size.width; px += 1) {
      final x = xMin + (px / size.width) * (xMax - xMin);
      final y = NewtonsMethodAlgorithm._f(x);
      final sy = toScreenY(y);
      if (sy.isFinite && sy > -500 && sy < size.height + 500) {
        if (first) {
          curvePath.moveTo(px, sy);
          first = false;
        } else {
          curvePath.lineTo(px, sy);
        }
      }
    }
    canvas.drawPath(
      curvePath,
      Paint()
        ..color = curveColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Tangent lines and points for each iteration
    for (var i = 0; i < state.iterations.length; i++) {
      final (x, fx, fpx) = state.iterations[i];
      final sx = toScreenX(x);
      final sy = toScreenY(fx);

      // Tangent line: y - fx = fpx * (X - x)
      final tangentX1 = xMin;
      final tangentY1 = fx + fpx * (tangentX1 - x);
      final tangentX2 = xMax;
      final tangentY2 = fx + fpx * (tangentX2 - x);

      canvas.drawLine(
        Offset(toScreenX(tangentX1), toScreenY(tangentY1)),
        Offset(toScreenX(tangentX2), toScreenY(tangentY2)),
        Paint()
          ..color = tangentColor
          ..strokeWidth = 1,
      );

      // Vertical line from x-axis to curve
      canvas.drawLine(
        Offset(sx, zeroY),
        Offset(sx, sy),
        Paint()
          ..color = pointColor.withValues(alpha: 0.3)
          ..strokeWidth = 1
          ..strokeCap = StrokeCap.round,
      );

      // Point on curve
      canvas.drawCircle(
        Offset(sx, sy),
        4,
        Paint()..color = pointColor,
      );

      // X-intercept of tangent (next x value)
      if (fpx.abs() > 1e-15) {
        final nextX = x - fx / fpx;
        canvas.drawCircle(
          Offset(toScreenX(nextX), zeroY),
          3,
          Paint()..color = rootColor,
        );
      }
    }

    // Current x marker
    if (state.currentX != null) {
      canvas.drawCircle(
        Offset(toScreenX(state.currentX!), zeroY),
        state.completed ? 6 : 4,
        Paint()..color = state.completed ? rootColor : pointColor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NewtonsPainter oldDelegate) {
    return oldDelegate.state != state;
  }
}

class _Controls extends StatefulWidget {
  const _Controls({required this.initialGuess, required this.onChanged});
  final double initialGuess;
  final ValueChanged<double> onChanged;

  @override
  State<_Controls> createState() => _ControlsState();
}

class _ControlsState extends State<_Controls> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialGuess;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('Initial x₀: ${_value.toStringAsFixed(1)}',
            style: Theme.of(context).textTheme.bodySmall),
        Expanded(
          child: Slider(
            value: _value, min: -1, max: 5, divisions: 60,
            onChanged: (v) => setState(() => _value = v),
            onChangeEnd: (v) => widget.onChanged(v),
          ),
        ),
      ],
    );
  }
}
