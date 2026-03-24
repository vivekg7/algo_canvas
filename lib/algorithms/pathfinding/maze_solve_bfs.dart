import 'dart:collection';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';
import 'package:algo_canvas/algorithms/pathfinding/grid_state.dart';
import 'package:algo_canvas/algorithms/pathfinding/grid_painter.dart';
import 'package:algo_canvas/algorithms/pathfinding/pathfinding_legend.dart';
import 'package:algo_canvas/widgets/color_legend.dart';

class MazeSolveBfsAlgorithm extends Algorithm {
  int _mazeSize = 12;

  @override
  String get name => 'Maze Solve (BFS)';

  @override
  String get description =>
      'BFS guarantees the shortest path through any maze.';

  @override
  AlgorithmCategory get category => AlgorithmCategory.pathfinding;

  @override
  Future<List<AlgorithmState>> generate() async {
    final random = Random();
    final mazeW = _mazeSize, mazeH = _mazeSize;
    final rows = mazeH * 2 + 1;
    final cols = mazeW * 2 + 1;

    // Generate maze (recursive backtracker)
    final grid = List.filled(rows * cols, TileType.wall);
    int gr(int mr) => mr * 2 + 1;
    int gc(int mc) => mc * 2 + 1;

    final visited = List.generate(mazeH, (_) => List.filled(mazeW, false));
    final stack = <(int, int)>[];
    visited[0][0] = true;
    grid[gr(0) * cols + gc(0)] = TileType.empty;
    stack.add((0, 0));
    const dirs = [(0, -1), (0, 1), (-1, 0), (1, 0)];

    while (stack.isNotEmpty) {
      final (cr, cc) = stack.last;
      final neighbors = <(int, int)>[];
      for (final (dr, dc) in dirs) {
        final nr = cr + dr, nc = cc + dc;
        if (nr >= 0 && nr < mazeH && nc >= 0 && nc < mazeW && !visited[nr][nc]) {
          neighbors.add((nr, nc));
        }
      }
      if (neighbors.isEmpty) {
        stack.removeLast();
      } else {
        final (nr, nc) = neighbors[random.nextInt(neighbors.length)];
        visited[nr][nc] = true;
        grid[(gr(cr) + (nr - cr)) * cols + (gc(cc) + (nc - cc))] = TileType.empty;
        grid[gr(nr) * cols + gc(nc)] = TileType.empty;
        stack.add((nr, nc));
      }
    }

    final startIdx = gr(0) * cols + gc(0);
    final endIdx = gr(mazeH - 1) * cols + gc(mazeW - 1);
    grid[startIdx] = TileType.start;
    grid[endIdx] = TileType.end;

    final states = <GridState>[];
    var step = 0;
    states.add(GridState(grid: List.of(grid), rows: rows, cols: cols, step: step,
      description: 'BFS maze solving'));

    // BFS
    final queue = Queue<int>();
    final cameFrom = List.filled(rows * cols, -1);
    final bfsVisited = List.filled(rows * cols, false);
    queue.add(startIdx);
    bfsVisited[startIdx] = true;

    var found = false;
    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      final cr = current ~/ cols, cc = current % cols;

      if (current == endIdx) { found = true; break; }

      if (grid[current] != TileType.start) { grid[current] = TileType.visited; }

      for (final (dr, dc) in dirs) {
        final nr = cr + dr, nc = cc + dc;
        if (nr < 0 || nr >= rows || nc < 0 || nc >= cols) { continue; }
        final nIdx = nr * cols + nc;
        if (bfsVisited[nIdx] || grid[nIdx] == TileType.wall) { continue; }

        bfsVisited[nIdx] = true;
        cameFrom[nIdx] = current;
        queue.add(nIdx);
        if (grid[nIdx] != TileType.end) { grid[nIdx] = TileType.queued; }
      }

      step++;
      if (step % 3 == 0) {
        states.add(GridState(grid: List.of(grid), rows: rows, cols: cols, step: step,
          description: 'Step $step: exploring...'));
      }
    }

    // Reconstruct path
    if (found) {
      var c = endIdx;
      var pathLen = 0;
      while (c != startIdx) {
        if (grid[c] != TileType.start && grid[c] != TileType.end) {
          grid[c] = TileType.path;
        }
        c = cameFrom[c];
        pathLen++;
      }
      states.add(GridState(grid: List.of(grid), rows: rows, cols: cols, step: step,
        description: 'Shortest path found! Length: $pathLen'));
    } else {
      states.add(GridState(grid: List.of(grid), rows: rows, cols: cols, step: step,
        description: 'No path found!'));
    }

    return states;
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) =>
      GridPainter(state: state as GridState, brightness: Theme.of(context).brightness);

  @override
  List<LegendItem>? buildLegend(BuildContext context) => pathfindingLegend(context);

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
    Expanded(child: Slider(value: _v, min: 5, max: 25, divisions: 20,
      onChanged: (v) => setState(() => _v = v), onChangeEnd: (v) => widget.onChanged(v.round()))),
  ]);
}
