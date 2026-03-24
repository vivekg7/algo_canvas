import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/algorithms/pathfinding/grid_state.dart';

class GridPainter extends CustomPainter {
  GridPainter({required this.state, required this.brightness});

  final GridState state;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final rows = state.rows;
    final cols = state.cols;
    final cellW = size.width / cols;
    final cellH = size.height / rows;
    final cellSize = min(cellW, cellH);
    final offsetX = (size.width - cellSize * cols) / 2;
    final offsetY = (size.height - cellSize * rows) / 2;

    final isDark = brightness == Brightness.dark;

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final tile = state.grid[r * cols + c];
        final rect = Rect.fromLTWH(
          offsetX + c * cellSize,
          offsetY + r * cellSize,
          cellSize - (cellSize > 3 ? 0.5 : 0),
          cellSize - (cellSize > 3 ? 0.5 : 0),
        );

        canvas.drawRect(rect, Paint()..color = _tileColor(tile, isDark));
      }
    }

    // Border
    canvas.drawRect(
      Rect.fromLTWH(offsetX, offsetY, cellSize * cols, cellSize * rows),
      Paint()
        ..color = isDark ? Colors.white12 : Colors.black12
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );
  }

  Color _tileColor(TileType tile, bool isDark) {
    switch (tile) {
      case TileType.empty:
        return isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5);
      case TileType.wall:
        return isDark ? const Color(0xFF616161) : const Color(0xFF424242);
      case TileType.start:
        return isDark ? const Color(0xFF42A5F5) : const Color(0xFF1976D2);
      case TileType.end:
        return isDark ? const Color(0xFFAB47BC) : const Color(0xFF7B1FA2);
      case TileType.visited:
        return isDark
            ? const Color(0xFF42A5F5).withValues(alpha: 0.25)
            : const Color(0xFF1976D2).withValues(alpha: 0.2);
      case TileType.queued:
        return isDark
            ? const Color(0xFFFFCA28).withValues(alpha: 0.4)
            : const Color(0xFFF9A825).withValues(alpha: 0.3);
      case TileType.path:
        return isDark ? const Color(0xFF4CAF50) : const Color(0xFF388E3C);
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    return oldDelegate.state != state;
  }
}
