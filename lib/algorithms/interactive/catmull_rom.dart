import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';

class CatmullRomState extends AlgorithmState {
  const CatmullRomState({
    required this.controlPoints,
    this.draggingIndex,
    required super.description,
  });
  final List<Offset> controlPoints;
  final int? draggingIndex;
}

class CatmullRomAlgorithm extends Algorithm {
  @override String get name => 'Catmull-Rom Spline';
  @override String get description => 'Interpolating spline: the curve passes through every control point.';
  @override AlgorithmCategory get category => AlgorithmCategory.computationalGeometry;
  @override AlgorithmMode get mode => AlgorithmMode.interactive;

  @override
  AlgorithmState createInitialState() {
    return const CatmullRomState(
      controlPoints: [
        Offset(0.1, 0.5), Offset(0.3, 0.15), Offset(0.5, 0.7),
        Offset(0.7, 0.25), Offset(0.9, 0.6),
      ],
      description: 'Drag points. Curve passes through all of them.',
    );
  }

  @override
  AlgorithmState? onInteractionStart(AlgorithmState current, Offset localPosition) {
    final s = current as CatmullRomState;
    for (var i = 0; i < s.controlPoints.length; i++) {
      if ((s.controlPoints[i] - localPosition).distance < 0.04) {
        return CatmullRomState(controlPoints: s.controlPoints, draggingIndex: i,
          description: 'Dragging point ${i + 1}');
      }
    }
    final pts = [...s.controlPoints, localPosition];
    return CatmullRomState(controlPoints: pts, draggingIndex: pts.length - 1,
      description: '${pts.length} points');
  }

  @override
  AlgorithmState? onInteractionUpdate(AlgorithmState current, Offset localPosition) {
    final s = current as CatmullRomState;
    if (s.draggingIndex == null) return null;
    final pts = List<Offset>.of(s.controlPoints);
    pts[s.draggingIndex!] = localPosition;
    return CatmullRomState(controlPoints: pts, draggingIndex: s.draggingIndex,
      description: '${pts.length} points');
  }

  @override
  AlgorithmState? onInteractionEnd(AlgorithmState current) {
    final s = current as CatmullRomState;
    return CatmullRomState(controlPoints: s.controlPoints,
      description: '${s.controlPoints.length} points — curve interpolates all');
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) =>
      _CatmullRomPainter(state: state as CatmullRomState, brightness: Theme.of(context).brightness);
}

class _CatmullRomPainter extends CustomPainter {
  _CatmullRomPainter({required this.state, required this.brightness});
  final CatmullRomState state;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final isDark = brightness == Brightness.dark;
    final pts = state.controlPoints;
    if (pts.isEmpty) return;

    final curveColor = isDark ? const Color(0xFF66BB6A) : const Color(0xFF388E3C);
    final ptColor = isDark ? const Color(0xFFFFCA28) : const Color(0xFFF9A825);
    final dragColor = isDark ? const Color(0xFFEF5350) : const Color(0xFFD32F2F);
    final lineColor = isDark ? Colors.white12 : Colors.black12;

    // Light control polygon
    for (var i = 0; i < pts.length - 1; i++) {
      canvas.drawLine(
        Offset(pts[i].dx * size.width, pts[i].dy * size.height),
        Offset(pts[i + 1].dx * size.width, pts[i + 1].dy * size.height),
        Paint()..color = lineColor..strokeWidth = 1);
    }

    // Catmull-Rom segments
    if (pts.length >= 2) {
      final path = Path();
      // Extend with phantom points
      final extended = [
        pts[0] * 2 - pts[min(1, pts.length - 1)],
        ...pts,
        pts[pts.length - 1] * 2 - pts[max(0, pts.length - 2)],
      ];

      var first = true;
      for (var i = 0; i < extended.length - 3; i++) {
        final p0 = extended[i], p1 = extended[i + 1], p2 = extended[i + 2], p3 = extended[i + 3];
        for (var t = 0; t <= 30; t++) {
          final s = t / 30.0;
          final p = _catmullRom(p0, p1, p2, p3, s);
          if (first) { path.moveTo(p.dx * size.width, p.dy * size.height); first = false; }
          else { path.lineTo(p.dx * size.width, p.dy * size.height); }
        }
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

  Offset _catmullRom(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
    final t2 = t * t, t3 = t2 * t;
    return Offset(
      0.5 * ((2 * p1.dx) + (-p0.dx + p2.dx) * t + (2 * p0.dx - 5 * p1.dx + 4 * p2.dx - p3.dx) * t2 + (-p0.dx + 3 * p1.dx - 3 * p2.dx + p3.dx) * t3),
      0.5 * ((2 * p1.dy) + (-p0.dy + p2.dy) * t + (2 * p0.dy - 5 * p1.dy + 4 * p2.dy - p3.dy) * t2 + (-p0.dy + 3 * p1.dy - 3 * p2.dy + p3.dy) * t3),
    );
  }

  @override bool shouldRepaint(covariant _CatmullRomPainter old) => !identical(old.state, state);
}

