import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';

class InteractiveHullState extends AlgorithmState {
  const InteractiveHullState({
    required this.points,
    required this.hullIndices,
    required super.description,
  });
  final List<Offset> points;
  final List<int> hullIndices;
}

class InteractiveConvexHullAlgorithm extends Algorithm {
  @override String get name => 'Interactive Convex Hull';
  @override String get description => 'Tap to add points. Hull updates instantly.';
  @override AlgorithmCategory get category => AlgorithmCategory.computationalGeometry;
  @override AlgorithmMode get mode => AlgorithmMode.interactive;

  @override
  AlgorithmState createInitialState() {
    return const InteractiveHullState(
      points: [], hullIndices: [],
      description: 'Tap to add points',
    );
  }

  @override
  AlgorithmState? onInteractionStart(AlgorithmState current, Offset localPosition) {
    final s = current as InteractiveHullState;
    final pts = [...s.points, localPosition];
    final hull = _computeHull(pts);
    return InteractiveHullState(points: pts, hullIndices: hull,
      description: '${pts.length} points, ${hull.length} on hull');
  }

  List<int> _computeHull(List<Offset> points) {
    final n = points.length;
    if (n < 3) return List.generate(n, (i) => i);

    // Graham Scan
    var lowest = 0;
    for (var i = 1; i < n; i++) {
      if (points[i].dy > points[lowest].dy ||
          (points[i].dy == points[lowest].dy && points[i].dx < points[lowest].dx)) {
        lowest = i;
      }
    }

    final indices = List.generate(n, (i) => i);
    final pivot = points[lowest];
    indices.sort((a, b) {
      final angleA = atan2(points[a].dy - pivot.dy, points[a].dx - pivot.dx);
      final angleB = atan2(points[b].dy - pivot.dy, points[b].dx - pivot.dx);
      final cmp = angleA.compareTo(angleB);
      if (cmp != 0) return cmp;
      final distA = (points[a] - pivot).distance;
      final distB = (points[b] - pivot).distance;
      return distA.compareTo(distB);
    });

    final stack = <int>[indices[0], indices[1]];
    for (var i = 2; i < n; i++) {
      while (stack.length > 1) {
        final top = stack[stack.length - 1];
        final next = stack[stack.length - 2];
        final cross = _cross(points[next], points[top], points[indices[i]]);
        if (cross <= 0) { stack.removeLast(); } else { break; }
      }
      stack.add(indices[i]);
    }
    return stack;
  }

  double _cross(Offset o, Offset a, Offset b) =>
      (a.dx - o.dx) * (b.dy - o.dy) - (a.dy - o.dy) * (b.dx - o.dx);

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) =>
      _HullPainter(state: state as InteractiveHullState, brightness: Theme.of(context).brightness);
}

class _HullPainter extends CustomPainter {
  _HullPainter({required this.state, required this.brightness});
  final InteractiveHullState state;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final isDark = brightness == Brightness.dark;
    final ptColor = isDark ? const Color(0xFF90A4AE) : const Color(0xFF607D8B);
    final hullColor = isDark ? const Color(0xFF4CAF50) : const Color(0xFF388E3C);
    final fillColor = hullColor.withValues(alpha: 0.1);

    final pts = state.points;
    final hull = state.hullIndices;

    // Hull fill and edges
    if (hull.length >= 3) {
      final path = Path();
      path.moveTo(pts[hull[0]].dx * size.width, pts[hull[0]].dy * size.height);
      for (var i = 1; i < hull.length; i++) {
        path.lineTo(pts[hull[i]].dx * size.width, pts[hull[i]].dy * size.height);
      }
      path.close();
      canvas.drawPath(path, Paint()..color = fillColor);
      canvas.drawPath(path, Paint()..color = hullColor..style = PaintingStyle.stroke..strokeWidth = 2);
    } else if (hull.length == 2) {
      canvas.drawLine(
        Offset(pts[hull[0]].dx * size.width, pts[hull[0]].dy * size.height),
        Offset(pts[hull[1]].dx * size.width, pts[hull[1]].dy * size.height),
        Paint()..color = hullColor..strokeWidth = 2);
    }

    // Points
    final hullSet = hull.toSet();
    for (var i = 0; i < pts.length; i++) {
      final p = Offset(pts[i].dx * size.width, pts[i].dy * size.height);
      final isHull = hullSet.contains(i);
      canvas.drawCircle(p, isHull ? 6 : 4, Paint()..color = isHull ? hullColor : ptColor);
    }
  }

  @override bool shouldRepaint(covariant _HullPainter old) => !identical(old.state, state);
}
