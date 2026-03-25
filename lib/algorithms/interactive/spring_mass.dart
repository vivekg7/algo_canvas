import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';

class SpringMassState extends AlgorithmState {
  const SpringMassState({
    required this.nodes,
    required this.velocities,
    required this.springs,
    this.draggingIndex,
    required super.description,
  });
  final List<Offset> nodes;
  final List<Offset> velocities;
  final List<(int, int)> springs; // pairs of node indices
  final int? draggingIndex;
}

class SpringMassAlgorithm extends Algorithm {
  @override String get name => 'Spring-Mass System';
  @override String get description => 'Drag nodes connected by springs. Physics simulates in real-time.';
  @override AlgorithmCategory get category => AlgorithmCategory.physicsSimulation;
  @override AlgorithmMode get mode => AlgorithmMode.interactive;

  static const _nodeCount = 8;

  @override
  AlgorithmState createInitialState() {
    final nodes = List.generate(_nodeCount, (i) {
      final angle = 2 * pi * i / _nodeCount;
      return Offset(0.5 + 0.25 * cos(angle), 0.5 + 0.25 * sin(angle));
    });
    final velocities = List.generate(_nodeCount, (_) => Offset.zero);

    // Connect each node to its neighbors and to the center
    final springs = <(int, int)>[];
    for (var i = 0; i < _nodeCount; i++) {
      springs.add((i, (i + 1) % _nodeCount));
      if (i < _nodeCount ~/ 2) { springs.add((i, i + _nodeCount ~/ 2)); }
    }

    return SpringMassState(
      nodes: nodes, velocities: velocities, springs: springs,
      description: 'Drag nodes to interact. Springs pull them back.',
    );
  }

  @override
  AlgorithmState? onInteractionStart(AlgorithmState current, Offset localPosition) {
    final s = current as SpringMassState;
    for (var i = 0; i < s.nodes.length; i++) {
      if ((s.nodes[i] - localPosition).distance < 0.05) {
        final nodes = List<Offset>.of(s.nodes);
        nodes[i] = localPosition;
        return SpringMassState(
          nodes: nodes, velocities: s.velocities, springs: s.springs,
          draggingIndex: i, description: 'Dragging node ${i + 1}');
      }
    }
    return null;
  }

  @override
  AlgorithmState? onInteractionUpdate(AlgorithmState current, Offset localPosition) {
    final s = current as SpringMassState;
    if (s.draggingIndex == null) return null;
    final nodes = List<Offset>.of(s.nodes);
    nodes[s.draggingIndex!] = localPosition;
    // Zero velocity for dragged node
    final vels = List<Offset>.of(s.velocities);
    vels[s.draggingIndex!] = Offset.zero;
    return SpringMassState(
      nodes: nodes, velocities: vels, springs: s.springs,
      draggingIndex: s.draggingIndex, description: 'Dragging node ${s.draggingIndex! + 1}');
  }

  @override
  AlgorithmState? onInteractionEnd(AlgorithmState current) {
    final s = current as SpringMassState;
    return SpringMassState(
      nodes: s.nodes, velocities: s.velocities, springs: s.springs,
      description: 'Released. Springs simulating...');
  }

  @override
  AlgorithmState? tick(AlgorithmState current) {
    final s = current as SpringMassState;
    const dt = 0.016;
    const stiffness = 15.0;
    const damping = 0.92;
    const restLength = 0.15;

    final nodes = List<Offset>.of(s.nodes);
    final vels = List<Offset>.of(s.velocities);
    final n = nodes.length;

    // Spring forces
    for (final (a, b) in s.springs) {
      final dx = nodes[b].dx - nodes[a].dx;
      final dy = nodes[b].dy - nodes[a].dy;
      final dist = sqrt(dx * dx + dy * dy);
      if (dist < 0.001) continue;
      final force = stiffness * (dist - restLength);
      final fx = force * dx / dist * dt;
      final fy = force * dy / dist * dt;
      vels[a] = Offset(vels[a].dx + fx, vels[a].dy + fy);
      vels[b] = Offset(vels[b].dx - fx, vels[b].dy - fy);
    }

    // Apply damping and update positions
    for (var i = 0; i < n; i++) {
      vels[i] = Offset(vels[i].dx * damping, vels[i].dy * damping);
      nodes[i] = Offset(
        (nodes[i].dx + vels[i].dx * dt).clamp(0.02, 0.98),
        (nodes[i].dy + vels[i].dy * dt).clamp(0.02, 0.98),
      );
    }

    return SpringMassState(
      nodes: nodes, velocities: vels, springs: s.springs,
      description: 'Simulating...');
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) =>
      _SpringPainter(state: state as SpringMassState, brightness: Theme.of(context).brightness);
}

class _SpringPainter extends CustomPainter {
  _SpringPainter({required this.state, required this.brightness});
  final SpringMassState state;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final isDark = brightness == Brightness.dark;
    final springColor = isDark ? Colors.white24 : Colors.black26;
    final nodeColor = isDark ? const Color(0xFF42A5F5) : const Color(0xFF1976D2);
    final dragColor = isDark ? const Color(0xFFEF5350) : const Color(0xFFD32F2F);

    // Springs
    for (final (a, b) in state.springs) {
      canvas.drawLine(
        Offset(state.nodes[a].dx * size.width, state.nodes[a].dy * size.height),
        Offset(state.nodes[b].dx * size.width, state.nodes[b].dy * size.height),
        Paint()..color = springColor..strokeWidth = 2);
    }

    // Nodes
    for (var i = 0; i < state.nodes.length; i++) {
      final p = Offset(state.nodes[i].dx * size.width, state.nodes[i].dy * size.height);
      final isDragging = state.draggingIndex == i;
      canvas.drawCircle(p, isDragging ? 12 : 8, Paint()..color = isDragging ? dragColor : nodeColor);
    }
  }

  @override bool shouldRepaint(covariant _SpringPainter old) => !identical(old.state, state);
}
