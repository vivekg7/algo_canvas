import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';
import 'package:algo_canvas/algorithms/pathfinding/grid_state.dart';
import 'package:algo_canvas/algorithms/pathfinding/grid_painter.dart';
import 'package:algo_canvas/algorithms/pathfinding/pathfinding_legend.dart';
import 'package:algo_canvas/widgets/color_legend.dart';

class MazeGenPrimAlgorithm extends Algorithm {
  int _mazeSize = 15;

  @override
  String get name => "Maze Gen (Prim's)";

  @override
  String get description =>
      "Randomized Prim's: grow maze by adding random frontier walls.";

  @override
  AlgorithmCategory get category => AlgorithmCategory.pathfinding;

  @override
  Future<List<AlgorithmState>> generate() async {
    final random = Random();
    final mazeW = _mazeSize, mazeH = _mazeSize;
    final rows = mazeH * 2 + 1;
    final cols = mazeW * 2 + 1;
    final grid = List.filled(rows * cols, TileType.wall);
    final states = <GridState>[];
    var step = 0;

    int gr(int mr) => mr * 2 + 1;
    int gc(int mc) => mc * 2 + 1;

    final inMaze = List.generate(mazeH, (_) => List.filled(mazeW, false));
    final frontier = <(int, int, int, int)>[]; // (wallR, wallC, cellR, cellC)

    void addFrontier(int r, int c) {
      const dirs = [(0, -1), (0, 1), (-1, 0), (1, 0)];
      for (final (dr, dc) in dirs) {
        final nr = r + dr, nc = c + dc;
        if (nr >= 0 && nr < mazeH && nc >= 0 && nc < mazeW && !inMaze[nr][nc]) {
          frontier.add((gr(r) + dr, gc(c) + dc, nr, nc));
        }
      }
    }

    // Start
    inMaze[0][0] = true;
    grid[gr(0) * cols + gc(0)] = TileType.empty;
    addFrontier(0, 0);

    states.add(GridState(grid: List.of(grid), rows: rows, cols: cols, step: step,
      description: "Maze generation: Prim's algorithm"));

    while (frontier.isNotEmpty) {
      final idx = random.nextInt(frontier.length);
      final (wallR, wallC, cellR, cellC) = frontier[idx];
      frontier.removeAt(idx);

      if (inMaze[cellR][cellC]) { continue; }

      inMaze[cellR][cellC] = true;
      grid[wallR * cols + wallC] = TileType.empty;
      grid[gr(cellR) * cols + gc(cellC)] = TileType.queued;

      step++;
      if (step % 3 == 0) {
        states.add(GridState(grid: List.of(grid), rows: rows, cols: cols, step: step,
          description: 'Adding cell ($cellR, $cellC)'));
      }

      grid[gr(cellR) * cols + gc(cellC)] = TileType.empty;
      addFrontier(cellR, cellC);
    }

    grid[gr(0) * cols + gc(0)] = TileType.start;
    grid[gr(mazeH - 1) * cols + gc(mazeW - 1)] = TileType.end;

    states.add(GridState(grid: List.of(grid), rows: rows, cols: cols, step: step,
      description: 'Maze generated! $mazeW×$mazeH'));

    return states;
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) =>
      GridPainter(state: state as GridState, colorScheme: Theme.of(context).colorScheme);

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
