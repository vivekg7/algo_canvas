import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';
import 'package:algo_canvas/algorithms/pathfinding/grid_state.dart';
import 'package:algo_canvas/algorithms/pathfinding/grid_painter.dart';
import 'package:algo_canvas/algorithms/pathfinding/pathfinding_legend.dart';
import 'package:algo_canvas/widgets/color_legend.dart';

class MazeSolveWallFollowerAlgorithm extends Algorithm {
  int _mazeSize = 12;

  @override
  String get name => 'Maze Solve (Wall Follower)';

  @override
  String get description =>
      'Right-hand rule: keep right wall touching to navigate any simply-connected maze.';

  @override
  AlgorithmCategory get category => AlgorithmCategory.pathfinding;

  @override
  Future<List<AlgorithmState>> generate() async {
    final random = Random();
    final mazeW = _mazeSize, mazeH = _mazeSize;
    final rows = mazeH * 2 + 1;
    final cols = mazeW * 2 + 1;

    // Generate maze first (recursive backtracker)
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

    final startR = gr(0), startC = gc(0);
    final endR = gr(mazeH - 1), endC = gc(mazeW - 1);
    grid[startR * cols + startC] = TileType.start;
    grid[endR * cols + endC] = TileType.end;

    final states = <GridState>[];
    var step = 0;
    states.add(GridState(grid: List.of(grid), rows: rows, cols: cols, step: step,
      description: 'Wall follower: right-hand rule'));

    // Solve: right-hand wall follower
    // Directions: 0=up, 1=right, 2=down, 3=left
    const dr = [-1, 0, 1, 0];
    const dc = [0, 1, 0, -1];
    var r = startR, c = startC;
    var dir = 1; // start facing right

    final maxSteps = rows * cols * 4;
    for (var s = 0; s < maxSteps; s++) {
      if (r == endR && c == endC) { break; }

      // Try right, forward, left, back
      final rightDir = (dir + 1) % 4;
      final leftDir = (dir + 3) % 4;
      final backDir = (dir + 2) % 4;

      int nr, nc;

      // Try turning right
      nr = r + dr[rightDir];
      nc = c + dc[rightDir];
      if (nr >= 0 && nr < rows && nc >= 0 && nc < cols && grid[nr * cols + nc] != TileType.wall) {
        dir = rightDir;
        r = nr; c = nc;
      } else {
        // Try going straight
        nr = r + dr[dir];
        nc = c + dc[dir];
        if (nr >= 0 && nr < rows && nc >= 0 && nc < cols && grid[nr * cols + nc] != TileType.wall) {
          r = nr; c = nc;
        } else {
          // Try turning left
          nr = r + dr[leftDir];
          nc = c + dc[leftDir];
          if (nr >= 0 && nr < rows && nc >= 0 && nc < cols && grid[nr * cols + nc] != TileType.wall) {
            dir = leftDir;
            r = nr; c = nc;
          } else {
            // Turn back
            dir = backDir;
            r = r + dr[dir]; c = c + dc[dir];
          }
        }
      }

      if (grid[r * cols + c] != TileType.start && grid[r * cols + c] != TileType.end) {
        grid[r * cols + c] = TileType.path;
      }

      step++;
      if (step % 2 == 0) {
        states.add(GridState(grid: List.of(grid), rows: rows, cols: cols, step: step,
          description: 'Step $step: at ($r, $c)'));
      }
    }

    states.add(GridState(grid: List.of(grid), rows: rows, cols: cols, step: step,
      description: r == endR && c == endC ? 'Maze solved!' : 'Could not reach end'));

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
    Expanded(child: Slider(value: _v, min: 5, max: 25, divisions: 20,
      onChanged: (v) => setState(() => _v = v), onChangeEnd: (v) => widget.onChanged(v.round()))),
  ]);
}
