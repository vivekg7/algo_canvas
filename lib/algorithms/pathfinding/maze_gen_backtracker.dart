import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';
import 'package:algo_canvas/algorithms/pathfinding/grid_state.dart';
import 'package:algo_canvas/algorithms/pathfinding/grid_painter.dart';
import 'package:algo_canvas/algorithms/pathfinding/pathfinding_legend.dart';
import 'package:algo_canvas/widgets/color_legend.dart';

class MazeGenBacktrackerAlgorithm extends Algorithm {
  int _mazeSize = 15;

  @override
  String get name => 'Maze Gen (Backtracker)';

  @override
  String get description =>
      'Recursive backtracker: carve passages via DFS with random neighbor selection.';

  @override
  AlgorithmCategory get category => AlgorithmCategory.pathfinding;

  @override
  Future<List<AlgorithmState>> generate() async {
    final random = Random();
    // Grid is (2*maze+1) to have walls between cells
    final mazeW = _mazeSize, mazeH = _mazeSize;
    final rows = mazeH * 2 + 1;
    final cols = mazeW * 2 + 1;
    final grid = List.filled(rows * cols, TileType.wall);
    final states = <GridState>[];
    var step = 0;

    // Cell coords in maze space → grid space
    int gr(int mr) => mr * 2 + 1;
    int gc(int mc) => mc * 2 + 1;

    final visited = List.generate(mazeH, (_) => List.filled(mazeW, false));
    final stack = <(int, int)>[];

    // Start at (0,0)
    visited[0][0] = true;
    grid[gr(0) * cols + gc(0)] = TileType.path;
    stack.add((0, 0));

    states.add(GridState(grid: List.of(grid), rows: rows, cols: cols, step: step,
      description: 'Maze generation: recursive backtracker'));

    const dirs = [(0, -1), (0, 1), (-1, 0), (1, 0)];

    while (stack.isNotEmpty) {
      final (cr, cc) = stack.last;

      // Find unvisited neighbors
      final neighbors = <(int, int)>[];
      for (final (dr, dc) in dirs) {
        final nr = cr + dr, nc = cc + dc;
        if (nr >= 0 && nr < mazeH && nc >= 0 && nc < mazeW && !visited[nr][nc]) {
          neighbors.add((nr, nc));
        }
      }

      if (neighbors.isEmpty) {
        // Backtrack
        grid[gr(cr) * cols + gc(cc)] = TileType.empty;
        stack.removeLast();
        step++;
        if (step % 2 == 0) {
          states.add(GridState(grid: List.of(grid), rows: rows, cols: cols, step: step,
            description: 'Backtracking from ($cr, $cc)'));
        }
      } else {
        // Choose random neighbor
        final (nr, nc) = neighbors[random.nextInt(neighbors.length)];
        visited[nr][nc] = true;

        // Remove wall between current and neighbor
        final wallR = gr(cr) + (nr - cr);
        final wallC = gc(cc) + (nc - cc);
        grid[wallR * cols + wallC] = TileType.empty;
        grid[gr(nr) * cols + gc(nc)] = TileType.path;

        stack.add((nr, nc));
        step++;
        if (step % 2 == 0) {
          states.add(GridState(grid: List.of(grid), rows: rows, cols: cols, step: step,
            description: 'Carving passage to ($nr, $nc)'));
        }
      }
    }

    // Final: mark all passages as empty
    for (var i = 0; i < grid.length; i++) {
      if (grid[i] == TileType.path) { grid[i] = TileType.empty; }
    }
    // Mark start and end
    grid[gr(0) * cols + gc(0)] = TileType.start;
    grid[gr(mazeH - 1) * cols + gc(mazeW - 1)] = TileType.end;

    states.add(GridState(grid: List.of(grid), rows: rows, cols: cols, step: step,
      description: 'Maze generated! $mazeW×$mazeH'));

    return states;
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) =>
      GridPainter(state: state as GridState, brightness: Theme.of(context).brightness);

  @override
  List<LegendItem>? buildLegend(BuildContext context) => mazeLegend(context);

  @override
  Widget? buildControls({required VoidCallback onChanged}) =>
      _Ctrl(size: _mazeSize, onChanged: (v) { _mazeSize = v; onChanged(); });
}

class _Ctrl extends StatefulWidget {
  const _Ctrl({required this.size, required this.onChanged});
  final int size; final ValueChanged<int> onChanged;
  @override State<_Ctrl> createState() => _CtrlState();
}
class _CtrlState extends State<_Ctrl> {
  late double _v;
  @override void initState() { super.initState(); _v = widget.size.toDouble(); }
  @override Widget build(BuildContext context) => Row(children: [
    Text('Maze: ${_v.round()}×${_v.round()}', style: Theme.of(context).textTheme.bodySmall),
    Expanded(child: Slider(value: _v, min: 5, max: 30, divisions: 25,
      onChanged: (v) => setState(() => _v = v), onChangeEnd: (v) => widget.onChanged(v.round()))),
  ]);
}
