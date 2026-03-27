import 'package:flutter/material.dart';
import 'package:algo_canvas/widgets/color_legend.dart';

List<LegendItem> stringLegend(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final colorScheme = Theme.of(context).colorScheme;
  return [
    LegendItem(colorScheme.tertiary, 'Current'),
    LegendItem(colorScheme.primary, 'Matching'),
    LegendItem(isDark ? const Color(0xFFEF5350) : const Color(0xFFD32F2F), 'Mismatch'),
    LegendItem(isDark ? const Color(0xFF4CAF50) : const Color(0xFF388E3C), 'Found'),
  ];
}
