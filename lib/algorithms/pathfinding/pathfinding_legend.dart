import 'package:flutter/material.dart';
import 'package:algo_canvas/widgets/color_legend.dart';

List<LegendItem> pathfindingLegend(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return [
    LegendItem(
      isDark ? const Color(0xFF42A5F5) : const Color(0xFF1976D2),
      'Start',
    ),
    LegendItem(
      isDark ? const Color(0xFFAB47BC) : const Color(0xFF7B1FA2),
      'End',
    ),
    LegendItem(
      isDark ? const Color(0xFF616161) : const Color(0xFF424242),
      'Wall',
    ),
    LegendItem(
      isDark ? const Color(0xFFFFCA28) : const Color(0xFFF9A825),
      'Queued',
    ),
    LegendItem(
      isDark ? const Color(0xFF4CAF50) : const Color(0xFF388E3C),
      'Path',
    ),
  ];
}

List<LegendItem> mazeLegend(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return [
    LegendItem(
      isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
      'Passage',
    ),
    LegendItem(
      isDark ? const Color(0xFF616161) : const Color(0xFF424242),
      'Wall',
    ),
    LegendItem(
      isDark ? const Color(0xFF4CAF50) : const Color(0xFF388E3C),
      'Path',
    ),
    LegendItem(
      isDark ? const Color(0xFFFFCA28) : const Color(0xFFF9A825),
      'Current',
    ),
  ];
}
