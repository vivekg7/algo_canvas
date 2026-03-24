import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';

class NBodyState extends AlgorithmState {
  const NBodyState({
    required this.bodies,
    required this.step,
    required this.trails,
    required super.description,
  });

  /// Each body as (x, y, vx, vy, mass).
  final List<(double, double, double, double, double)> bodies;

  /// Trail for each body: list of (x, y) positions.
  final List<List<(double, double)>> trails;
  final int step;
}

class NBodyAlgorithm extends Algorithm {
  int _count = 30;
  double _gravity = 1.0;
  static const _maxTrail = 60;

  @override
  String get name => 'N-Body Gravity';

  @override
  String get description =>
      'Particles attract each other via gravitational force. O(n²).';

  @override
  AlgorithmCategory get category => AlgorithmCategory.physicsSimulation;

  @override
  AlgorithmMode get mode => AlgorithmMode.live;

  @override
  AlgorithmState createInitialState() {
    final random = Random();
    final bodies = <(double, double, double, double, double)>[];
    final trails = <List<(double, double)>>[];

    // Central massive body
    bodies.add((0.5, 0.5, 0, 0, 50.0));
    trails.add([(0.5, 0.5)]);

    // Orbiting bodies
    for (var i = 1; i < _count; i++) {
      final angle = random.nextDouble() * 2 * pi;
      final dist = 0.1 + random.nextDouble() * 0.3;
      final x = 0.5 + cos(angle) * dist;
      final y = 0.5 + sin(angle) * dist;

      // Tangential velocity for roughly circular orbit
      final orbitalSpeed = sqrt(50.0 * _gravity * 0.0001 / dist) * 0.8;
      final vx = -sin(angle) * orbitalSpeed;
      final vy = cos(angle) * orbitalSpeed;

      final mass = 0.5 + random.nextDouble() * 2.0;
      bodies.add((x, y, vx, vy, mass));
      trails.add([(x, y)]);
    }

    return NBodyState(
      bodies: bodies,
      trails: trails,
      step: 0,
      description: 'Step 0: $_count bodies',
    );
  }

  @override
  AlgorithmState? tick(AlgorithmState current) {
    final s = current as NBodyState;
    final n = s.bodies.length;
    const dt = 0.016;
    const softening = 0.005; // prevent division by zero
    final g = _gravity * 0.0001;

    // Copy positions/velocities
    final x = List<double>.generate(n, (i) => s.bodies[i].$1);
    final y = List<double>.generate(n, (i) => s.bodies[i].$2);
    final vx = List<double>.generate(n, (i) => s.bodies[i].$3);
    final vy = List<double>.generate(n, (i) => s.bodies[i].$4);
    final mass = List<double>.generate(n, (i) => s.bodies[i].$5);

    // Compute forces
    for (var i = 0; i < n; i++) {
      var ax = 0.0, ay = 0.0;
      for (var j = 0; j < n; j++) {
        if (i == j) continue;
        final dx = x[j] - x[i];
        final dy = y[j] - y[i];
        final distSq = dx * dx + dy * dy + softening;
        final dist = sqrt(distSq);
        final force = g * mass[j] / distSq;
        ax += force * dx / dist;
        ay += force * dy / dist;
      }
      vx[i] += ax * dt;
      vy[i] += ay * dt;
    }

    // Update positions
    for (var i = 0; i < n; i++) {
      x[i] += vx[i] * dt;
      y[i] += vy[i] * dt;
    }

    // Build new bodies and trails
    final bodies = <(double, double, double, double, double)>[];
    final trails = <List<(double, double)>>[];

    for (var i = 0; i < n; i++) {
      bodies.add((x[i], y[i], vx[i], vy[i], mass[i]));

      final trail = List<(double, double)>.of(s.trails[i]);
      trail.add((x[i], y[i]));
      if (trail.length > _maxTrail) trail.removeAt(0);
      trails.add(trail);
    }

    final step = s.step + 1;

    return NBodyState(
      bodies: bodies,
      trails: trails,
      step: step,
      description: 'Step $step: $n bodies',
    );
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) {
    return _NBodyPainter(
      state: state as NBodyState,
      brightness: Theme.of(context).brightness,
    );
  }

  @override
  Widget? buildControls({required VoidCallback onChanged}) {
    return _Controls(
      count: _count,
      gravity: _gravity,
      onChanged: (count, gravity) {
        _count = count;
        _gravity = gravity;
        onChanged();
      },
    );
  }
}

class _NBodyPainter extends CustomPainter {
  _NBodyPainter({required this.state, required this.brightness});

  final NBodyState state;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final isDark = brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0A0A1A) : const Color(0xFFF0F0F8);

    canvas.drawRect(Offset.zero & size, Paint()..color = bgColor);

    final bodies = state.bodies;
    final trails = state.trails;

    // Color palette for bodies
    const colors = [
      Color(0xFFFFCA28), // central body
      Color(0xFF42A5F5),
      Color(0xFFEF5350),
      Color(0xFF66BB6A),
      Color(0xFFAB47BC),
      Color(0xFFFF7043),
      Color(0xFF26C6DA),
      Color(0xFFEC407A),
    ];

    for (var i = 0; i < bodies.length; i++) {
      final color = colors[i % colors.length];
      final (bx, by, _, _, mass) = bodies[i];
      final px = bx * size.width;
      final py = by * size.height;

      // Trail
      if (trails[i].length > 1) {
        final trailPath = Path();
        final first = trails[i].first;
        trailPath.moveTo(first.$1 * size.width, first.$2 * size.height);
        for (var j = 1; j < trails[i].length; j++) {
          final p = trails[i][j];
          trailPath.lineTo(p.$1 * size.width, p.$2 * size.height);
        }
        canvas.drawPath(
          trailPath,
          Paint()
            ..color = color.withValues(alpha: 0.25)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }

      // Body
      final radius = (1.5 + sqrt(mass) * 1.2).clamp(2.0, 12.0);
      canvas.drawCircle(
        Offset(px, py),
        radius,
        Paint()..color = color,
      );
    }

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
  bool shouldRepaint(covariant _NBodyPainter oldDelegate) {
    return oldDelegate.state != state;
  }
}

class _Controls extends StatefulWidget {
  const _Controls({
    required this.count,
    required this.gravity,
    required this.onChanged,
  });

  final int count;
  final double gravity;
  final void Function(int count, double gravity) onChanged;

  @override
  State<_Controls> createState() => _ControlsState();
}

class _ControlsState extends State<_Controls> {
  late double _count;
  late double _gravity;

  @override
  void initState() {
    super.initState();
    _count = widget.count.toDouble();
    _gravity = widget.gravity;
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodySmall;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text('Bodies: ${_count.round()}', style: textStyle),
            Expanded(
              child: Slider(
                value: _count, min: 5, max: 100, divisions: 19,
                onChanged: (v) => setState(() => _count = v),
                onChangeEnd: (v) =>
                    widget.onChanged(v.round(), _gravity),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Text('Gravity: ${_gravity.toStringAsFixed(1)}x', style: textStyle),
            Expanded(
              child: Slider(
                value: _gravity, min: 0.1, max: 5.0, divisions: 49,
                onChanged: (v) => setState(() => _gravity = v),
                onChangeEnd: (v) =>
                    widget.onChanged(_count.round(), v),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
