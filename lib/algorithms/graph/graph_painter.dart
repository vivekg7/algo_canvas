import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/algorithms/graph/graph_state.dart';

class GraphPainter extends CustomPainter {
  GraphPainter({
    required this.state,
    required this.brightness,
  });

  final GraphState state;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final isDark = brightness == Brightness.dark;
    final padding = 30.0;
    final drawW = size.width - padding * 2;
    final drawH = size.height - padding * 2;

    Offset nodePos(GraphNode node) {
      return Offset(padding + node.x * drawW, padding + node.y * drawH);
    }

    // -- Draw edges --
    for (final edge in state.edges) {
      final from = state.nodes[edge.from];
      final to = state.nodes[edge.to];
      final p1 = nodePos(from);
      final p2 = nodePos(to);

      final edgeColor = _edgeColor(edge.status, isDark);
      final strokeWidth = edge.status == EdgeStatus.inTree ? 3.0 : 1.5;

      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = edgeColor
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );

      // Arrow for directed graphs
      if (state.directed) {
        _drawArrow(canvas, p1, p2, edgeColor, strokeWidth);
      }

      // Weight label
      if (state.weighted) {
        final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
        // Offset label slightly to avoid overlapping the edge
        final dx = p2.dx - p1.dx;
        final dy = p2.dy - p1.dy;
        final len = sqrt(dx * dx + dy * dy);
        final offsetX = len > 0 ? -dy / len * 10 : 0.0;
        final offsetY = len > 0 ? dx / len * 10 : 0.0;

        final tp = TextPainter(
          text: TextSpan(
            text: edge.weight == edge.weight.roundToDouble()
                ? '${edge.weight.round()}'
                : edge.weight.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white54 : Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(
          canvas,
          Offset(mid.dx + offsetX - tp.width / 2,
              mid.dy + offsetY - tp.height / 2),
        );
      }
    }

    // -- Draw nodes --
    for (final node in state.nodes) {
      final pos = nodePos(node);
      final radius = 14.0;

      // Node fill
      canvas.drawCircle(pos, radius, Paint()..color = _nodeColor(node.status, isDark));

      // Node border
      canvas.drawCircle(
        pos,
        radius,
        Paint()
          ..color = isDark ? Colors.white24 : Colors.black26
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );

      // Label
      final label = node.label ?? '${node.id}';
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontSize: 10,
            color: node.status == NodeStatus.unvisited
                ? (isDark ? Colors.white70 : Colors.black87)
                : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));

      // Distance label below node
      if (node.distance != null) {
        final distLabel = node.distance == double.infinity
            ? '∞'
            : (node.distance == node.distance!.roundToDouble()
                ? '${node.distance!.round()}'
                : node.distance!.toStringAsFixed(1));
        final dtp = TextPainter(
          text: TextSpan(
            text: distLabel,
            style: TextStyle(
              fontSize: 9,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        dtp.paint(canvas, Offset(pos.dx - dtp.width / 2, pos.dy + radius + 2));
      }
    }
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to, Color color, double strokeWidth) {
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final len = sqrt(dx * dx + dy * dy);
    if (len < 30) return;

    // Arrow tip at node edge (radius 14)
    final ux = dx / len;
    final uy = dy / len;
    final tip = Offset(to.dx - ux * 14, to.dy - uy * 14);
    const arrowSize = 8.0;

    final p1 = Offset(
      tip.dx - ux * arrowSize - uy * arrowSize * 0.5,
      tip.dy - uy * arrowSize + ux * arrowSize * 0.5,
    );
    final p2 = Offset(
      tip.dx - ux * arrowSize + uy * arrowSize * 0.5,
      tip.dy - uy * arrowSize - ux * arrowSize * 0.5,
    );

    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..close();

    canvas.drawPath(path, Paint()..color = color);
  }

  Color _nodeColor(NodeStatus status, bool isDark) {
    switch (status) {
      case NodeStatus.unvisited:
        return isDark ? const Color(0xFF424242) : const Color(0xFFE0E0E0);
      case NodeStatus.queued:
        return isDark ? const Color(0xFFFFCA28) : const Color(0xFFF9A825);
      case NodeStatus.visiting:
        return isDark ? const Color(0xFFEF5350) : const Color(0xFFD32F2F);
      case NodeStatus.visited:
        return isDark ? const Color(0xFF4CAF50) : const Color(0xFF388E3C);
      case NodeStatus.source:
        return isDark ? const Color(0xFF42A5F5) : const Color(0xFF1976D2);
      case NodeStatus.target:
        return isDark ? const Color(0xFFAB47BC) : const Color(0xFF7B1FA2);
    }
  }

  Color _edgeColor(EdgeStatus status, bool isDark) {
    switch (status) {
      case EdgeStatus.none:
        return isDark ? Colors.white24 : Colors.black26;
      case EdgeStatus.exploring:
        return isDark ? const Color(0xFFFFCA28) : const Color(0xFFF9A825);
      case EdgeStatus.inTree:
        return isDark ? const Color(0xFF4CAF50) : const Color(0xFF388E3C);
      case EdgeStatus.rejected:
        return isDark
            ? const Color(0xFFEF5350).withValues(alpha: 0.3)
            : const Color(0xFFD32F2F).withValues(alpha: 0.2);
    }
  }

  @override
  bool shouldRepaint(covariant GraphPainter oldDelegate) {
    return oldDelegate.state != state;
  }
}
