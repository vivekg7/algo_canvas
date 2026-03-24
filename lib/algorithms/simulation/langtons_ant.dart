import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';

enum _Direction { up, right, down, left }

class LangtonsAntState extends AlgorithmState {
  const LangtonsAntState({
    required this.grid,
    required this.rows,
    required this.cols,
    required this.antRow,
    required this.antCol,
    required this.antDirection,
    required this.step,
    required super.description,
  });

  final List<List<bool>> grid; // true = black
  final int rows;
  final int cols;
  final int antRow;
  final int antCol;
  final int antDirection; // 0=up, 1=right, 2=down, 3=left
  final int step;
}

class LangtonsAntAlgorithm extends Algorithm {
  int _gridSize = 80;
  int _maxSteps = 5000;

  @override
  String get name => "Langton's Ant";

  @override
  String get description =>
      'Simple rules produce complex emergent behavior on a grid.';

  @override
  AlgorithmCategory get category => AlgorithmCategory.physicsSimulation;

  @override
  bool get isStreaming => true;

  @override
  Stream<AlgorithmState> stream() async* {
    final rows = _gridSize;
    final cols = _gridSize;
    final grid = List.generate(rows, (_) => List.generate(cols, (_) => false));

    var antR = rows ~/ 2;
    var antC = cols ~/ 2;
    var dir = _Direction.up;

    yield LangtonsAntState(
      grid: _copyGrid(grid),
      rows: rows,
      cols: cols,
      antRow: antR,
      antCol: antC,
      antDirection: dir.index,
      step: 0,
      description: 'Step 0: ant starts at center facing up',
    );

    for (var step = 1; step <= _maxSteps; step++) {
      // Yield to event loop periodically
      if (step % 10 == 0) {
        await Future<void>.delayed(Duration.zero);
      }

      // Rule: on white, turn right. On black, turn left.
      if (grid[antR][antC]) {
        // Black → turn left
        dir = _Direction.values[(dir.index + 3) % 4];
      } else {
        // White → turn right
        dir = _Direction.values[(dir.index + 1) % 4];
      }

      // Flip the cell
      grid[antR][antC] = !grid[antR][antC];

      // Move forward
      switch (dir) {
        case _Direction.up:
          antR--;
        case _Direction.right:
          antC++;
        case _Direction.down:
          antR++;
        case _Direction.left:
          antC--;
      }

      // Stop if ant leaves the grid
      if (antR < 0 || antR >= rows || antC < 0 || antC >= cols) {
        yield LangtonsAntState(
          grid: _copyGrid(grid),
          rows: rows,
          cols: cols,
          antRow: antR.clamp(0, rows - 1),
          antCol: antC.clamp(0, cols - 1),
          antDirection: dir.index,
          step: step,
          description: 'Step $step: ant left the grid',
        );
        break;
      }

      // Only yield every few steps for large grids to keep state count manageable
      final emitInterval = _gridSize >= 100 ? 5 : 1;
      if (step % emitInterval == 0 || step == _maxSteps) {
        yield LangtonsAntState(
          grid: _copyGrid(grid),
          rows: rows,
          cols: cols,
          antRow: antR,
          antCol: antC,
          antDirection: dir.index,
          step: step,
          description: 'Step $step',
        );
      }
    }
  }

  List<List<bool>> _copyGrid(List<List<bool>> grid) {
    return [for (final row in grid) List<bool>.of(row)];
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) {
    return _LangtonsAntPainter(
      state: state as LangtonsAntState,
      brightness: Theme.of(context).brightness,
    );
  }

  @override
  Widget? buildControls({required VoidCallback onChanged}) {
    return _Controls(
      gridSize: _gridSize,
      maxSteps: _maxSteps,
      onChanged: (size, steps) {
        _gridSize = size;
        _maxSteps = steps;
        onChanged();
      },
    );
  }
}

class _LangtonsAntPainter extends CustomPainter {
  _LangtonsAntPainter({required this.state, required this.brightness});

  final LangtonsAntState state;
  final Brightness brightness;

  static const _dirArrows = ['↑', '→', '↓', '←'];

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
    final whiteCell = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5);
    final blackCell = isDark ? const Color(0xFFB0BEC5) : const Color(0xFF37474F);
    final antColor = isDark
        ? const Color(0xFFEF5350)
        : const Color(0xFFD32F2F);

    // Background
    canvas.drawRect(
      Rect.fromLTWH(offsetX, offsetY, cellSize * cols, cellSize * rows),
      Paint()..color = whiteCell,
    );

    // Draw black cells
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if (state.grid[r][c]) {
          canvas.drawRect(
            Rect.fromLTWH(
              offsetX + c * cellSize,
              offsetY + r * cellSize,
              cellSize,
              cellSize,
            ),
            Paint()..color = blackCell,
          );
        }
      }
    }

    // Draw ant
    final antCenter = Offset(
      offsetX + state.antCol * cellSize + cellSize / 2,
      offsetY + state.antRow * cellSize + cellSize / 2,
    );

    if (cellSize >= 4) {
      canvas.drawCircle(
        antCenter,
        cellSize * 0.4,
        Paint()..color = antColor,
      );

      if (cellSize >= 8) {
        final tp = TextPainter(
          text: TextSpan(
            text: _dirArrows[state.antDirection],
            style: TextStyle(
              fontSize: cellSize * 0.5,
              color: Colors.white,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(
          canvas,
          antCenter - Offset(tp.width / 2, tp.height / 2),
        );
      }
    } else {
      // Tiny cells: just draw a colored dot
      canvas.drawRect(
        Rect.fromLTWH(
          offsetX + state.antCol * cellSize,
          offsetY + state.antRow * cellSize,
          cellSize,
          cellSize,
        ),
        Paint()..color = antColor,
      );
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
  bool shouldRepaint(covariant _LangtonsAntPainter oldDelegate) {
    return oldDelegate.state != state;
  }
}

class _Controls extends StatefulWidget {
  const _Controls({
    required this.gridSize,
    required this.maxSteps,
    required this.onChanged,
  });

  final int gridSize;
  final int maxSteps;
  final void Function(int size, int steps) onChanged;

  @override
  State<_Controls> createState() => _ControlsState();
}

class _ControlsState extends State<_Controls> {
  late double _sizeValue;
  late double _stepsValue;

  @override
  void initState() {
    super.initState();
    _sizeValue = widget.gridSize.toDouble();
    _stepsValue = widget.maxSteps.toDouble();
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
                min: 20,
                max: 150,
                divisions: 26,
                onChanged: (v) => setState(() => _sizeValue = v),
                onChangeEnd: (v) =>
                    widget.onChanged(v.round(), _stepsValue.round()),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Text('Steps: ${_stepsValue.round()}', style: textStyle),
            Expanded(
              child: Slider(
                value: _stepsValue,
                min: 1000,
                max: 15000,
                divisions: 28,
                onChanged: (v) => setState(() => _stepsValue = v),
                onChangeEnd: (v) =>
                    widget.onChanged(_sizeValue.round(), v.round()),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
