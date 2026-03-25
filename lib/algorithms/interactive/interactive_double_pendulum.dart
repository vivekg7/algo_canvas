import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';

class DoublePendulumInteractiveState extends AlgorithmState {
  const DoublePendulumInteractiveState({
    required this.theta1,
    required this.theta2,
    required this.omega1,
    required this.omega2,
    required this.trail,
    this.dragging,
    required super.description,
  });
  final double theta1, theta2;
  final double omega1, omega2;
  final List<(double, double)> trail;
  final int? dragging; // null = no drag, 1 = first bob, 2 = second bob
}

class InteractiveDoublePendulumAlgorithm extends Algorithm {
  static const _l1 = 0.18;
  static const _l2 = 0.18;
  static const _m1 = 1.0;
  static const _m2 = 1.0;
  static const _g = 9.81;
  static const _dt = 0.004;
  static const _stepsPerTick = 4;
  static const _maxTrail = 600;

  @override String get name => 'Interactive Double Pendulum';
  @override String get description => 'Drag either bob to set position, release for chaotic motion.';
  @override AlgorithmCategory get category => AlgorithmCategory.physicsSimulation;
  @override AlgorithmMode get mode => AlgorithmMode.interactive;

  @override
  AlgorithmState createInitialState() {
    return const DoublePendulumInteractiveState(
      theta1: 2.0, theta2: 2.5, omega1: 0, omega2: 0, trail: [],
      description: 'Drag either bob to set position',
    );
  }

  @override
  AlgorithmState? onInteractionStart(AlgorithmState current, Offset localPosition) {
    final s = current as DoublePendulumInteractiveState;
    // Pivot at (0.5, 0.3) in normalized coords
    const px = 0.5, py = 0.3;

    // Joint position
    final jx = px + _l1 * sin(s.theta1);
    final jy = py + _l1 * cos(s.theta1);
    // Tip position
    final tx = jx + _l2 * sin(s.theta2);
    final ty = jy + _l2 * cos(s.theta2);

    final d1 = sqrt(pow(localPosition.dx - jx, 2) + pow(localPosition.dy - jy, 2));
    final d2 = sqrt(pow(localPosition.dx - tx, 2) + pow(localPosition.dy - ty, 2));

    if (d2 < 0.06) {
      return _setFromTip(s, localPosition, 2);
    } else if (d1 < 0.06) {
      return _setFromJoint(s, localPosition, 1);
    }
    return null;
  }

  @override
  AlgorithmState? onInteractionUpdate(AlgorithmState current, Offset localPosition) {
    final s = current as DoublePendulumInteractiveState;
    if (s.dragging == null) return null;
    if (s.dragging == 1) return _setFromJoint(s, localPosition, 1);
    return _setFromTip(s, localPosition, 2);
  }

  @override
  AlgorithmState? onInteractionEnd(AlgorithmState current) {
    final s = current as DoublePendulumInteractiveState;
    return DoublePendulumInteractiveState(
      theta1: s.theta1, theta2: s.theta2, omega1: 0, omega2: 0,
      trail: s.trail, description: 'Released — chaotic motion!',
    );
  }

  DoublePendulumInteractiveState _setFromJoint(
      DoublePendulumInteractiveState s, Offset pos, int dragging) {
    const px = 0.5, py = 0.3;
    final theta1 = atan2(pos.dx - px, pos.dy - py);
    return DoublePendulumInteractiveState(
      theta1: theta1, theta2: s.theta2, omega1: 0, omega2: 0,
      trail: [], dragging: dragging,
      description: 'Dragging arm 1',
    );
  }

  DoublePendulumInteractiveState _setFromTip(
      DoublePendulumInteractiveState s, Offset pos, int dragging) {
    const px = 0.5, py = 0.3;
    final jx = px + _l1 * sin(s.theta1);
    final jy = py + _l1 * cos(s.theta1);
    final theta2 = atan2(pos.dx - jx, pos.dy - jy);
    return DoublePendulumInteractiveState(
      theta1: s.theta1, theta2: theta2, omega1: 0, omega2: 0,
      trail: [], dragging: dragging,
      description: 'Dragging arm 2',
    );
  }

  @override
  AlgorithmState? tick(AlgorithmState current) {
    final s = current as DoublePendulumInteractiveState;
    if (s.dragging != null) return null;

    var th1 = s.theta1, th2 = s.theta2;
    var w1 = s.omega1, w2 = s.omega2;

    for (var i = 0; i < _stepsPerTick; i++) {
      final (nw1, nw2) = _rk4Step(th1, th2, w1, w2);
      w1 = nw1; w2 = nw2;
      th1 += w1 * _dt;
      th2 += w2 * _dt;
    }

    // Tip position for trail
    const px = 0.5, py = 0.3;
    final jx = px + _l1 * sin(th1);
    final jy = py + _l1 * cos(th1);
    final tx = jx + _l2 * sin(th2);
    final ty = jy + _l2 * cos(th2);

    final trail = List<(double, double)>.of(s.trail);
    trail.add((tx, ty));
    if (trail.length > _maxTrail) { trail.removeAt(0); }

    return DoublePendulumInteractiveState(
      theta1: th1, theta2: th2, omega1: w1, omega2: w2,
      trail: trail, description: 'Simulating...',
    );
  }

  (double, double) _rk4Step(double th1, double th2, double w1, double w2) {
    (double, double) derivs(double t1, double t2, double v1, double v2) {
      final dth = t1 - t2;
      final sinDth = sin(dth);
      final cosDth = cos(dth);
      final mt = _m1 + _m2;
      final den1 = mt * _l1 - _m2 * _l1 * cosDth * cosDth;
      final a1 = (_m2 * _l1 * v1 * v1 * sinDth * cosDth +
              _m2 * _g * sin(t2) * cosDth +
              _m2 * _l2 * v2 * v2 * sinDth -
              mt * _g * sin(t1)) / den1;
      final den2 = (_l2 / _l1) * den1;
      final a2 = (-_m2 * _l2 * v2 * v2 * sinDth * cosDth +
              mt * _g * sin(t1) * cosDth -
              mt * _l1 * v1 * v1 * sinDth -
              mt * _g * sin(t2)) / den2;
      return (a1, a2);
    }

    final (k1a, k1b) = derivs(th1, th2, w1, w2);
    final (k2a, k2b) = derivs(th1 + w1 * _dt / 2, th2 + w2 * _dt / 2,
        w1 + k1a * _dt / 2, w2 + k1b * _dt / 2);
    final (k3a, k3b) = derivs(th1 + w1 * _dt / 2, th2 + w2 * _dt / 2,
        w1 + k2a * _dt / 2, w2 + k2b * _dt / 2);
    final (k4a, k4b) = derivs(th1 + w1 * _dt, th2 + w2 * _dt,
        w1 + k3a * _dt, w2 + k3b * _dt);

    return (
      w1 + (_dt / 6) * (k1a + 2 * k2a + 2 * k3a + k4a),
      w2 + (_dt / 6) * (k1b + 2 * k2b + 2 * k3b + k4b),
    );
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) =>
      _Painter(state: state as DoublePendulumInteractiveState, brightness: Theme.of(context).brightness);
}

class _Painter extends CustomPainter {
  _Painter({required this.state, required this.brightness});
  final DoublePendulumInteractiveState state;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final isDark = brightness == Brightness.dark;
    const l1 = InteractiveDoublePendulumAlgorithm._l1;
    const l2 = InteractiveDoublePendulumAlgorithm._l2;

    final pivot = Offset(0.5 * size.width, 0.3 * size.height);
    final joint = Offset(
      pivot.dx + l1 * sin(state.theta1) * size.height,
      pivot.dy + l1 * cos(state.theta1) * size.height,
    );
    final tip = Offset(
      joint.dx + l2 * sin(state.theta2) * size.height,
      joint.dy + l2 * cos(state.theta2) * size.height,
    );

    // Trail
    if (state.trail.length > 1) {
      final trailColor = isDark ? const Color(0xFF42A5F5) : const Color(0xFF1976D2);
      final path = Path();
      path.moveTo(state.trail[0].$1 * size.width, state.trail[0].$2 * size.height);
      for (var i = 1; i < state.trail.length; i++) {
        path.lineTo(state.trail[i].$1 * size.width, state.trail[i].$2 * size.height);
      }
      canvas.drawPath(path, Paint()
        ..color = trailColor.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round);
    }

    // Arms
    final armPaint = Paint()
      ..color = isDark ? Colors.white70 : Colors.black87
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(pivot, joint, armPaint);
    canvas.drawLine(joint, tip, armPaint);

    // Pivot
    canvas.drawCircle(pivot, 5, Paint()..color = isDark ? Colors.white54 : Colors.black45);

    // Joint bob
    final jointColor = state.dragging == 1
        ? (isDark ? const Color(0xFFEF5350) : const Color(0xFFD32F2F))
        : (isDark ? const Color(0xFFFFCA28) : const Color(0xFFF9A825));
    canvas.drawCircle(joint, state.dragging == 1 ? 12 : 8, Paint()..color = jointColor);

    // Tip bob
    final tipColor = state.dragging == 2
        ? (isDark ? const Color(0xFFEF5350) : const Color(0xFFD32F2F))
        : (isDark ? const Color(0xFFEF5350) : const Color(0xFFD32F2F));
    canvas.drawCircle(tip, state.dragging == 2 ? 14 : 10, Paint()..color = tipColor);
  }

  @override bool shouldRepaint(covariant _Painter old) => !identical(old.state, state);
}
