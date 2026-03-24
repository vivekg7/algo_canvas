import 'package:flutter/material.dart';
import 'package:algo_canvas/algorithms/searching/searching_state.dart';

class SearchingPainter extends CustomPainter {
  SearchingPainter({
    required this.state,
    required this.brightness,
  });

  final SearchingState state;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final array = state.array;
    if (array.isEmpty) return;

    final maxVal = array.reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) return;

    final barWidth = size.width / array.length;
    final barMaxHeight = size.height - 24; // Leave room for target line label

    // Draw target line
    final targetY = size.height - 24 - (state.target / maxVal) * barMaxHeight;
    final targetPaint = Paint()
      ..color = _targetColor().withValues(alpha: 0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(0, targetY),
      Offset(size.width, targetY),
      targetPaint,
    );

    // Target label
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'target: ${state.target}',
        style: TextStyle(
          color: _targetColor(),
          fontSize: 10,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(4, targetY - 14));

    // Draw bars
    for (var i = 0; i < array.length; i++) {
      final barHeight = (array[i] / maxVal) * barMaxHeight;
      final rect = Rect.fromLTWH(
        i * barWidth,
        size.height - 24 - barHeight,
        barWidth - (array.length > 100 ? 0 : 1),
        barHeight,
      );

      final paint = Paint()
        ..color = _colorForIndex(i)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndCorners(
          rect,
          topLeft: const Radius.circular(2),
          topRight: const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  Color _targetColor() {
    return brightness == Brightness.dark
        ? const Color(0xFFFFCA28)
        : const Color(0xFFF9A825);
  }

  Color _colorForIndex(int index) {
    final isDark = brightness == Brightness.dark;

    // Found
    if (state.found != null && state.found == index) {
      return isDark
          ? const Color(0xFF4CAF50)
          : const Color(0xFF388E3C);
    }

    // Currently checking
    if (state.checking == index) {
      return isDark
          ? const Color(0xFFEF5350)
          : const Color(0xFFD32F2F);
    }

    // Eliminated
    if (state.eliminated.contains(index)) {
      return isDark
          ? const Color(0xFF424242)
          : const Color(0xFFBDBDBD);
    }

    // In active search range
    if (state.rangeStart != null &&
        state.rangeEnd != null &&
        index >= state.rangeStart! &&
        index <= state.rangeEnd!) {
      return isDark
          ? const Color(0xFF42A5F5)
          : const Color(0xFF1976D2);
    }

    // Default
    return isDark
        ? const Color(0xFF90A4AE)
        : const Color(0xFF607D8B);
  }

  @override
  bool shouldRepaint(covariant SearchingPainter oldDelegate) {
    return oldDelegate.state != state;
  }
}
