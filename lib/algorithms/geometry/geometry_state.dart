import 'package:algo_canvas/core/algorithm_state.dart';

enum PointStatus { normal, active, hull, rejected }

enum LineStatus { none, testing, accepted, rejected }

class GeoPoint {
  const GeoPoint(this.x, this.y, {this.status = PointStatus.normal});
  final double x; // normalized 0..1
  final double y;
  final PointStatus status;

  GeoPoint copyWith({PointStatus? status}) =>
      GeoPoint(x, y, status: status ?? this.status);
}

class GeoLine {
  const GeoLine(this.fromIdx, this.toIdx, {this.status = LineStatus.none});
  final int fromIdx;
  final int toIdx;
  final LineStatus status;
}

class GeometryState extends AlgorithmState {
  const GeometryState({
    required this.points,
    this.lines = const [],
    this.polygons = const [],
    required super.description,
  });

  final List<GeoPoint> points;
  final List<GeoLine> lines;

  /// Polygons as lists of point indices (drawn as filled outlines).
  final List<List<int>> polygons;
}
