import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';
import 'package:algo_canvas/algorithms/geometry/geometry_state.dart';
import 'package:algo_canvas/algorithms/geometry/geometry_painter.dart';
import 'package:algo_canvas/algorithms/geometry/geometry_legend.dart';
import 'package:algo_canvas/widgets/color_legend.dart';

class DelaunayAlgorithm extends Algorithm {
  int _pointCount = 15;

  @override
  String get name => 'Delaunay Triangulation';
  @override
  String get description => 'Triangulate points maximizing minimum angles. Brute-force O(n⁴).';
  @override
  AlgorithmCategory get category => AlgorithmCategory.computationalGeometry;

  @override
  Future<List<AlgorithmState>> generate() async {
    final random = Random();
    final points = List.generate(_pointCount, (_) =>
        GeoPoint(0.05 + random.nextDouble() * 0.9, 0.05 + random.nextDouble() * 0.9));
    final states = <GeometryState>[];
    final n = points.length;
    final acceptedEdges = <GeoLine>[];

    states.add(GeometryState(points: points, description: 'Delaunay triangulation: $n points'));

    // Brute-force: for each triple, check if it forms a valid Delaunay triangle
    // (no other point inside its circumcircle)
    final triangles = <(int, int, int)>[];

    for (var i = 0; i < n; i++) {
      for (var j = i + 1; j < n; j++) {
        for (var k = j + 1; k < n; k++) {
          // Check circumcircle
          final (cx, cy, r) = _circumcircle(points[i], points[j], points[k]);
          if (r < 0) { continue; } // degenerate

          var valid = true;
          for (var l = 0; l < n; l++) {
            if (l == i || l == j || l == k) { continue; }
            final dx = points[l].x - cx;
            final dy = points[l].y - cy;
            if (dx * dx + dy * dy < r * r - 1e-10) {
              valid = false;
              break;
            }
          }

          if (valid) {
            triangles.add((i, j, k));

            void addEdge(int a, int b) {
              if (!acceptedEdges.any((e) =>
                  (e.fromIdx == a && e.toIdx == b) || (e.fromIdx == b && e.toIdx == a))) {
                acceptedEdges.add(GeoLine(a, b, status: LineStatus.accepted));
              }
            }
            addEdge(i, j);
            addEdge(j, k);
            addEdge(i, k);

            final pts = List.of(points);
            pts[i] = pts[i].copyWith(status: PointStatus.hull);
            pts[j] = pts[j].copyWith(status: PointStatus.hull);
            pts[k] = pts[k].copyWith(status: PointStatus.hull);

            states.add(GeometryState(
              points: pts, lines: List.of(acceptedEdges),
              polygons: [[i, j, k]],
              description: 'Triangle ($i, $j, $k) — valid Delaunay',
            ));
          }
        }
      }
    }

    // Final
    for (var i = 0; i < points.length; i++) {
      points[i] = points[i].copyWith(status: PointStatus.hull);
    }

    states.add(GeometryState(
      points: points, lines: acceptedEdges,
      polygons: triangles.map((t) => [t.$1, t.$2, t.$3]).toList(),
      description: 'Delaunay complete: ${triangles.length} triangles, ${acceptedEdges.length} edges',
    ));

    return states;
  }

  /// Returns (centerX, centerY, radius). Radius < 0 if degenerate.
  (double, double, double) _circumcircle(GeoPoint a, GeoPoint b, GeoPoint c) {
    final ax = a.x, ay = a.y;
    final bx = b.x, by = b.y;
    final cx = c.x, cy = c.y;

    final d = 2 * (ax * (by - cy) + bx * (cy - ay) + cx * (ay - by));
    if (d.abs() < 1e-12) { return (0, 0, -1); }

    final ux = ((ax * ax + ay * ay) * (by - cy) + (bx * bx + by * by) * (cy - ay) + (cx * cx + cy * cy) * (ay - by)) / d;
    final uy = ((ax * ax + ay * ay) * (cx - bx) + (bx * bx + by * by) * (ax - cx) + (cx * cx + cy * cy) * (bx - ax)) / d;

    final r = sqrt((ax - ux) * (ax - ux) + (ay - uy) * (ay - uy));
    return (ux, uy, r);
  }

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
    Expanded(child: Slider(value: _v, min: 5, max: 20, divisions: 15,
      onChanged: (v) => setState(() => _v = v), onChangeEnd: (v) => widget.onChanged(v.round()))),
  ]);
}
