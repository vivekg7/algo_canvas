import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';
import 'package:algo_canvas/algorithms/geometry/geometry_state.dart';
import 'package:algo_canvas/algorithms/geometry/geometry_painter.dart';
import 'package:algo_canvas/algorithms/geometry/geometry_legend.dart';
import 'package:algo_canvas/widgets/color_legend.dart';

class LineIntersectionAlgorithm extends Algorithm {
  int _segmentCount = 10;

  @override
  String get name => 'Line Intersection';
  @override
  String get description => 'Brute-force check all segment pairs for intersections. O(n²).';
  @override
  AlgorithmCategory get category => AlgorithmCategory.computationalGeometry;

  @override
  Future<List<AlgorithmState>> generate() async {
    final random = Random();
    final n = _segmentCount;
    final points = <GeoPoint>[];
    final segments = <GeoLine>[];

    // Generate random segments
    for (var i = 0; i < n; i++) {
      final x1 = 0.05 + random.nextDouble() * 0.9;
      final y1 = 0.05 + random.nextDouble() * 0.9;
      final x2 = 0.05 + random.nextDouble() * 0.9;
      final y2 = 0.05 + random.nextDouble() * 0.9;
      final fromIdx = points.length;
      points.add(GeoPoint(x1, y1));
      points.add(GeoPoint(x2, y2));
      segments.add(GeoLine(fromIdx, fromIdx + 1));
    }

    final states = <GeometryState>[];
    final intersections = <GeoPoint>[];

    states.add(GeometryState(
      points: List.of(points),
      lines: List.of(segments),
      description: '$n random line segments',
    ));

    // Check all pairs
    for (var i = 0; i < n; i++) {
      for (var j = i + 1; j < n; j++) {
        final testLines = List.of(segments);
        testLines[i] = GeoLine(segments[i].fromIdx, segments[i].toIdx, status: LineStatus.testing);
        testLines[j] = GeoLine(segments[j].fromIdx, segments[j].toIdx, status: LineStatus.testing);

        final p1 = points[segments[i].fromIdx];
        final p2 = points[segments[i].toIdx];
        final p3 = points[segments[j].fromIdx];
        final p4 = points[segments[j].toIdx];

        final inter = _intersect(p1, p2, p3, p4);

        if (inter != null) {
          intersections.add(GeoPoint(inter.$1, inter.$2, status: PointStatus.active));
          final allPoints = [...points, ...intersections];
          testLines[i] = GeoLine(segments[i].fromIdx, segments[i].toIdx, status: LineStatus.accepted);
          testLines[j] = GeoLine(segments[j].fromIdx, segments[j].toIdx, status: LineStatus.accepted);

          states.add(GeometryState(
            points: allPoints, lines: testLines,
            description: 'Intersection found: segment $i × segment $j',
          ));

          testLines[i] = segments[i];
          testLines[j] = segments[j];
        } else {
          states.add(GeometryState(
            points: [...points, ...intersections], lines: testLines,
            description: 'No intersection: segment $i × segment $j',
          ));
        }
      }
    }

    states.add(GeometryState(
      points: [...points, ...intersections],
      lines: segments,
      description: 'Found ${intersections.length} intersections among $n segments',
    ));

    return states;
  }

  (double, double)? _intersect(GeoPoint p1, GeoPoint p2, GeoPoint p3, GeoPoint p4) {
    final d1x = p2.x - p1.x, d1y = p2.y - p1.y;
    final d2x = p4.x - p3.x, d2y = p4.y - p3.y;
    final denom = d1x * d2y - d1y * d2x;
    if (denom.abs() < 1e-10) { return null; }

    final t = ((p3.x - p1.x) * d2y - (p3.y - p1.y) * d2x) / denom;
    final u = ((p3.x - p1.x) * d1y - (p3.y - p1.y) * d1x) / denom;

    if (t >= 0 && t <= 1 && u >= 0 && u <= 1) {
      return (p1.x + t * d1x, p1.y + t * d1y);
    }
    return null;
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) =>
      GeometryPainter(state: state as GeometryState, colorScheme: Theme.of(context).colorScheme);

  @override
  List<LegendItem>? buildLegend(BuildContext context) => geometryLegend(context);

  @override
  Widget? buildControls({required VoidCallback onChanged}) =>
      _Ctrl(count: _segmentCount, onChanged: (v) { _segmentCount = v; onChanged(); });
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
    Text('Segments: ${_v.round()}', style: Theme.of(context).textTheme.bodySmall),
    Expanded(child: Slider(value: _v, min: 3, max: 20, divisions: 17,
      onChanged: (v) => setState(() => _v = v), onChangeEnd: (v) => widget.onChanged(v.round()))),
  ]);
}
