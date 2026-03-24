import 'package:flutter/material.dart';
import 'package:algo_canvas/widgets/color_legend.dart';

List<LegendItem> geometryLegend(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return [
    LegendItem(isDark ? const Color(0xFFEF5350) : const Color(0xFFD32F2F), 'Active'),
    LegendItem(isDark ? const Color(0xFFFFCA28) : const Color(0xFFF9A825), 'Testing'),
    LegendItem(isDark ? const Color(0xFF4CAF50) : const Color(0xFF388E3C), 'Accepted'),
  ];
}
