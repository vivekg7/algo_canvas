import 'package:flutter/material.dart';

enum AlgorithmCategory {
  sorting('Sorting', Icons.bar_chart, Color(0xFF42A5F5)),
  graphTraversal('Graph Traversal', Icons.hub, Color(0xFF66BB6A)),
  pathfinding('Pathfinding', Icons.route, Color(0xFFAB47BC)),
  searching('Searching', Icons.search, Color(0xFFFF7043)),
  tree('Tree', Icons.account_tree, Color(0xFF26A69A)),
  dynamicProgramming('Dynamic Programming', Icons.grid_view, Color(0xFF5C6BC0)),
  mathSignal('Math / Signal', Icons.functions, Color(0xFFEC407A)),
  physicsSimulation('Physics / Simulation', Icons.science, Color(0xFF78909C)),
  string('String', Icons.text_fields, Color(0xFFFFA726)),
  computationalGeometry('Computational Geometry', Icons.pentagon, Color(0xFF29B6F6)),
  backtracking('Backtracking', Icons.undo, Color(0xFFEF5350)),
  compression('Compression / Encoding', Icons.compress, Color(0xFF8D6E63)),
  fractals('Fractals', Icons.auto_awesome, Color(0xFFBA68C8)),
  spaceFillingCurves('Space-Filling Curves', Icons.timeline, Color(0xFFFFD54F));

  const AlgorithmCategory(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}
