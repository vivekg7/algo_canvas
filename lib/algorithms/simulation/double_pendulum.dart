import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';

class DoublePendulumState extends AlgorithmState {
  const DoublePendulumState({
    required this.theta1,
    required this.theta2,
    required this.l1,
    required this.l2,
    required this.trail,
    required this.step,
    required super.description,
  });

  final double theta1; // angle of first arm (radians)
  final double theta2; // angle of second arm (radians)
  final double l1; // length of first arm (normalized)
  final double l2; // length of second arm (normalized)

  /// Trail of tip positions as (x, y) in normalized coords centered at origin.
  final List<(double, double)> trail;
  final int step;
}

class DoublePendulumAlgorithm extends Algorithm {
  double _angle1 = 120; // degrees
  double _angle2 = 150; // degrees

  @override
  String get name => 'Double Pendulum';

  @override
  String get description =>
      'Two connected pendulums exhibiting chaotic motion from simple physics.';

  @override
  AlgorithmCategory get category => AlgorithmCategory.physicsSimulation;

  @override
  bool get isStreaming => true;

  @override
  Stream<AlgorithmState> stream() async* {
    const l1 = 0.4; // normalized lengths
    const l2 = 0.4;
    const m1 = 1.0;
    const m2 = 1.0;
    const g = 9.81;
    const dt = 0.005;
    const stepsPerFrame = 4;
    const maxFrames = 3000;
    const maxTrailLength = 800;

    var th1 = _angle1 * pi / 180;
    var th2 = _angle2 * pi / 180;
    var w1 = 0.0; // angular velocity
    var w2 = 0.0;

    final trail = <(double, double)>[];

    // Compute tip position
    (double, double) tip() {
      final x = l1 * sin(th1) + l2 * sin(th2);
      final y = l1 * cos(th1) + l2 * cos(th2);
      return (x, y);
    }

    trail.add(tip());

    yield DoublePendulumState(
      theta1: th1,
      theta2: th2,
      l1: l1,
      l2: l2,
      trail: List.of(trail),
      step: 0,
      description: 'Initial angles: ${_angle1.round()}° and ${_angle2.round()}°',
    );

    for (var frame = 1; frame <= maxFrames; frame++) {
      if (frame % 20 == 0) {
        await Future<void>.delayed(Duration.zero);
      }

      // Runge-Kutta 4th order integration, multiple sub-steps per frame
      for (var s = 0; s < stepsPerFrame; s++) {
        final (nw1, nw2) = _rk4Step(th1, th2, w1, w2, m1, m2, l1, l2, g, dt);
        w1 = nw1;
        w2 = nw2;
        th1 += w1 * dt;
        th2 += w2 * dt;
      }

      final t = tip();
      trail.add(t);
      if (trail.length > maxTrailLength) {
        trail.removeAt(0);
      }

      yield DoublePendulumState(
        theta1: th1,
        theta2: th2,
        l1: l1,
        l2: l2,
        trail: List.of(trail),
        step: frame,
        description: 'Step $frame',
      );
    }
  }

  /// RK4 integration step. Returns updated (w1, w2).
  (double, double) _rk4Step(
    double th1,
    double th2,
    double w1,
    double w2,
    double m1,
    double m2,
    double l1,
    double l2,
    double g,
    double dt,
  ) {
    (double, double) derivs(double t1, double t2, double v1, double v2) {
      final dth = t1 - t2;
      final sinDth = sin(dth);
      final cosDth = cos(dth);
      final mt = m1 + m2;

      final den1 = mt * l1 - m2 * l1 * cosDth * cosDth;
      final a1 = (m2 * l1 * v1 * v1 * sinDth * cosDth +
              m2 * g * sin(t2) * cosDth +
              m2 * l2 * v2 * v2 * sinDth -
              mt * g * sin(t1)) /
          den1;

      final den2 = (l2 / l1) * den1;
      final a2 = (-m2 * l2 * v2 * v2 * sinDth * cosDth +
              mt * g * sin(t1) * cosDth -
              mt * l1 * v1 * v1 * sinDth -
              mt * g * sin(t2)) /
          den2;

      return (a1, a2);
    }

    final (k1a, k1b) = derivs(th1, th2, w1, w2);
    final (k2a, k2b) = derivs(
        th1 + w1 * dt / 2, th2 + w2 * dt / 2, w1 + k1a * dt / 2, w2 + k1b * dt / 2);
    final (k3a, k3b) = derivs(
        th1 + w1 * dt / 2, th2 + w2 * dt / 2, w1 + k2a * dt / 2, w2 + k2b * dt / 2);
    final (k4a, k4b) = derivs(
        th1 + w1 * dt, th2 + w2 * dt, w1 + k3a * dt, w2 + k3b * dt);

    final nw1 = w1 + (dt / 6) * (k1a + 2 * k2a + 2 * k3a + k4a);
    final nw2 = w2 + (dt / 6) * (k1b + 2 * k2b + 2 * k3b + k4b);

    return (nw1, nw2);
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) {
    return _DoublePendulumPainter(
      state: state as DoublePendulumState,
      brightness: Theme.of(context).brightness,
    );
  }

  @override
  Widget? buildControls({required VoidCallback onChanged}) {
    return _Controls(
      angle1: _angle1,
      angle2: _angle2,
      onChanged: (a1, a2) {
        _angle1 = a1;
        _angle2 = a2;
        onChanged();
      },
    );
  }
}

class _DoublePendulumPainter extends CustomPainter {
  _DoublePendulumPainter({required this.state, required this.brightness});

  final DoublePendulumState state;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final isDark = brightness == Brightness.dark;
    final scale = size.shortestSide * 0.55;
    final center = Offset(size.width / 2, size.height * 0.35);

    final l1 = state.l1;
    final l2 = state.l2;

    // Joint and tip positions
    final joint = Offset(
      center.dx + l1 * sin(state.theta1) * scale,
      center.dy + l1 * cos(state.theta1) * scale,
    );
    final tip = Offset(
      joint.dx + l2 * sin(state.theta2) * scale,
      joint.dy + l2 * cos(state.theta2) * scale,
    );

    // Draw trail
    if (state.trail.length > 1) {
      final trailPath = Path();
      final first = state.trail.first;
      trailPath.moveTo(
        center.dx + first.$1 * scale,
        center.dy + first.$2 * scale,
      );

      for (var i = 1; i < state.trail.length; i++) {
        final p = state.trail[i];
        trailPath.lineTo(
          center.dx + p.$1 * scale,
          center.dy + p.$2 * scale,
        );
      }

      // Gradient trail: older = more transparent
      final trailColor = isDark
          ? const Color(0xFF42A5F5)
          : const Color(0xFF1976D2);

      canvas.drawPath(
        trailPath,
        Paint()
          ..color = trailColor.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
      );
    }

    // Draw arms
    final armPaint = Paint()
      ..color = isDark ? Colors.white70 : Colors.black87
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, joint, armPaint);
    canvas.drawLine(joint, tip, armPaint);

    // Draw pivot
    canvas.drawCircle(
      center,
      5,
      Paint()..color = isDark ? Colors.white54 : Colors.black45,
    );

    // Draw joint
    canvas.drawCircle(
      joint,
      7,
      Paint()
        ..color = isDark
            ? const Color(0xFFFFCA28)
            : const Color(0xFFF9A825),
    );

    // Draw tip (bob)
    canvas.drawCircle(
      tip,
      9,
      Paint()
        ..color = isDark
            ? const Color(0xFFEF5350)
            : const Color(0xFFD32F2F),
    );
  }

  @override
  bool shouldRepaint(covariant _DoublePendulumPainter oldDelegate) {
    return oldDelegate.state != state;
  }
}

class _Controls extends StatefulWidget {
  const _Controls({
    required this.angle1,
    required this.angle2,
    required this.onChanged,
  });

  final double angle1;
  final double angle2;
  final void Function(double a1, double a2) onChanged;

  @override
  State<_Controls> createState() => _ControlsState();
}

class _ControlsState extends State<_Controls> {
  late double _a1;
  late double _a2;

  @override
  void initState() {
    super.initState();
    _a1 = widget.angle1;
    _a2 = widget.angle2;
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodySmall;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text('Arm 1: ${_a1.round()}°', style: textStyle),
            Expanded(
              child: Slider(
                value: _a1,
                min: 0,
                max: 180,
                divisions: 36,
                onChanged: (v) => setState(() => _a1 = v),
                onChangeEnd: (v) => widget.onChanged(v, _a2),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Text('Arm 2: ${_a2.round()}°', style: textStyle),
            Expanded(
              child: Slider(
                value: _a2,
                min: 0,
                max: 180,
                divisions: 36,
                onChanged: (v) => setState(() => _a2 = v),
                onChangeEnd: (v) => widget.onChanged(_a1, v),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
