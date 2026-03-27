import 'package:flutter/material.dart';
import 'package:algo_canvas/widgets/color_legend.dart';

List<LegendItem> treeLegend(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final colorScheme = Theme.of(context).colorScheme;
  return [
    LegendItem(isDark ? const Color(0xFFEF5350) : const Color(0xFFD32F2F), 'Visiting'),
    LegendItem(colorScheme.tertiary, 'Highlighted'),
    LegendItem(colorScheme.primary, 'Inserted'),
    LegendItem(isDark ? const Color(0xFF4CAF50) : const Color(0xFF388E3C), 'Found'),
  ];
}
