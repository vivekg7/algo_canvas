import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';

class MonteCarloPiState extends AlgorithmState {
  const MonteCarloPiState({
    required this.points,
    required this.insideCount,
    required this.totalCount,
    required this.piEstimate,
    required super.description,
  });

  /// List of (x, y, inside) — normalized 0..1.
  final List<(double, double, bool)> points;
  final int insideCount;
  final int totalCount;
  final double piEstimate;
}

class MonteCarloPiAlgorithm extends Algorithm {
  int _totalPoints = 5000;
  final int _pointsPerStep = 20;

  @override
  String get name => 'Monte Carlo Pi';

  @override
  String get description =>
      'Estimate π by randomly sampling points inside a unit square.';

  @override
  AlgorithmCategory get category => AlgorithmCategory.mathSignal;

  @override
  AlgorithmMode get mode => AlgorithmMode.live;

  @override
  AlgorithmState createInitialState() {
    return const MonteCarloPiState(
      points: [],
      insideCount: 0,
      totalCount: 0,
      piEstimate: 0,
      description: 'Estimating π using random sampling',
    );
  }

  @override
  AlgorithmState? tick(AlgorithmState current) {
    final s = current as MonteCarloPiState;
    if (s.totalCount >= _totalPoints) return null;

    final random = Random();
    final newPoints = List<(double, double, bool)>.of(s.points);
    var inside = s.insideCount;
    var total = s.totalCount;

    final batch = min(_pointsPerStep, _totalPoints - total);
    for (var i = 0; i < batch; i++) {
      final x = random.nextDouble();
      final y = random.nextDouble();
      // Check if inside unit circle centered at (0.5, 0.5) with radius 0.5
      final dx = x - 0.5;
      final dy = y - 0.5;
      final isInside = dx * dx + dy * dy <= 0.25;
      newPoints.add((x, y, isInside));
      if (isInside) inside++;
      total++;
    }

    final piEst = total > 0 ? 4.0 * inside / total : 0.0;

    return MonteCarloPiState(
      points: newPoints,
      insideCount: inside,
      totalCount: total,
      piEstimate: piEst,
      description:
          'π ≈ ${piEst.toStringAsFixed(6)} ($total points, error: ${(piEst - pi).abs().toStringAsFixed(6)})',
    );
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) {
    return _MonteCarloPiPainter(
      state: state as MonteCarloPiState,
      brightness: Theme.of(context).brightness,
    );
  }

  @override
  Widget? buildControls({required VoidCallback onChanged}) {
    return _Controls(
      totalPoints: _totalPoints,
      onChanged: (total) {
        _totalPoints = total;
        onChanged();
      },
    );
  }
}

class _MonteCarloPiPainter extends CustomPainter {
  _MonteCarloPiPainter({required this.state, required this.brightness});

  final MonteCarloPiState state;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final isDark = brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5);
    final insideColor = isDark ? const Color(0xFF42A5F5) : const Color(0xFF1976D2);
    final outsideColor = isDark
        ? const Color(0xFFEF5350).withValues(alpha: 0.5)
        : const Color(0xFFD32F2F).withValues(alpha: 0.4);
    final circleColor = isDark ? Colors.white24 : Colors.black26;

    final squareSize = size.shortestSide * 0.75;
    final offsetX = (size.width - squareSize) / 2;
    final offsetY = 16.0;

    // Square
    final squareRect = Rect.fromLTWH(offsetX, offsetY, squareSize, squareSize);
    canvas.drawRect(squareRect, Paint()..color = bgColor);
    canvas.drawRect(
      squareRect,
      Paint()
        ..color = isDark ? Colors.white24 : Colors.black26
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Circle
    canvas.drawCircle(
      Offset(offsetX + squareSize / 2, offsetY + squareSize / 2),
      squareSize / 2,
      Paint()
        ..color = circleColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Points
    for (final (x, y, inside) in state.points) {
      canvas.drawCircle(
        Offset(offsetX + x * squareSize, offsetY + y * squareSize),
        1.2,
        Paint()..color = inside ? insideColor : outsideColor,
      );
    }

    // Pi estimate text below
    if (state.totalCount > 0) {
      final piText = TextPainter(
        text: TextSpan(
          children: [
            TextSpan(
              text: 'π ≈ ${state.piEstimate.toStringAsFixed(6)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            TextSpan(
              text: '  (actual: ${pi.toStringAsFixed(6)})',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ],
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      piText.paint(
        canvas,
        Offset(
          (size.width - piText.width) / 2,
          offsetY + squareSize + 16,
        ),
      );

      final countText = TextPainter(
        text: TextSpan(
          text:
              '${state.insideCount} inside / ${state.totalCount} total',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      countText.paint(
        canvas,
        Offset(
          (size.width - countText.width) / 2,
          offsetY + squareSize + 42,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MonteCarloPiPainter oldDelegate) {
    return oldDelegate.state != state;
  }
}

class _Controls extends StatefulWidget {
  const _Controls({required this.totalPoints, required this.onChanged});
  final int totalPoints;
  final ValueChanged<int> onChanged;

  @override
  State<_Controls> createState() => _ControlsState();
}

class _ControlsState extends State<_Controls> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.totalPoints.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('Points: ${_value.round()}',
            style: Theme.of(context).textTheme.bodySmall),
        Expanded(
          child: Slider(
            value: _value, min: 500, max: 20000, divisions: 39,
            onChanged: (v) => setState(() => _value = v),
            onChangeEnd: (v) => widget.onChanged(v.round()),
          ),
        ),
      ],
    );
  }
}
