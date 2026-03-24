import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';

class _Boid {
  double x, y, vx, vy;
  _Boid(this.x, this.y, this.vx, this.vy);

  _Boid copy() => _Boid(x, y, vx, vy);
}

class BoidsState extends AlgorithmState {
  const BoidsState({
    required this.boids,
    required this.step,
    required this.width,
    required this.height,
    required super.description,
  });

  /// Each boid as (x, y, vx, vy).
  final List<(double, double, double, double)> boids;
  final int step;
  final double width;
  final double height;
}

class BoidsAlgorithm extends Algorithm {
  int _count = 80;
  double _separation = 1.0;
  double _alignment = 1.0;
  double _cohesion = 1.0;

  @override
  String get name => 'Boids (Flocking)';

  @override
  String get description =>
      'Emergent flocking from 3 rules: separation, alignment, cohesion.';

  @override
  AlgorithmCategory get category => AlgorithmCategory.physicsSimulation;

  @override
  AlgorithmMode get mode => AlgorithmMode.live;

  @override
  AlgorithmState createInitialState() {
    final random = Random();
    const w = 1.0;
    const h = 1.0;
    final boids = List.generate(_count, (_) {
      final angle = random.nextDouble() * 2 * pi;
      const speed = 0.003;
      return _Boid(
        random.nextDouble() * w,
        random.nextDouble() * h,
        cos(angle) * speed,
        sin(angle) * speed,
      );
    });

    return _stateFromBoids(boids, 0, w, h);
  }

  @override
  AlgorithmState? tick(AlgorithmState current) {
    final s = current as BoidsState;
    final boids = s.boids
        .map((b) => _Boid(b.$1, b.$2, b.$3, b.$4))
        .toList();
    final w = s.width;
    final h = s.height;

    const visualRange = 0.08;
    const protectedRange = 0.02;
    const maxSpeed = 0.006;
    const minSpeed = 0.002;
    const turnFactor = 0.0003;
    const margin = 0.05;

    for (var i = 0; i < boids.length; i++) {
      final boid = boids[i];
      var sepX = 0.0, sepY = 0.0;
      var alignX = 0.0, alignY = 0.0;
      var cohX = 0.0, cohY = 0.0;
      var neighbors = 0;

      for (var j = 0; j < boids.length; j++) {
        if (i == j) continue;
        final other = boids[j];
        final dx = boid.x - other.x;
        final dy = boid.y - other.y;
        final dist = sqrt(dx * dx + dy * dy);

        if (dist < protectedRange) {
          // Separation
          sepX += dx;
          sepY += dy;
        }

        if (dist < visualRange) {
          // Alignment
          alignX += other.vx;
          alignY += other.vy;
          // Cohesion
          cohX += other.x;
          cohY += other.y;
          neighbors++;
        }
      }

      // Apply separation
      boid.vx += sepX * 0.05 * _separation;
      boid.vy += sepY * 0.05 * _separation;

      if (neighbors > 0) {
        // Apply alignment
        alignX /= neighbors;
        alignY /= neighbors;
        boid.vx += (alignX - boid.vx) * 0.05 * _alignment;
        boid.vy += (alignY - boid.vy) * 0.05 * _alignment;

        // Apply cohesion
        cohX /= neighbors;
        cohY /= neighbors;
        boid.vx += (cohX - boid.x) * 0.005 * _cohesion;
        boid.vy += (cohY - boid.y) * 0.005 * _cohesion;
      }

      // Edge avoidance (soft turn)
      if (boid.x < margin) boid.vx += turnFactor;
      if (boid.x > w - margin) boid.vx -= turnFactor;
      if (boid.y < margin) boid.vy += turnFactor;
      if (boid.y > h - margin) boid.vy -= turnFactor;

      // Clamp speed
      final speed = sqrt(boid.vx * boid.vx + boid.vy * boid.vy);
      if (speed > maxSpeed) {
        boid.vx = (boid.vx / speed) * maxSpeed;
        boid.vy = (boid.vy / speed) * maxSpeed;
      } else if (speed < minSpeed) {
        boid.vx = (boid.vx / speed) * minSpeed;
        boid.vy = (boid.vy / speed) * minSpeed;
      }

      // Update position
      boid.x += boid.vx;
      boid.y += boid.vy;
    }

    return _stateFromBoids(boids, s.step + 1, w, h);
  }

  BoidsState _stateFromBoids(
      List<_Boid> boids, int step, double w, double h) {
    return BoidsState(
      boids: boids.map((b) => (b.x, b.y, b.vx, b.vy)).toList(),
      step: step,
      width: w,
      height: h,
      description: 'Step $step: ${boids.length} boids',
    );
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) {
    return _BoidsPainter(
      state: state as BoidsState,
      brightness: Theme.of(context).brightness,
    );
  }

  @override
  Widget? buildControls({required VoidCallback onChanged}) {
    return _Controls(
      count: _count,
      separation: _separation,
      alignment: _alignment,
      cohesion: _cohesion,
      onChanged: (count, sep, ali, coh) {
        _count = count;
        _separation = sep;
        _alignment = ali;
        _cohesion = coh;
        onChanged();
      },
    );
  }
}

class _BoidsPainter extends CustomPainter {
  _BoidsPainter({required this.state, required this.brightness});

  final BoidsState state;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final isDark = brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5);
    final boidColor = isDark ? const Color(0xFF42A5F5) : const Color(0xFF1976D2);

    canvas.drawRect(Offset.zero & size, Paint()..color = bgColor);

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color = isDark ? Colors.white12 : Colors.black12
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );

    for (final (x, y, vx, vy) in state.boids) {
      final px = x * size.width;
      final py = y * size.height;
      final angle = atan2(vy, vx);

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(angle);

      // Triangle pointing in direction of movement
      final path = Path()
        ..moveTo(6, 0)
        ..lineTo(-4, -3)
        ..lineTo(-4, 3)
        ..close();

      canvas.drawPath(path, Paint()..color = boidColor);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _BoidsPainter oldDelegate) {
    return oldDelegate.state != state;
  }
}

class _Controls extends StatefulWidget {
  const _Controls({
    required this.count,
    required this.separation,
    required this.alignment,
    required this.cohesion,
    required this.onChanged,
  });

  final int count;
  final double separation;
  final double alignment;
  final double cohesion;
  final void Function(int count, double sep, double ali, double coh) onChanged;

  @override
  State<_Controls> createState() => _ControlsState();
}

class _ControlsState extends State<_Controls> {
  late double _count;
  late double _sep;
  late double _ali;
  late double _coh;

  @override
  void initState() {
    super.initState();
    _count = widget.count.toDouble();
    _sep = widget.separation;
    _ali = widget.alignment;
    _coh = widget.cohesion;
  }

  void _emit() {
    widget.onChanged(_count.round(), _sep, _ali, _coh);
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodySmall;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text('Boids: ${_count.round()}', style: textStyle),
            Expanded(
              child: Slider(
                value: _count, min: 10, max: 200, divisions: 19,
                onChanged: (v) => setState(() => _count = v),
                onChangeEnd: (_) => _emit(),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Text('Sep: ${_sep.toStringAsFixed(1)}', style: textStyle),
            Expanded(
              child: Slider(
                value: _sep, min: 0, max: 3, divisions: 30,
                onChanged: (v) => setState(() => _sep = v),
                onChangeEnd: (_) => _emit(),
              ),
            ),
            Text('Ali: ${_ali.toStringAsFixed(1)}', style: textStyle),
            Expanded(
              child: Slider(
                value: _ali, min: 0, max: 3, divisions: 30,
                onChanged: (v) => setState(() => _ali = v),
                onChangeEnd: (_) => _emit(),
              ),
            ),
            Text('Coh: ${_coh.toStringAsFixed(1)}', style: textStyle),
            Expanded(
              child: Slider(
                value: _coh, min: 0, max: 3, divisions: 30,
                onChanged: (v) => setState(() => _coh = v),
                onChangeEnd: (_) => _emit(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
