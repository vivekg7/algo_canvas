import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/algorithms/dp/dp_state.dart';

class DpPainter extends CustomPainter {
  DpPainter({required this.state, required this.brightness});

  final DpState state;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final isDark = brightness == Brightness.dark;
    final rows = state.rows;
    final cols = state.cols;
    final hasRowLabels = state.rowLabels != null;
    final hasColLabels = state.colLabels != null;

    // Calculate cell size
    final labelOffset = 28.0;
    final availW = size.width - (hasRowLabels ? labelOffset : 0);
    final availH = size.height - (hasColLabels ? labelOffset : 0);
    final cellW = availW / cols;
    final cellH = availH / rows;
    final cellSize = min(cellW, cellH).clamp(16.0, 50.0);

    final tableW = cellSize * cols;
    final tableH = cellSize * rows;
    final offsetX = (size.width - tableW - (hasRowLabels ? labelOffset : 0)) / 2 +
        (hasRowLabels ? labelOffset : 0);
    final offsetY = (size.height - tableH - (hasColLabels ? labelOffset : 0)) / 2 +
        (hasColLabels ? labelOffset : 0);

    final emptyColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5);
    final computingColor = isDark ? const Color(0xFFFFCA28) : const Color(0xFFF9A825);
    final filledColor = isDark ? const Color(0xFF42A5F5) : const Color(0xFF1976D2);
    final pathColor = isDark ? const Color(0xFF4CAF50) : const Color(0xFF388E3C);
    final textColor = isDark ? Colors.white : Colors.black;
    final dimText = isDark ? Colors.white38 : Colors.black38;
    final gridColor = isDark ? Colors.white12 : Colors.black12;

    // Column labels
    if (hasColLabels) {
      for (var c = 0; c < cols && c < state.colLabels!.length; c++) {
        final tp = TextPainter(
          text: TextSpan(
            text: state.colLabels![c],
            style: TextStyle(fontSize: min(cellSize * 0.35, 11), color: dimText, fontWeight: FontWeight.w600),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(
          offsetX + c * cellSize + (cellSize - tp.width) / 2,
          offsetY - labelOffset + (labelOffset - tp.height) / 2,
        ));
      }
    }

    // Row labels
    if (hasRowLabels) {
      for (var r = 0; r < rows && r < state.rowLabels!.length; r++) {
        final tp = TextPainter(
          text: TextSpan(
            text: state.rowLabels![r],
            style: TextStyle(fontSize: min(cellSize * 0.35, 11), color: dimText, fontWeight: FontWeight.w600),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(
          offsetX - labelOffset + (labelOffset - tp.width) / 2,
          offsetY + r * cellSize + (cellSize - tp.height) / 2,
        ));
      }
    }

    // Cells
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final idx = r * cols + c;
        final rect = Rect.fromLTWH(
          offsetX + c * cellSize,
          offsetY + r * cellSize,
          cellSize,
          cellSize,
        );

        // Cell background
        Color bg;
        switch (state.cellStatus[idx]) {
          case CellStatus.empty:
            bg = emptyColor;
          case CellStatus.computing:
            bg = computingColor.withValues(alpha: 0.5);
          case CellStatus.filled:
            bg = filledColor.withValues(alpha: 0.2);
          case CellStatus.onPath:
            bg = pathColor.withValues(alpha: 0.4);
        }

        // Highlight current cell
        if (state.currentRow == r && state.currentCol == c) {
          bg = computingColor;
        }

        canvas.drawRect(rect, Paint()..color = bg);

        // Grid lines
        canvas.drawRect(rect, Paint()
          ..color = gridColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5);

        // Value text
        final value = state.table[idx];
        if (value.isNotEmpty) {
          final tp = TextPainter(
            text: TextSpan(
              text: value,
              style: TextStyle(
                fontSize: min(cellSize * 0.35, 12),
                color: state.cellStatus[idx] == CellStatus.empty ? dimText : textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          tp.paint(canvas, Offset(
            offsetX + c * cellSize + (cellSize - tp.width) / 2,
            offsetY + r * cellSize + (cellSize - tp.height) / 2,
          ));
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant DpPainter oldDelegate) {
    return oldDelegate.state != state;
  }
}
