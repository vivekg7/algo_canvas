import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';

class WaveState extends AlgorithmState {
  const WaveState({
    required this.current,
    required this.step,
    required super.description,
  });

  /// 1D wave amplitudes (normalized -1 to 1).
  final List<double> current;
  final int step;
}

class WaveEquationAlgorithm extends Algorithm {
  int _points = 300;
  double _speed = 1.0;
  double _damping = 0.998;

  @override
  String get name => 'Wave Equation';

  @override
  String get description =>
      '1D wave propagation with reflection at boundaries and damping.';

  @override
  AlgorithmCategory get category => AlgorithmCategory.physicsSimulation;

  @override
  AlgorithmMode get mode => AlgorithmMode.live;

  @override
  AlgorithmState createInitialState() {
    final n = _points;
    // Gaussian pulse in the center
    final current = List<double>.generate(n, (i) {
      final x = (i - n / 2) / (n * 0.05);
      return exp(-x * x);
    });
    // Previous = same as current (zero initial velocity)
    // We store prev in the state by encoding it — or we can use two arrays.
    // Simpler: use a helper state that holds both.
    return _WaveInternalState(
      current: List.of(current),
      previous: List.of(current),
      step: 0,
      description: 'Step 0: Gaussian pulse at center',
    );
  }

  @override
  AlgorithmState? tick(AlgorithmState current) {
    final s = current as _WaveInternalState;
    final n = s.current.length;
    final c = _speed * 0.8; // Courant number
    final c2 = c * c;

    final next = List<double>.filled(n, 0);

    // Wave equation: u(t+1) = 2*u(t) - u(t-1) + c²*(u(i+1) - 2*u(i) + u(i-1))
    for (var i = 1; i < n - 1; i++) {
      next[i] = _damping * (2 * s.current[i] -
              s.previous[i] +
              c2 * (s.current[i + 1] - 2 * s.current[i] + s.current[i - 1]));
    }

    // Fixed boundary conditions (reflection)
    next[0] = 0;
    next[n - 1] = 0;

    final step = s.step + 1;

    return _WaveInternalState(
      current: next,
      previous: List.of(s.current),
      step: step,
      description: 'Step $step',
    );
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) {
    return _WavePainter(
      state: state as WaveState,
      brightness: Theme.of(context).brightness,
    );
  }

  @override
  Widget? buildControls({required VoidCallback onChanged}) {
    return _Controls(
      points: _points,
      speed: _speed,
      damping: _damping,
      onChanged: (points, speed, damping) {
        _points = points;
        _speed = speed;
        _damping = damping;
        onChanged();
      },
    );
  }
}

/// Internal state that also tracks the previous frame for the wave equation.
class _WaveInternalState extends WaveState {
  const _WaveInternalState({
    required super.current,
    required this.previous,
    required super.step,
    required super.description,
  });

  final List<double> previous;
}

class _WavePainter extends CustomPainter {
  _WavePainter({required this.state, required this.brightness});

  final WaveState state;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final isDark = brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5);
    final waveColor = isDark ? const Color(0xFF42A5F5) : const Color(0xFF1976D2);
    final fillColor = isDark
        ? const Color(0xFF42A5F5).withValues(alpha: 0.15)
        : const Color(0xFF1976D2).withValues(alpha: 0.1);
    final axisColor = isDark ? Colors.white24 : Colors.black12;

    // Background
    canvas.drawRect(Offset.zero & size, Paint()..color = bgColor);

    final midY = size.height / 2;
    final amplitude = size.height * 0.4;
    final points = state.current;
    final n = points.length;
    if (n < 2) return;

    final dx = size.width / (n - 1);

    // Center axis
    canvas.drawLine(
      Offset(0, midY),
      Offset(size.width, midY),
      Paint()
        ..color = axisColor
        ..strokeWidth = 1,
    );

    // Wave fill
    final fillPath = Path()..moveTo(0, midY);
    for (var i = 0; i < n; i++) {
      fillPath.lineTo(i * dx, midY - points[i] * amplitude);
    }
    fillPath.lineTo(size.width, midY);
    fillPath.close();
    canvas.drawPath(fillPath, Paint()..color = fillColor);

    // Wave line
    final wavePath = Path();
    wavePath.moveTo(0, midY - points[0] * amplitude);
    for (var i = 1; i < n; i++) {
      wavePath.lineTo(i * dx, midY - points[i] * amplitude);
    }

    canvas.drawPath(
      wavePath,
      Paint()
        ..color = waveColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Border
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color = isDark ? Colors.white12 : Colors.black12
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.state != state;
  }
}

class _Controls extends StatefulWidget {
  const _Controls({
    required this.points,
    required this.speed,
    required this.damping,
    required this.onChanged,
  });

  final int points;
  final double speed;
  final double damping;
  final void Function(int points, double speed, double damping) onChanged;

  @override
  State<_Controls> createState() => _ControlsState();
}

class _ControlsState extends State<_Controls> {
  late double _points;
  late double _speed;
  late double _damping;

  @override
  void initState() {
    super.initState();
    _points = widget.points.toDouble();
    _speed = widget.speed;
    _damping = widget.damping;
  }

  void _emit() {
    widget.onChanged(_points.round(), _speed, _damping);
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodySmall;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text('Points: ${_points.round()}', style: textStyle),
            Expanded(
              child: Slider(
                value: _points, min: 50, max: 600, divisions: 22,
                onChanged: (v) => setState(() => _points = v),
                onChangeEnd: (_) => _emit(),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Text('Speed: ${_speed.toStringAsFixed(1)}', style: textStyle),
            Expanded(
              child: Slider(
                value: _speed, min: 0.1, max: 1.0, divisions: 9,
                onChanged: (v) => setState(() => _speed = v),
                onChangeEnd: (_) => _emit(),
              ),
            ),
            Text('Damping: ${(_damping * 100).toStringAsFixed(1)}%',
                style: textStyle),
            Expanded(
              child: Slider(
                value: _damping, min: 0.98, max: 1.0, divisions: 20,
                onChanged: (v) => setState(() => _damping = v),
                onChangeEnd: (_) => _emit(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
