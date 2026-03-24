import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';
import 'package:algo_canvas/algorithms/geometry/geometry_state.dart';
import 'package:algo_canvas/algorithms/geometry/geometry_painter.dart';
import 'package:algo_canvas/algorithms/geometry/geometry_legend.dart';
import 'package:algo_canvas/widgets/color_legend.dart';

class ConvexHullJarvisAlgorithm extends Algorithm {
  int _pointCount = 20;

  @override
  String get name => 'Convex Hull (Jarvis)';
  @override
  String get description => 'Gift wrapping: pick leftmost, then wrap around choosing most counter-clockwise. O(nh).';
  @override
  AlgorithmCategory get category => AlgorithmCategory.computationalGeometry;

  @override
  Future<List<AlgorithmState>> generate() async {
    final random = Random();
    final points = List.generate(_pointCount, (_) =>
        GeoPoint(0.05 + random.nextDouble() * 0.9, 0.05 + random.nextDouble() * 0.9));
    final states = <GeometryState>[];
    final hull = <int>[];
    final hullLines = <GeoLine>[];

    states.add(GeometryState(points: List.of(points), description: 'Jarvis March: ${points.length} points'));

    // Find leftmost
    var leftmost = 0;
    for (var i = 1; i < points.length; i++) {
      if (points[i].x < points[leftmost].x) { leftmost = i; }
    }

    var current = leftmost;
    do {
      hull.add(current);
      points[current] = points[current].copyWith(status: PointStatus.hull);

      var next = 0;
      for (var i = 0; i < points.length; i++) {
        if (i == current) { continue; }

        final pts = List.of(points);
        pts[i] = pts[i].copyWith(status: PointStatus.active);
        final testLines = List.of(hullLines);
        testLines.add(GeoLine(current, i, status: LineStatus.testing));

        states.add(GeometryState(points: pts, lines: testLines,
          description: 'From $current: testing point $i'));

        if (next == current || _cross(points[current], points[next], points[i]) < 0) {
          next = i;
        }
      }

      hullLines.add(GeoLine(current, next, status: LineStatus.accepted));
      states.add(GeometryState(points: List.of(points), lines: List.of(hullLines),
        description: 'Edge: $current → $next'));

      current = next;
    } while (current != leftmost);

    // Close hull
    states.add(GeometryState(
      points: List.of(points), lines: hullLines, polygons: [hull],
      description: 'Convex hull: ${hull.length} vertices'));

    return states;
  }

  double _cross(GeoPoint o, GeoPoint a, GeoPoint b) =>
      (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x);

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) =>
      GeometryPainter(state: state as GeometryState, brightness: Theme.of(context).brightness);

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
    Expanded(child: Slider(value: _v, min: 8, max: 30, divisions: 22,
      onChanged: (v) => setState(() => _v = v), onChangeEnd: (v) => widget.onChanged(v.round()))),
  ]);
}
