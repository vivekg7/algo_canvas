import 'package:flutter/material.dart';
import 'package:algo_canvas/widgets/color_legend.dart';

List<LegendItem> dpLegend(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final colorScheme = Theme.of(context).colorScheme;
  return [
    LegendItem(
      colorScheme.tertiary,
      'Computing',
    ),
    LegendItem(
      colorScheme.primary,
      'Filled',
    ),
    LegendItem(
      isDark ? const Color(0xFF4CAF50) : const Color(0xFF388E3C),
      'Optimal path',
    ),
  ];
}
