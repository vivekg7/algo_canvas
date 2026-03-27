import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';
import 'package:algo_canvas/algorithms/geometry/geometry_state.dart';
import 'package:algo_canvas/algorithms/geometry/geometry_painter.dart';
import 'package:algo_canvas/algorithms/geometry/geometry_legend.dart';
import 'package:algo_canvas/widgets/color_legend.dart';

class ConvexHullGrahamAlgorithm extends Algorithm {
  int _pointCount = 20;

  @override
  String get name => 'Convex Hull (Graham)';
  @override
  String get description => 'Graham Scan: sort by angle, then scan with left-turn test. O(n log n).';
  @override
  AlgorithmCategory get category => AlgorithmCategory.computationalGeometry;

  @override
  Future<List<AlgorithmState>> generate() async {
    final random = Random();
    var points = List.generate(_pointCount, (_) =>
        GeoPoint(0.05 + random.nextDouble() * 0.9, 0.05 + random.nextDouble() * 0.9));
    final states = <GeometryState>[];

    states.add(GeometryState(points: List.of(points), description: 'Graham Scan: ${points.length} points'));

    // Find lowest point (highest y since y increases downward)
    var lowest = 0;
    for (var i = 1; i < points.length; i++) {
      if (points[i].y > points[lowest].y || (points[i].y == points[lowest].y && points[i].x < points[lowest].x)) {
        lowest = i;
      }
    }

    // Move to front
    final temp = points[0];
    points[0] = points[lowest];
    points[lowest] = temp;
    points[0] = points[0].copyWith(status: PointStatus.active);

    states.add(GeometryState(points: List.of(points), description: 'Pivot: lowest point'));

    // Sort by polar angle
    final pivot = points[0];
    final sorted = points.sublist(1);
    sorted.sort((a, b) {
      final angleA = atan2(a.y - pivot.y, a.x - pivot.x);
      final angleB = atan2(b.y - pivot.y, b.x - pivot.x);
      return angleA.compareTo(angleB);
    });
    points = [pivot, ...sorted];

    states.add(GeometryState(points: List.of(points), description: 'Points sorted by polar angle'));

    // Graham scan
    final stack = <int>[0, 1];

    for (var i = 2; i < points.length; i++) {
      // Test turn
      while (stack.length > 1) {
        final top = stack[stack.length - 1];
        final nextToTop = stack[stack.length - 2];

        final lines = <GeoLine>[];
        for (var j = 0; j < stack.length - 1; j++) {
          lines.add(GeoLine(stack[j], stack[j + 1], status: LineStatus.accepted));
        }
        lines.add(GeoLine(top, i, status: LineStatus.testing));

        final pts = List.of(points);
        pts[i] = pts[i].copyWith(status: PointStatus.active);
        pts[top] = pts[top].copyWith(status: PointStatus.active);

        states.add(GeometryState(points: pts, lines: lines,
          description: 'Testing turn at point $top with point $i'));

        final cross = _crossProduct(points[nextToTop], points[top], points[i]);
        if (cross <= 0) {
          // Right turn or collinear — remove top
          points[top] = points[top].copyWith(status: PointStatus.rejected);
          stack.removeLast();
          states.add(GeometryState(points: List.of(points),
            lines: [for (var j = 0; j < stack.length - 1; j++) GeoLine(stack[j], stack[j + 1], status: LineStatus.accepted)],
            description: 'Right turn — removed point $top'));
        } else {
          break;
        }
      }
      stack.add(i);
      points[i] = points[i].copyWith(status: PointStatus.hull);
    }

    // Final hull
    final hullLines = <GeoLine>[];
    for (var i = 0; i < stack.length; i++) {
      hullLines.add(GeoLine(stack[i], stack[(i + 1) % stack.length], status: LineStatus.accepted));
      points[stack[i]] = points[stack[i]].copyWith(status: PointStatus.hull);
    }

    states.add(GeometryState(
      points: List.of(points), lines: hullLines, polygons: [stack],
      description: 'Convex hull: ${stack.length} vertices'));

    return states;
  }

  double _crossProduct(GeoPoint o, GeoPoint a, GeoPoint b) =>
      (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x);

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) =>
      GeometryPainter(state: state as GeometryState, colorScheme: Theme.of(context).colorScheme);

  @override
  List<LegendItem>? buildLegend(BuildContext context) => geometryLegend(context);

  @override
  Widget? buildControls({required VoidCallback onChanged}) =>
      _Ctrl(count: _pointCount, onChanged: (v) { _pointCount = v; onChanged(); });
}

class _Ctrl extends StatefulWidget {
  const _Ctrl({required this.count, required this.onChanged});
  final int count; final ValueChanged<int> onChanged;
  @override State<_Ctrl> createState() => _CtrlState();
}
class _CtrlState extends State<_Ctrl> {
  late double _v;
  @override void initState() { super.initState(); _v = widget.count.toDouble(); }
  @override Widget build(BuildContext context) => Row(children: [
    Text('Points: ${_v.round()}', style: Theme.of(context).textTheme.bodySmall),
    Expanded(child: Slider(value: _v, min: 8, max: 50, divisions: 42,
      onChanged: (v) => setState(() => _v = v), onChangeEnd: (v) => widget.onChanged(v.round()))),
  ]);
}
