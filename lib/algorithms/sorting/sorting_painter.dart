import 'package:flutter/material.dart';
import 'package:algo_canvas/algorithms/sorting/sorting_state.dart';

class SortingPainter extends CustomPainter {
  SortingPainter({
    required this.state,
    required this.colorScheme,
  });

  final SortingState state;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final array = state.array;
    if (array.isEmpty) return;

    final maxVal = array.reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) return;

    final barWidth = size.width / array.length;
    final showLabels = array.length <= 30 && barWidth >= 14;
    final barMaxHeight = size.height - (showLabels ? 16 : 0);
    final isDark = colorScheme.brightness == Brightness.dark;

    for (var i = 0; i < array.length; i++) {
      final barHeight = (array[i] / maxVal) * barMaxHeight;
      final rect = Rect.fromLTWH(
        i * barWidth,
        size.height - barHeight - (showLabels ? 16 : 0),
        barWidth - (array.length > 100 ? 0 : 1),
        barHeight,
      );

      final paint = Paint()
        ..color = _colorForIndex(i, isDark)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndCorners(
          rect,
          topLeft: const Radius.circular(2),
          topRight: const Radius.circular(2),
        ),
        paint,
      );

      // Value label below bar
      if (showLabels) {
        final tp = TextPainter(
          text: TextSpan(
            text: '${array[i]}',
            style: TextStyle(
              fontSize: (barWidth * 0.4).clamp(7, 11),
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(
          canvas,
          Offset(
            i * barWidth + (barWidth - tp.width) / 2,
            size.height - 14,
          ),
        );
      }
    }
  }

  Color _colorForIndex(int index, bool isDark) {
    if (state.sorted.contains(index)) {
      return isDark
          ? const Color(0xFF4CAF50)
          : const Color(0xFF388E3C);
    }
    if (state.swapping.contains(index)) {
      return isDark
          ? const Color(0xFFEF5350)
          : const Color(0xFFD32F2F);
    }
    if (state.pivot != null && state.pivot == index) {
      return colorScheme.tertiary;
    }
    if (state.comparing.contains(index)) {
      return colorScheme.primary;
    }
    // Default bar color
    return isDark
        ? const Color(0xFF90A4AE)
        : const Color(0xFF607D8B);
  }

  @override
  bool shouldRepaint(covariant SortingPainter oldDelegate) {
    return oldDelegate.state != state || oldDelegate.colorScheme != colorScheme;
  }
}
