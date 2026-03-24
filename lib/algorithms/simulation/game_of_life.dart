import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';

class GameOfLifeState extends AlgorithmState {
  const GameOfLifeState({
    required this.grid,
    required this.rows,
    required this.cols,
    required this.generation,
    required this.liveCells,
    this.born = const {},
    this.died = const {},
    required super.description,
  });

  final List<List<bool>> grid;
  final int rows;
  final int cols;
  final int generation;
  final int liveCells;

  /// Cells that were just born this generation.
  final Set<(int, int)> born;

  /// Cells that just died this generation.
  final Set<(int, int)> died;
}

class GameOfLifeAlgorithm extends Algorithm {
  int _gridSize = 40;
  double _density = 0.3;

  @override
  String get name => "Conway's Game of Life";

  @override
  String get description =>
      'Cellular automaton where cells live or die based on neighbor count.';

  @override
  AlgorithmCategory get category => AlgorithmCategory.physicsSimulation;

  @override
  bool get isStreaming => true;

  @override
  Stream<AlgorithmState> stream() async* {
    final random = Random();
    final rows = _gridSize;
    final cols = _gridSize;

    // Initialize with random cells
    var grid = List.generate(
      rows,
      (_) => List.generate(cols, (_) => random.nextDouble() < _density),
    );

    var generation = 0;
    var liveCells = _countLive(grid, rows, cols);

    yield GameOfLifeState(
      grid: _copyGrid(grid),
      rows: rows,
      cols: cols,
      generation: generation,
      liveCells: liveCells,
      description: 'Generation 0: $liveCells live cells',
    );

    // Keep previous two grids for stability detection
    final history = <List<List<bool>>>[_copyGrid(grid)];

    for (var gen = 1; gen <= 2000; gen++) {
      // Yield to the event loop so the UI stays responsive
      await Future<void>.delayed(Duration.zero);
      final newGrid = List.generate(
        rows,
        (_) => List.generate(cols, (_) => false),
      );
      final born = <(int, int)>{};
      final died = <(int, int)>{};

      for (var r = 0; r < rows; r++) {
        for (var c = 0; c < cols; c++) {
          final neighbors = _countNeighbors(grid, rows, cols, r, c);
          if (grid[r][c]) {
            newGrid[r][c] = neighbors == 2 || neighbors == 3;
            if (!newGrid[r][c]) died.add((r, c));
          } else {
            newGrid[r][c] = neighbors == 3;
            if (newGrid[r][c]) born.add((r, c));
          }
        }
      }

      history.add(_copyGrid(grid));
      if (history.length > 3) history.removeAt(0);

      grid = newGrid;
      generation = gen;
      liveCells = _countLive(grid, rows, cols);

      // Detect stability: still life (matches previous) or
      // period-2 oscillator (matches two generations ago)
      final isStill = _gridsEqual(grid, history.last, rows, cols);
      final isOscillator = history.length >= 2 &&
          _gridsEqual(grid, history[history.length - 2], rows, cols);

      String desc;
      if (liveCells == 0) {
        desc = 'Generation $gen: all cells dead — extinction';
      } else if (isStill) {
        desc = 'Generation $gen: stable — still life ($liveCells cells)';
      } else if (isOscillator) {
        desc = 'Generation $gen: stable — period-2 oscillator ($liveCells cells)';
      } else {
        desc = 'Generation $gen: $liveCells live cells';
      }

      yield GameOfLifeState(
        grid: _copyGrid(grid),
        rows: rows,
        cols: cols,
        generation: generation,
        liveCells: liveCells,
        born: born,
        died: died,
        description: desc,
      );

      if (liveCells == 0 || isStill || isOscillator) break;
    }
  }

  int _countNeighbors(
      List<List<bool>> grid, int rows, int cols, int r, int c) {
    var count = 0;
    for (var dr = -1; dr <= 1; dr++) {
      for (var dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        final nr = r + dr;
        final nc = c + dc;
        if (nr >= 0 && nr < rows && nc >= 0 && nc < cols && grid[nr][nc]) {
          count++;
        }
      }
    }
    return count;
  }

  int _countLive(List<List<bool>> grid, int rows, int cols) {
    var count = 0;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if (grid[r][c]) count++;
      }
    }
    return count;
  }

  bool _gridsEqual(
      List<List<bool>> a, List<List<bool>> b, int rows, int cols) {
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if (a[r][c] != b[r][c]) return false;
      }
    }
    return true;
  }

  List<List<bool>> _copyGrid(List<List<bool>> grid) {
    return [for (final row in grid) List<bool>.of(row)];
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) {
    return _GameOfLifePainter(
      state: state as GameOfLifeState,
      brightness: Theme.of(context).brightness,
    );
  }

  @override
  Widget? buildControls({required VoidCallback onChanged}) {
    return _Controls(
      gridSize: _gridSize,
      density: _density,
      onChanged: (size, density) {
        _gridSize = size;
        _density = density;
        onChanged();
      },
    );
  }
}

class _GameOfLifePainter extends CustomPainter {
  _GameOfLifePainter({required this.state, required this.brightness});

  final GameOfLifeState state;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final rows = state.rows;
    final cols = state.cols;
    final cellW = size.width / cols;
    final cellH = size.height / rows;
    final cellSize = cellW < cellH ? cellW : cellH;
    final offsetX = (size.width - cellSize * cols) / 2;
    final offsetY = (size.height - cellSize * rows) / 2;

    final isDark = brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5);
    final aliveColor = isDark ? const Color(0xFF4CAF50) : const Color(0xFF388E3C);
    final bornColor = isDark ? const Color(0xFF81C784) : const Color(0xFF66BB6A);
    final diedColor = isDark
        ? const Color(0xFFEF5350).withValues(alpha: 0.3)
        : const Color(0xFFD32F2F).withValues(alpha: 0.2);

    // Background
    canvas.drawRect(
      Rect.fromLTWH(offsetX, offsetY, cellSize * cols, cellSize * rows),
      Paint()..color = bgColor,
    );

    // Draw cells
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final rect = Rect.fromLTWH(
          offsetX + c * cellSize,
          offsetY + r * cellSize,
          cellSize - (cellSize > 4 ? 0.5 : 0),
          cellSize - (cellSize > 4 ? 0.5 : 0),
        );

        if (state.grid[r][c]) {
          final color = state.born.contains((r, c)) ? bornColor : aliveColor;
          canvas.drawRect(rect, Paint()..color = color);
        } else if (state.died.contains((r, c))) {
          canvas.drawRect(rect, Paint()..color = diedColor);
        }
      }
    }

    // Border
    canvas.drawRect(
      Rect.fromLTWH(offsetX, offsetY, cellSize * cols, cellSize * rows),
      Paint()
        ..color = isDark ? Colors.white12 : Colors.black12
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );
  }

  @override
  bool shouldRepaint(covariant _GameOfLifePainter oldDelegate) {
    return oldDelegate.state != state;
  }
}

class _Controls extends StatefulWidget {
  const _Controls({
    required this.gridSize,
    required this.density,
    required this.onChanged,
  });

  final int gridSize;
  final double density;
  final void Function(int size, double density) onChanged;

  @override
  State<_Controls> createState() => _ControlsState();
}

class _ControlsState extends State<_Controls> {
  late double _sizeValue;
  late double _densityValue;

  @override
  void initState() {
    super.initState();
    _sizeValue = widget.gridSize.toDouble();
    _densityValue = widget.density;
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodySmall;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text('Grid: ${_sizeValue.round()}×${_sizeValue.round()}',
                style: textStyle),
            Expanded(
              child: Slider(
                value: _sizeValue,
                min: 10,
                max: 150,
                divisions: 28,
                onChanged: (v) => setState(() => _sizeValue = v),
                onChangeEnd: (v) =>
                    widget.onChanged(v.round(), _densityValue),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Text('Density: ${(_densityValue * 100).round()}%',
                style: textStyle),
            Expanded(
              child: Slider(
                value: _densityValue,
                min: 0.1,
                max: 0.6,
                divisions: 10,
                onChanged: (v) => setState(() => _densityValue = v),
                onChangeEnd: (v) =>
                    widget.onChanged(_sizeValue.round(), v),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
