import 'package:flutter/material.dart';
import 'package:algo_canvas/algorithms/geometry/geometry_state.dart';

class GeometryPainter extends CustomPainter {
  GeometryPainter({required this.state, required this.brightness});

  final GeometryState state;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final isDark = brightness == Brightness.dark;
    final padding = 30.0;
    final drawW = size.width - padding * 2;
    final drawH = size.height - padding * 2;

    Offset pos(GeoPoint p) => Offset(padding + p.x * drawW, padding + p.y * drawH);

    // Draw polygons
    for (final poly in state.polygons) {
      if (poly.length < 3) continue;
      final path = Path();
      path.moveTo(pos(state.points[poly[0]]).dx, pos(state.points[poly[0]]).dy);
      for (var i = 1; i < poly.length; i++) {
        path.lineTo(pos(state.points[poly[i]]).dx, pos(state.points[poly[i]]).dy);
      }
      path.close();
      canvas.drawPath(path, Paint()
        ..color = (isDark ? const Color(0xFF42A5F5) : const Color(0xFF1976D2)).withValues(alpha: 0.1)
        ..style = PaintingStyle.fill);
    }

    // Draw lines
    for (final line in state.lines) {
      final p1 = pos(state.points[line.fromIdx]);
      final p2 = pos(state.points[line.toIdx]);
      canvas.drawLine(p1, p2, Paint()
        ..color = _lineColor(line.status, isDark)
        ..strokeWidth = line.status == LineStatus.accepted ? 2.5 : 1.5
        ..strokeCap = StrokeCap.round);
    }

    // Draw points
    for (final point in state.points) {
      final p = pos(point);
      final radius = point.status == PointStatus.active ? 6.0 : 4.5;
      canvas.drawCircle(p, radius, Paint()..color = _pointColor(point.status, isDark));
      canvas.drawCircle(p, radius, Paint()
        ..color = isDark ? Colors.white24 : Colors.black26
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5);
    }
  }

  Color _pointColor(PointStatus status, bool isDark) {
    switch (status) {
      case PointStatus.normal:
        return isDark ? const Color(0xFF90A4AE) : const Color(0xFF607D8B);
      case PointStatus.active:
        return isDark ? const Color(0xFFEF5350) : const Color(0xFFD32F2F);
      case PointStatus.hull:
        return isDark ? const Color(0xFF4CAF50) : const Color(0xFF388E3C);
      case PointStatus.rejected:
        return isDark ? const Color(0xFF616161) : const Color(0xFFBDBDBD);
    }
  }

  Color _lineColor(LineStatus status, bool isDark) {
    switch (status) {
      case LineStatus.none:
        return isDark ? Colors.white12 : Colors.black12;
      case LineStatus.testing:
        return isDark ? const Color(0xFFFFCA28) : const Color(0xFFF9A825);
      case LineStatus.accepted:
        return isDark ? const Color(0xFF4CAF50) : const Color(0xFF388E3C);
      case LineStatus.rejected:
        return isDark
            ? const Color(0xFFEF5350).withValues(alpha: 0.4)
            : const Color(0xFFD32F2F).withValues(alpha: 0.3);
    }
  }

  @override
  bool shouldRepaint(covariant GeometryPainter oldDelegate) =>
      oldDelegate.state != state;
}
