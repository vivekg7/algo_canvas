import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';

class BSplineState extends AlgorithmState {
  const BSplineState({
    required this.controlPoints,
    this.draggingIndex,
    required this.degree,
    required super.description,
  });
  final List<Offset> controlPoints;
  final int? draggingIndex;
  final int degree;
}

class BSplineAlgorithm extends Algorithm {
  @override String get name => 'B-Spline Curve';
  @override String get description => 'Drag control points. The curve follows but does not interpolate them.';
  @override AlgorithmCategory get category => AlgorithmCategory.computationalGeometry;
  @override AlgorithmMode get mode => AlgorithmMode.interactive;

  @override
  AlgorithmState createInitialState() {
    return const BSplineState(
      controlPoints: [
        Offset(0.1, 0.5), Offset(0.25, 0.15), Offset(0.4, 0.8),
        Offset(0.55, 0.2), Offset(0.7, 0.75), Offset(0.9, 0.4),
      ],
      degree: 3,
      description: 'Drag points to reshape. Tap to add.',
    );
  }

  @override
  AlgorithmState? onInteractionStart(AlgorithmState current, Offset localPosition) {
    final s = current as BSplineState;
    for (var i = 0; i < s.controlPoints.length; i++) {
      if ((s.controlPoints[i] - localPosition).distance < 0.04) {
        return BSplineState(controlPoints: s.controlPoints, draggingIndex: i, degree: s.degree,
          description: 'Dragging point ${i + 1}');
      }
    }
    final pts = [...s.controlPoints, localPosition];
    return BSplineState(controlPoints: pts, draggingIndex: pts.length - 1, degree: s.degree,
      description: '${pts.length} control points');
  }

  @override
  AlgorithmState? onInteractionUpdate(AlgorithmState current, Offset localPosition) {
    final s = current as BSplineState;
    if (s.draggingIndex == null) return null;
    final pts = List<Offset>.of(s.controlPoints);
    pts[s.draggingIndex!] = localPosition;
    return BSplineState(controlPoints: pts, draggingIndex: s.draggingIndex, degree: s.degree,
      description: '${pts.length} control points');
  }

  @override
  AlgorithmState? onInteractionEnd(AlgorithmState current) {
    final s = current as BSplineState;
    return BSplineState(controlPoints: s.controlPoints, degree: s.degree,
      description: '${s.controlPoints.length} control points — drag to reshape');
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) =>
      _BSplinePainter(state: state as BSplineState, brightness: Theme.of(context).brightness);
}

class _BSplinePainter extends CustomPainter {
  _BSplinePainter({required this.state, required this.brightness});
  final BSplineState state;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final isDark = brightness == Brightness.dark;
    final pts = state.controlPoints;
    if (pts.isEmpty) return;

    final curveColor = isDark ? const Color(0xFFEF5350) : const Color(0xFFD32F2F);
    final lineColor = isDark ? Colors.white24 : Colors.black26;
    final ptColor = isDark ? const Color(0xFFFFCA28) : const Color(0xFFF9A825);
    final dragColor = isDark ? const Color(0xFF42A5F5) : const Color(0xFF1976D2);

    // Control polygon
    for (var i = 0; i < pts.length - 1; i++) {
      canvas.drawLine(
        Offset(pts[i].dx * size.width, pts[i].dy * size.height),
        Offset(pts[i + 1].dx * size.width, pts[i + 1].dy * size.height),
        Paint()..color = lineColor..strokeWidth = 1);
    }

    // B-spline curve
    if (pts.length > state.degree) {
      final path = Path();
      final steps = max(200, pts.length * 30);
      var first = true;
      for (var i = 0; i <= steps; i++) {
        final t = i / steps;
        final p = _evaluate(pts, state.degree, t);
        if (first) { path.moveTo(p.dx * size.width, p.dy * size.height); first = false; }
        else { path.lineTo(p.dx * size.width, p.dy * size.height); }
      }
      canvas.drawPath(path, Paint()..color = curveColor..style = PaintingStyle.stroke..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
    }

    // Points
    for (var i = 0; i < pts.length; i++) {
      final p = Offset(pts[i].dx * size.width, pts[i].dy * size.height);
      canvas.drawCircle(p, state.draggingIndex == i ? 9.0 : 6.0,
        Paint()..color = state.draggingIndex == i ? dragColor : ptColor);
    }
  }

  Offset _evaluate(List<Offset> pts, int degree, double t) {
    final n = pts.length;
    final k = degree + 1;
    // Uniform knot vector
    final m = n + k;
    final knots = List<double>.generate(m, (i) => i.toDouble());
    // Map t to knot range [degree, n]
    final tMapped = degree + t * (n - degree);

    // De Boor's algorithm
    var d = List<Offset>.of(pts);
    for (var r = 1; r < k; r++) {
      final newD = <Offset>[];
      for (var i = r; i < n; i++) {
        final denom = knots[i + k - r] - knots[i];
        if (denom.abs() < 1e-10) { newD.add(d[i - r]); continue; }
        final alpha = (tMapped - knots[i]) / denom;
        newD.add(Offset(
          d[i - 1].dx * (1 - alpha) + d[i].dx * alpha,
          d[i - 1].dy * (1 - alpha) + d[i].dy * alpha,
        ));
      }
      d = [for (var i = 0; i < r; i++) d[i], ...newD];
    }

    // Find the relevant point
    final span = tMapped.floor().clamp(degree, n - 1);
    return d[span];
  }

  @override bool shouldRepaint(covariant _BSplinePainter old) => !identical(old.state, state);
}
