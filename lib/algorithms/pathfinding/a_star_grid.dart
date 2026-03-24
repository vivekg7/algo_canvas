import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';
import 'package:algo_canvas/algorithms/pathfinding/grid_state.dart';
import 'package:algo_canvas/algorithms/pathfinding/grid_painter.dart';
import 'package:algo_canvas/algorithms/pathfinding/pathfinding_legend.dart';
import 'package:algo_canvas/widgets/color_legend.dart';

class AStarGridAlgorithm extends Algorithm {
  int _gridSize = 25;
  double _wallDensity = 0.3;

  @override
  String get name => 'A* Grid';

  @override
  String get description =>
      'A* pathfinding on a grid with obstacles using Manhattan heuristic.';

  @override
  AlgorithmCategory get category => AlgorithmCategory.pathfinding;

  @override
  Future<List<AlgorithmState>> generate() async {
    final random = Random();
    final rows = _gridSize;
    final cols = _gridSize;
    final grid = List.filled(rows * cols, TileType.empty);

    // Random walls
    for (var i = 0; i < rows * cols; i++) {
      if (random.nextDouble() < _wallDensity) {
        grid[i] = TileType.wall;
      }
    }

    // Start (top-left area) and end (bottom-right area)
    const startR = 1, startC = 1;
    final endR = rows - 2, endC = cols - 2;
    grid[startR * cols + startC] = TileType.start;
    grid[endR * cols + endC] = TileType.end;
    // Clear area around start/end
    for (var dr = -1; dr <= 1; dr++) {
      for (var dc = -1; dc <= 1; dc++) {
        final sr = startR + dr, sc = startC + dc;
        final er = endR + dr, ec = endC + dc;
        if (sr >= 0 && sr < rows && sc >= 0 && sc < cols) {
          if (grid[sr * cols + sc] == TileType.wall) { grid[sr * cols + sc] = TileType.empty; }
        }
        if (er >= 0 && er < rows && ec >= 0 && ec < cols) {
          if (grid[er * cols + ec] == TileType.wall) { grid[er * cols + ec] = TileType.empty; }
        }
      }
    }

    final states = <GridState>[];
    states.add(GridState(grid: List.of(grid), rows: rows, cols: cols, step: 0,
      description: 'A* from ($startR,$startC) to ($endR,$endC)'));

    // A* search
    final gScore = List.filled(rows * cols, double.infinity);
    final fScore = List.filled(rows * cols, double.infinity);
    final cameFrom = List.filled(rows * cols, -1);
    final openSet = <int>{};
    final closedSet = <int>{};

    int heuristic(int idx) {
      final r = idx ~/ cols, c = idx % cols;
      return (r - endR).abs() + (c - endC).abs();
    }

    final startIdx = startR * cols + startC;
    final endIdx = endR * cols + endC;
    gScore[startIdx] = 0;
    fScore[startIdx] = heuristic(startIdx).toDouble();
    openSet.add(startIdx);

    var step = 0;
    const dirs = [(-1, 0), (1, 0), (0, -1), (0, 1)];

    while (openSet.isNotEmpty) {
      // Find node with lowest fScore
      var current = openSet.first;
      for (final node in openSet) {
        if (fScore[node] < fScore[current]) { current = node; }
      }

      if (current == endIdx) {
        // Reconstruct path
        var c = current;
        while (c != startIdx) {
          if (grid[c] != TileType.start && grid[c] != TileType.end) {
            grid[c] = TileType.path;
          }
          c = cameFrom[c];
        }
        step++;
        states.add(GridState(grid: List.of(grid), rows: rows, cols: cols, step: step,
          description: 'Path found! Length: ${gScore[endIdx].round()}'));
        return states;
      }

      openSet.remove(current);
      closedSet.add(current);
      if (grid[current] != TileType.start) { grid[current] = TileType.visited; }

      final cr = current ~/ cols, cc = current % cols;
      for (final (dr, dc) in dirs) {
        final nr = cr + dr, nc = cc + dc;
        if (nr < 0 || nr >= rows || nc < 0 || nc >= cols) { continue; }
        final nIdx = nr * cols + nc;
        if (closedSet.contains(nIdx) || grid[nIdx] == TileType.wall) { continue; }

        final tentativeG = gScore[current] + 1;
        if (tentativeG < gScore[nIdx]) {
          cameFrom[nIdx] = current;
          gScore[nIdx] = tentativeG;
          fScore[nIdx] = tentativeG + heuristic(nIdx);
          openSet.add(nIdx);
          if (grid[nIdx] != TileType.end) { grid[nIdx] = TileType.queued; }
        }
      }

      step++;
      if (step % 3 == 0) {
        states.add(GridState(grid: List.of(grid), rows: rows, cols: cols, step: step,
          description: 'Step $step: exploring...'));
      }
    }

    states.add(GridState(grid: List.of(grid), rows: rows, cols: cols, step: step,
      description: 'No path found!'));
    return states;
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) =>
      GridPainter(state: state as GridState, brightness: Theme.of(context).brightness);

  @override
  List<LegendItem>? buildLegend(BuildContext context) => pathfindingLegend(context);

  @override
  Widget? buildControls({required VoidCallback onChanged}) =>
      _Controls(gridSize: _gridSize, wallDensity: _wallDensity, onChanged: (s, w) {
        _gridSize = s; _wallDensity = w; onChanged();
      });
}

class _Controls extends StatefulWidget {
  const _Controls({required this.gridSize, required this.wallDensity, required this.onChanged});
  final int gridSize; final double wallDensity;
  final void Function(int, double) onChanged;
  @override State<_Controls> createState() => _ControlsState();
}
class _ControlsState extends State<_Controls> {
  late double _size, _density;
  @override void initState() { super.initState(); _size = widget.gridSize.toDouble(); _density = widget.wallDensity; }
  @override Widget build(BuildContext context) {
    final ts = Theme.of(context).textTheme.bodySmall;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Row(children: [
        Text('Grid: ${_size.round()}×${_size.round()}', style: ts),
        Expanded(child: Slider(value: _size, min: 10, max: 50, divisions: 20,
          onChanged: (v) => setState(() => _size = v),
          onChangeEnd: (v) => widget.onChanged(v.round(), _density))),
      ]),
      Row(children: [
        Text('Walls: ${(_density * 100).round()}%', style: ts),
        Expanded(child: Slider(value: _density, min: 0.1, max: 0.45, divisions: 7,
          onChanged: (v) => setState(() => _density = v),
          onChangeEnd: (v) => widget.onChanged(_size.round(), v))),
      ]),
    ]);
  }
}
