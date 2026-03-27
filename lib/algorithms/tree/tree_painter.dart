import 'package:flutter/material.dart';
import 'package:algo_canvas/algorithms/tree/tree_state.dart';

class TreePainter extends CustomPainter {
  TreePainter({required this.state, required this.colorScheme});

  final TreeState state;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final isDark = colorScheme.brightness == Brightness.dark;
    final padding = 20.0;
    final drawW = size.width - padding * 2;
    final drawH = size.height - padding * 2;

    Offset pos(TreeNode node) {
      return Offset(padding + node.x * drawW, padding + node.y * drawH);
    }

    final edgeColor = isDark ? Colors.white24 : Colors.black26;
    final highlightEdgeColor = isDark ? const Color(0xFF4CAF50) : const Color(0xFF388E3C);

    final highlightSet = state.highlightPath.toSet();

    // Draw edges first
    for (final node in state.nodes.values) {
      final p = pos(node);
      for (final childId in [node.left, node.right]) {
        if (childId == null) continue;
        final child = state.nodes[childId];
        if (child == null) continue;
        final cp = pos(child);

        final isHighlighted = highlightSet.contains(node.id) && highlightSet.contains(childId);
        canvas.drawLine(p, cp, Paint()
          ..color = isHighlighted ? highlightEdgeColor : edgeColor
          ..strokeWidth = isHighlighted ? 2.5 : 1.5);
      }
    }

    // Draw nodes
    for (final node in state.nodes.values) {
      final p = pos(node);
      final radius = 16.0;

      canvas.drawCircle(p, radius, Paint()..color = _nodeColor(node.status, isDark));
      canvas.drawCircle(p, radius, Paint()
        ..color = isDark ? Colors.white24 : Colors.black26
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1);

      // Value
      final tp = TextPainter(
        text: TextSpan(
          text: '${node.value}',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: node.status == TreeNodeStatus.normal
                ? (isDark ? Colors.white70 : Colors.black87)
                : Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));

      // Balance factor for AVL
      if (node.balanceFactor != null) {
        final bfTp = TextPainter(
          text: TextSpan(
            text: '${node.balanceFactor}',
            style: TextStyle(
              fontSize: 8,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        bfTp.paint(canvas, Offset(p.dx + radius + 2, p.dy - radius));
      }
    }
  }

  Color _nodeColor(TreeNodeStatus status, bool isDark) {
    switch (status) {
      case TreeNodeStatus.normal:
        return isDark ? const Color(0xFF424242) : const Color(0xFFE0E0E0);
      case TreeNodeStatus.highlighted:
        return colorScheme.tertiary;
      case TreeNodeStatus.visiting:
        return isDark ? const Color(0xFFEF5350) : const Color(0xFFD32F2F);
      case TreeNodeStatus.found:
        return isDark ? const Color(0xFF4CAF50) : const Color(0xFF388E3C);
      case TreeNodeStatus.inserted:
        return colorScheme.primary;
      case TreeNodeStatus.deleted:
        return isDark ? const Color(0xFFEF5350).withValues(alpha: 0.5) : const Color(0xFFD32F2F).withValues(alpha: 0.5);
    }
  }

  @override
  bool shouldRepaint(covariant TreePainter oldDelegate) {
    return oldDelegate.state != state || oldDelegate.colorScheme != colorScheme;
  }
}
