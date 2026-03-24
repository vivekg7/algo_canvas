import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/algorithms/string/string_state.dart';

class StringMatchPainter extends CustomPainter {
  StringMatchPainter({required this.state, required this.brightness});

  final StringMatchState state;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final isDark = brightness == Brightness.dark;
    final text = state.text;
    final pattern = state.pattern;
    final cellSize = min(size.width / (text.length + 1), 32.0).clamp(14.0, 32.0);
    final offsetX = (size.width - cellSize * text.length) / 2;

    // Draw text row
    final textY = size.height * 0.25;
    _drawLabel(canvas, 'Text:', offsetX - 40, textY + cellSize * 0.3, isDark);

    for (var i = 0; i < text.length; i++) {
      final x = offsetX + i * cellSize;
      final rect = Rect.fromLTWH(x, textY, cellSize - 1, cellSize);

      canvas.drawRect(rect, Paint()..color = _charColor(state.textStatus[i], isDark));
      canvas.drawRect(rect, Paint()
        ..color = isDark ? Colors.white12 : Colors.black12
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5);

      _drawChar(canvas, text[i], x + cellSize / 2, textY + cellSize / 2, isDark,
          state.textStatus[i] != CharStatus.normal);
    }

    // Draw pattern row (aligned at textOffset)
    final patternY = textY + cellSize + 16;
    _drawLabel(canvas, 'Pattern:', offsetX - 56, patternY + cellSize * 0.3, isDark);

    for (var i = 0; i < pattern.length; i++) {
      final x = offsetX + (state.textOffset + i) * cellSize;
      if (x < 0 || x + cellSize > size.width + cellSize) { continue; }

      final rect = Rect.fromLTWH(x, patternY, cellSize - 1, cellSize);

      canvas.drawRect(rect, Paint()..color = _charColor(state.patternStatus[i], isDark));
      canvas.drawRect(rect, Paint()
        ..color = isDark ? Colors.white24 : Colors.black26
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1);

      _drawChar(canvas, pattern[i], x + cellSize / 2, patternY + cellSize / 2, isDark,
          state.patternStatus[i] != CharStatus.normal);
    }

    // Draw matches found
    if (state.matches.isNotEmpty) {
      final matchY = patternY + cellSize + 24;
      final matchColor = isDark ? const Color(0xFF4CAF50) : const Color(0xFF388E3C);
      final tp = TextPainter(
        text: TextSpan(
          text: 'Found at: ${state.matches.join(", ")}',
          style: TextStyle(fontSize: 13, color: matchColor, fontWeight: FontWeight.w600),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset((size.width - tp.width) / 2, matchY));
    }

    // Draw extra info (e.g., failure table)
    if (state.extraInfo != null) {
      final infoY = patternY + cellSize + (state.matches.isNotEmpty ? 48 : 24);
      _drawLabel(canvas, 'Table:', offsetX - 46, infoY + cellSize * 0.3, isDark);

      for (var i = 0; i < state.extraInfo!.length && i < pattern.length; i++) {
        final x = offsetX + i * cellSize;
        final rect = Rect.fromLTWH(x, infoY, cellSize - 1, cellSize * 0.8);

        canvas.drawRect(rect, Paint()
          ..color = isDark ? const Color(0xFF37474F) : const Color(0xFFECEFF1));
        canvas.drawRect(rect, Paint()
          ..color = isDark ? Colors.white12 : Colors.black12
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5);

        _drawChar(canvas, '${state.extraInfo![i]}',
            x + cellSize / 2, infoY + cellSize * 0.4, isDark, false);
      }
    }
  }

  void _drawChar(Canvas canvas, String ch, double cx, double cy, bool isDark, bool bold) {
    final tp = TextPainter(
      text: TextSpan(
        text: ch,
        style: TextStyle(
          fontSize: 13,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
  }

  void _drawLabel(Canvas canvas, String label, double x, double y, bool isDark) {
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 11,
          color: isDark ? Colors.white38 : Colors.black38,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x, y));
  }

  Color _charColor(CharStatus status, bool isDark) {
    switch (status) {
      case CharStatus.normal:
        return isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5);
      case CharStatus.current:
        return isDark
            ? const Color(0xFFFFCA28).withValues(alpha: 0.4)
            : const Color(0xFFF9A825).withValues(alpha: 0.3);
      case CharStatus.matching:
        return isDark
            ? const Color(0xFF42A5F5).withValues(alpha: 0.4)
            : const Color(0xFF1976D2).withValues(alpha: 0.3);
      case CharStatus.mismatched:
        return isDark
            ? const Color(0xFFEF5350).withValues(alpha: 0.4)
            : const Color(0xFFD32F2F).withValues(alpha: 0.3);
      case CharStatus.matched:
        return isDark
            ? const Color(0xFF4CAF50).withValues(alpha: 0.5)
            : const Color(0xFF388E3C).withValues(alpha: 0.4);
    }
  }

  @override
  bool shouldRepaint(covariant StringMatchPainter oldDelegate) {
    return oldDelegate.state != state;
  }
}
