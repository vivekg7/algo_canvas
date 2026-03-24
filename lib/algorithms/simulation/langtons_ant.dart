import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';

class LangtonsAntState extends AlgorithmState {
  const LangtonsAntState({
    required this.grid,
    required this.rows,
    required this.cols,
    required this.antRow,
    required this.antCol,
    required this.antDirection,
    required this.step,
    this.finished = false,
    required super.description,
  });

  final List<List<bool>> grid; // true = black
  final int rows;
  final int cols;
  final int antRow;
  final int antCol;
  final int antDirection; // 0=up, 1=right, 2=down, 3=left
  final int step;
  final bool finished;
}

class LangtonsAntAlgorithm extends Algorithm {
  int _gridSize = 80;

  @override
  String get name => "Langton's Ant";

  @override
  String get description =>
      'Simple rules produce complex emergent behavior on a grid.';

  @override
  AlgorithmCategory get category => AlgorithmCategory.physicsSimulation;

  @override
  AlgorithmMode get mode => AlgorithmMode.live;

  @override
  AlgorithmState createInitialState() {
    final rows = _gridSize;
    final cols = _gridSize;
    final grid = List.generate(rows, (_) => List.generate(cols, (_) => false));

    return LangtonsAntState(
      grid: grid,
      rows: rows,
      cols: cols,
      antRow: rows ~/ 2,
      antCol: cols ~/ 2,
      antDirection: 0,
      step: 0,
      description: 'Step 0: ant starts at center facing up',
    );
  }

  @override
  AlgorithmState? tick(AlgorithmState current) {
    final s = current as LangtonsAntState;
    if (s.finished) return null;

    final rows = s.rows;
    final cols = s.cols;
    final grid = [for (final row in s.grid) List<bool>.of(row)];
    var antR = s.antRow;
    var antC = s.antCol;
    var dir = s.antDirection;

    // Rule: on white turn right, on black turn left
    if (grid[antR][antC]) {
      dir = (dir + 3) % 4; // left
    } else {
      dir = (dir + 1) % 4; // right
    }

    // Flip
    grid[antR][antC] = !grid[antR][antC];

    // Move
    switch (dir) {
      case 0: antR--;
      case 1: antC++;
      case 2: antR++;
      case 3: antC--;
    }

    final step = s.step + 1;

    // Check bounds
    if (antR < 0 || antR >= rows || antC < 0 || antC >= cols) {
      return LangtonsAntState(
        grid: grid,
        rows: rows,
        cols: cols,
        antRow: antR.clamp(0, rows - 1),
        antCol: antC.clamp(0, cols - 1),
        antDirection: dir,
        step: step,
        finished: true,
        description: 'Step $step: ant left the grid',
      );
    }

    return LangtonsAntState(
      grid: grid,
      rows: rows,
      cols: cols,
      antRow: antR,
      antCol: antC,
      antDirection: dir,
      step: step,
      description: 'Step $step',
    );
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
    return _GridSizeControl(
      gridSize: _gridSize,
      onChanged: (size) {
        _gridSize = size;
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

    canvas.drawRect(
      Rect.fromLTWH(offsetX, offsetY, cellSize * cols, cellSize * rows),
      Paint()..color = whiteCell,
    );

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

    // Ant
    final antCenter = Offset(
      offsetX + state.antCol * cellSize + cellSize / 2,
      offsetY + state.antRow * cellSize + cellSize / 2,
    );

    if (cellSize >= 4) {
      canvas.drawCircle(antCenter, cellSize * 0.4, Paint()..color = antColor);
      if (cellSize >= 8) {
        final tp = TextPainter(
          text: TextSpan(
            text: _dirArrows[state.antDirection],
            style: TextStyle(fontSize: cellSize * 0.5, color: Colors.white),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, antCenter - Offset(tp.width / 2, tp.height / 2));
      }
    } else {
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

class _GridSizeControl extends StatefulWidget {
  const _GridSizeControl({required this.gridSize, required this.onChanged});
  final int gridSize;
  final ValueChanged<int> onChanged;

  @override
  State<_GridSizeControl> createState() => _GridSizeControlState();
}

class _GridSizeControlState extends State<_GridSizeControl> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.gridSize.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('Grid: ${_value.round()}×${_value.round()}',
            style: Theme.of(context).textTheme.bodySmall),
        Expanded(
          child: Slider(
            value: _value,
            min: 20,
            max: 150,
            divisions: 26,
            onChanged: (v) => setState(() => _value = v),
            onChangeEnd: (v) => widget.onChanged(v.round()),
          ),
        ),
      ],
    );
  }
}
