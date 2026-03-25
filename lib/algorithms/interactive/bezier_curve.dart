import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';

class BezierState extends AlgorithmState {
  const BezierState({
    required this.controlPoints,
    this.draggingIndex,
    required super.description,
  });

  /// Control points in normalized 0..1 coordinates.
  final List<Offset> controlPoints;
  final int? draggingIndex;
}

class BezierCurveAlgorithm extends Algorithm {
  @override String get name => 'Bezier Curve';
  @override String get description => 'Drag control points to shape the curve. Tap empty space to add points.';
  @override AlgorithmCategory get category => AlgorithmCategory.computationalGeometry;
  @override AlgorithmMode get mode => AlgorithmMode.interactive;

  @override
  AlgorithmState createInitialState() {
    return const BezierState(
      controlPoints: [
        Offset(0.15, 0.7),
        Offset(0.35, 0.15),
        Offset(0.65, 0.15),
        Offset(0.85, 0.7),
      ],
      description: 'Drag control points to shape the curve',
    );
  }

  @override
  AlgorithmState? onInteractionStart(AlgorithmState current, Offset localPosition) {
    final s = current as BezierState;
    const hitRadius = 0.04;

    // Check if touching an existing control point
    for (var i = 0; i < s.controlPoints.length; i++) {
      final cp = s.controlPoints[i];
      final dx = cp.dx - localPosition.dx;
      final dy = cp.dy - localPosition.dy;
      if (sqrt(dx * dx + dy * dy) < hitRadius) {
        return BezierState(
          controlPoints: s.controlPoints,
          draggingIndex: i,
          description: 'Dragging point ${i + 1}',
        );
      }
    }

    // Add a new control point
    final newPoints = [...s.controlPoints, localPosition];
    return BezierState(
      controlPoints: newPoints,
      draggingIndex: newPoints.length - 1,
      description: '${newPoints.length} control points — order ${newPoints.length - 1} Bezier',
    );
  }

  @override
  AlgorithmState? onInteractionUpdate(AlgorithmState current, Offset localPosition) {
    final s = current as BezierState;
    if (s.draggingIndex == null) return null;

    final newPoints = List<Offset>.of(s.controlPoints);
    newPoints[s.draggingIndex!] = localPosition;
    return BezierState(
      controlPoints: newPoints,
      draggingIndex: s.draggingIndex,
      description: '${newPoints.length} control points — order ${newPoints.length - 1} Bezier',
    );
  }

  @override
  AlgorithmState? onInteractionEnd(AlgorithmState current) {
    final s = current as BezierState;
    return BezierState(
      controlPoints: s.controlPoints,
      description: '${s.controlPoints.length} control points — drag to reshape',
    );
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) =>
      _BezierPainter(state: state as BezierState, brightness: Theme.of(context).brightness);
}

class _BezierPainter extends CustomPainter {
  _BezierPainter({required this.state, required this.brightness});
  final BezierState state;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final isDark = brightness == Brightness.dark;
    final curveColor = isDark ? const Color(0xFF42A5F5) : const Color(0xFF1976D2);
    final controlLineColor = isDark ? Colors.white24 : Colors.black26;
    final pointColor = isDark ? const Color(0xFFFFCA28) : const Color(0xFFF9A825);
    final draggingColor = isDark ? const Color(0xFFEF5350) : const Color(0xFFD32F2F);

    final pts = state.controlPoints;
    if (pts.isEmpty) return;

    // Draw control polygon
    if (pts.length > 1) {
      for (var i = 0; i < pts.length - 1; i++) {
        canvas.drawLine(
          Offset(pts[i].dx * size.width, pts[i].dy * size.height),
          Offset(pts[i + 1].dx * size.width, pts[i + 1].dy * size.height),
          Paint()
            ..color = controlLineColor
            ..strokeWidth = 1
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    // Draw Bezier curve using De Casteljau
    if (pts.length >= 2) {
      final steps = max(100, pts.length * 30);
      final path = Path();
      final first = _deCasteljau(pts, 0);
      path.moveTo(first.dx * size.width, first.dy * size.height);

      for (var i = 1; i <= steps; i++) {
        final t = i / steps;
        final p = _deCasteljau(pts, t);
        path.lineTo(p.dx * size.width, p.dy * size.height);
      }

      canvas.drawPath(path, Paint()
        ..color = curveColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round);
    }

    // Draw control points
    for (var i = 0; i < pts.length; i++) {
      final p = Offset(pts[i].dx * size.width, pts[i].dy * size.height);
      final isDragging = state.draggingIndex == i;
      final radius = isDragging ? 10.0 : 7.0;

      canvas.drawCircle(p, radius, Paint()..color = isDragging ? draggingColor : pointColor);
      canvas.drawCircle(p, radius, Paint()
        ..color = isDark ? Colors.white30 : Colors.black26
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5);

      // Label
      final tp = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: TextStyle(fontSize: 9, color: isDark ? Colors.black : Colors.white, fontWeight: FontWeight.w700),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
    }
  }

  /// De Casteljau's algorithm for arbitrary-order Bezier curve.
  Offset _deCasteljau(List<Offset> points, double t) {
    var current = List<Offset>.of(points);
    while (current.length > 1) {
      final next = <Offset>[];
      for (var i = 0; i < current.length - 1; i++) {
        next.add(Offset(
          current[i].dx * (1 - t) + current[i + 1].dx * t,
          current[i].dy * (1 - t) + current[i + 1].dy * t,
        ));
      }
      current = next;
    }
    return current[0];
  }

  @override bool shouldRepaint(covariant _BezierPainter old) => !identical(old.state, state);
}
