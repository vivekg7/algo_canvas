import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';
import 'package:algo_canvas/algorithms/pathfinding/grid_state.dart';
import 'package:algo_canvas/algorithms/pathfinding/grid_painter.dart';

class InteractivePathState extends AlgorithmState {
  const InteractivePathState({
    required this.grid,
    required this.rows,
    required this.cols,
    required this.startR,
    required this.startC,
    required this.endR,
    required this.endC,
    required this.drawing,
    required super.description,
  });
  final List<TileType> grid;
  final int rows, cols;
  final int startR, startC, endR, endC;
  final bool drawing; // true = drawing walls, false = erasing
}

class InteractivePathfindingAlgorithm extends Algorithm {
  static const _gridSize = 20;

  @override String get name => 'Interactive Pathfinding';
  @override String get description => 'Draw walls, then path auto-solves via A*. Drag to paint/erase walls.';
  @override AlgorithmCategory get category => AlgorithmCategory.pathfinding;
  @override AlgorithmMode get mode => AlgorithmMode.interactive;

  @override
  AlgorithmState createInitialState() {
    final grid = List.filled(_gridSize * _gridSize, TileType.empty);
    grid[1 * _gridSize + 1] = TileType.start;
    grid[(_gridSize - 2) * _gridSize + (_gridSize - 2)] = TileType.end;
    return _solve(InteractivePathState(
      grid: grid, rows: _gridSize, cols: _gridSize,
      startR: 1, startC: 1, endR: _gridSize - 2, endC: _gridSize - 2,
      drawing: true, description: 'Draw walls. Path auto-updates.',
    ));
  }

  @override
  AlgorithmState? onInteractionStart(AlgorithmState current, Offset localPosition) =>
      _handleDraw(current as InteractivePathState, localPosition);

  @override
  AlgorithmState? onInteractionUpdate(AlgorithmState current, Offset localPosition) =>
      _handleDraw(current as InteractivePathState, localPosition);

  AlgorithmState? _handleDraw(InteractivePathState s, Offset pos) {
    final col = (pos.dx * s.cols).floor().clamp(0, s.cols - 1);
    final row = (pos.dy * s.rows).floor().clamp(0, s.rows - 1);
    final idx = row * s.cols + col;

    // Don't overwrite start/end
    if (s.grid[idx] == TileType.start || s.grid[idx] == TileType.end) return null;

    final newGrid = List<TileType>.of(s.grid);
    // Toggle: if first touch hits a wall, erase; otherwise draw
    newGrid[idx] = s.grid[idx] == TileType.wall ? TileType.empty : TileType.wall;

    // Clear old path/visited
    for (var i = 0; i < newGrid.length; i++) {
      if (newGrid[i] == TileType.path || newGrid[i] == TileType.visited || newGrid[i] == TileType.queued) {
        newGrid[i] = TileType.empty;
      }
    }

    return _solve(InteractivePathState(
      grid: newGrid, rows: s.rows, cols: s.cols,
      startR: s.startR, startC: s.startC, endR: s.endR, endC: s.endC,
      drawing: s.drawing, description: 'Draw walls. Path auto-updates.',
    ));
  }

  InteractivePathState _solve(InteractivePathState s) {
    final grid = List<TileType>.of(s.grid);
    final rows = s.rows, cols = s.cols;
    final startIdx = s.startR * cols + s.startC;
    final endIdx = s.endR * cols + s.endC;

    // BFS to find shortest path
    final visited = List.filled(rows * cols, false);
    final cameFrom = List.filled(rows * cols, -1);
    final queue = Queue<int>();
    queue.add(startIdx);
    visited[startIdx] = true;
    const dirs = [(-1, 0), (1, 0), (0, -1), (0, 1)];

    var found = false;
    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      if (current == endIdx) { found = true; break; }
      final cr = current ~/ cols, cc = current % cols;
      for (final (dr, dc) in dirs) {
        final nr = cr + dr, nc = cc + dc;
        if (nr < 0 || nr >= rows || nc < 0 || nc >= cols) continue;
        final nIdx = nr * cols + nc;
        if (visited[nIdx] || grid[nIdx] == TileType.wall) continue;
        visited[nIdx] = true;
        cameFrom[nIdx] = current;
        queue.add(nIdx);
      }
    }

    if (found) {
      var c = endIdx;
      while (c != startIdx) {
        if (grid[c] != TileType.start && grid[c] != TileType.end) {
          grid[c] = TileType.path;
        }
        c = cameFrom[c];
      }
    }

    // Restore start/end
    grid[startIdx] = TileType.start;
    grid[endIdx] = TileType.end;

    return InteractivePathState(
      grid: grid, rows: rows, cols: cols,
      startR: s.startR, startC: s.startC, endR: s.endR, endC: s.endC,
      drawing: s.drawing,
      description: found ? 'Path found! Draw more walls.' : 'No path. Remove some walls.',
    );
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) {
    final s = state as InteractivePathState;
    // Convert to GridState for the shared painter
    return GridPainter(
      state: GridState(grid: s.grid, rows: s.rows, cols: s.cols, step: 0, description: s.description),
      brightness: Theme.of(context).brightness,
    );
  }
}
