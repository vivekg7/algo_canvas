import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';

class PendulumState extends AlgorithmState {
  const PendulumState({
    required this.angle,
    required this.angularVelocity,
    required this.trail,
    this.isDragging = false,
    required super.description,
  });
  final double angle; // radians
  final double angularVelocity;
  final List<double> trail; // past angles
  final bool isDragging;
}

class InteractivePendulumAlgorithm extends Algorithm {
  @override String get name => 'Interactive Pendulum';
  @override String get description => 'Drag the bob to set angle, release to simulate. Gravity does the rest.';
  @override AlgorithmCategory get category => AlgorithmCategory.physicsSimulation;
  @override AlgorithmMode get mode => AlgorithmMode.interactive;

  @override
  AlgorithmState createInitialState() {
    return const PendulumState(
      angle: 0.5, angularVelocity: 0, trail: [],
      description: 'Drag the bob to set initial angle',
    );
  }

  @override
  AlgorithmState? onInteractionStart(AlgorithmState current, Offset localPosition) {
    // Convert position to angle relative to pivot (0.5, 0.2)
    final angle = atan2(localPosition.dx - 0.5, localPosition.dy - 0.2);
    return PendulumState(
      angle: angle, angularVelocity: 0, trail: (current as PendulumState).trail,
      isDragging: true, description: 'Angle: ${(angle * 180 / pi).toStringAsFixed(1)}°');
  }

  @override
  AlgorithmState? onInteractionUpdate(AlgorithmState current, Offset localPosition) {
    final angle = atan2(localPosition.dx - 0.5, localPosition.dy - 0.2);
    return PendulumState(
      angle: angle, angularVelocity: 0, trail: (current as PendulumState).trail,
      isDragging: true, description: 'Angle: ${(angle * 180 / pi).toStringAsFixed(1)}°');
  }

  @override
  AlgorithmState? onInteractionEnd(AlgorithmState current) {
    final s = current as PendulumState;
    return PendulumState(
      angle: s.angle, angularVelocity: 0, trail: s.trail,
      description: 'Released — simulating...');
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) =>
      _PendulumPainter(state: state as PendulumState, brightness: Theme.of(context).brightness);
}

class _PendulumPainter extends CustomPainter {
  _PendulumPainter({required this.state, required this.brightness});
  final PendulumState state;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final isDark = brightness == Brightness.dark;
    final armColor = isDark ? Colors.white70 : Colors.black87;
    final bobColor = isDark ? const Color(0xFFEF5350) : const Color(0xFFD32F2F);
    final pivotColor = isDark ? Colors.white54 : Colors.black45;
    final trailColor = isDark ? const Color(0xFF42A5F5).withValues(alpha: 0.3) : const Color(0xFF1976D2).withValues(alpha: 0.2);

    final pivot = Offset(size.width * 0.5, size.height * 0.2);
    const length = 0.35;
    final bobX = pivot.dx + sin(state.angle) * length * size.height;
    final bobY = pivot.dy + cos(state.angle) * length * size.height;
    final bob = Offset(bobX, bobY);

    // Trail
    for (var i = 0; i < state.trail.length; i++) {
      final a = state.trail[i];
      final tx = pivot.dx + sin(a) * length * size.height;
      final ty = pivot.dy + cos(a) * length * size.height;
      final opacity = (i / state.trail.length).clamp(0.0, 1.0);
      canvas.drawCircle(Offset(tx, ty), 2,
        Paint()..color = trailColor.withValues(alpha: opacity * 0.5));
    }

    // Arm
    canvas.drawLine(pivot, bob, Paint()..color = armColor..strokeWidth = 3..strokeCap = StrokeCap.round);

    // Pivot
    canvas.drawCircle(pivot, 5, Paint()..color = pivotColor);

    // Bob
    canvas.drawCircle(bob, state.isDragging ? 16 : 12, Paint()..color = bobColor);

    // Angle arc
    if (state.angle.abs() > 0.01) {
      final arcRect = Rect.fromCircle(center: pivot, radius: 30);
      canvas.drawArc(arcRect, pi / 2 - state.angle, state.angle, false,
        Paint()..color = isDark ? Colors.white24 : Colors.black26..style = PaintingStyle.stroke..strokeWidth = 1.5);
    }
  }

  @override bool shouldRepaint(covariant _PendulumPainter old) => !identical(old.state, state);
}
