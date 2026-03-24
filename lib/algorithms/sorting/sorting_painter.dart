import 'package:flutter/material.dart';
import 'package:algo_canvas/algorithms/sorting/sorting_state.dart';

class SortingPainter extends CustomPainter {
  SortingPainter({
    required this.state,
    required this.brightness,
  });

  final SortingState state;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final array = state.array;
    if (array.isEmpty) return;

    final maxVal = array.reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) return;

    final barWidth = size.width / array.length;
    final barMaxHeight = size.height;

    for (var i = 0; i < array.length; i++) {
      final barHeight = (array[i] / maxVal) * barMaxHeight;
      final rect = Rect.fromLTWH(
        i * barWidth,
        size.height - barHeight,
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

  Color _colorForIndex(int index) {
    final isDark = brightness == Brightness.dark;

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
      return isDark
          ? const Color(0xFFFFCA28)
          : const Color(0xFFF9A825);
    }
    if (state.comparing.contains(index)) {
      return isDark
          ? const Color(0xFF42A5F5)
          : const Color(0xFF1976D2);
    }
    // Default bar color
    return isDark
        ? const Color(0xFF90A4AE)
        : const Color(0xFF607D8B);
  }

  @override
  bool shouldRepaint(covariant SortingPainter oldDelegate) {
    return oldDelegate.state != state;
  }
}
