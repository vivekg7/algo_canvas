import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';

class NQueensState extends AlgorithmState {
  const NQueensState({
    required this.boardSize,
    required this.queens,
    this.currentRow,
    this.currentCol,
    this.conflicts = const {},
    this.solved = false,
    required super.description,
  });

  final int boardSize;

  /// Map of row -> column for placed queens.
  final Map<int, int> queens;
  final int? currentRow;
  final int? currentCol;

  /// Set of (row, col) positions that conflict.
  final Set<(int, int)> conflicts;
  final bool solved;
}

class NQueensAlgorithm extends Algorithm {
  int _boardSize = 8;

  @override
  String get name => 'N-Queens';

  @override
  String get description =>
      'Place N queens on an N×N board so none threaten each other.';

  @override
  AlgorithmCategory get category => AlgorithmCategory.backtracking;

  @override
  Future<List<AlgorithmState>> generate() async {
    final states = <NQueensState>[];
    final queens = <int, int>{};

    states.add(NQueensState(
      boardSize: _boardSize,
      queens: Map.of(queens),
      description: 'Place $_boardSize queens on a ${_boardSize}x$_boardSize board',
    ));

    bool isSafe(int row, int col) {
      for (final entry in queens.entries) {
        final qRow = entry.key;
        final qCol = entry.value;
        if (qCol == col ||
            (qRow - row).abs() == (qCol - col).abs()) {
          return false;
        }
      }
      return true;
    }

    Set<(int, int)> getConflicts(int row, int col) {
      final conflicts = <(int, int)>{};
      for (final entry in queens.entries) {
        final qRow = entry.key;
        final qCol = entry.value;
        if (qCol == col ||
            (qRow - row).abs() == (qCol - col).abs()) {
          conflicts.add((qRow, qCol));
          conflicts.add((row, col));
        }
      }
      return conflicts;
    }

    bool solve(int row) {
      if (row == _boardSize) {
        states.add(NQueensState(
          boardSize: _boardSize,
          queens: Map.of(queens),
          solved: true,
          description: 'All $_boardSize queens placed successfully!',
        ));
        return true;
      }

      for (var col = 0; col < _boardSize; col++) {
        states.add(NQueensState(
          boardSize: _boardSize,
          queens: Map.of(queens),
          currentRow: row,
          currentCol: col,
          description: 'Trying queen at row $row, col $col',
        ));

        if (isSafe(row, col)) {
          queens[row] = col;
          states.add(NQueensState(
            boardSize: _boardSize,
            queens: Map.of(queens),
            description: 'Placed queen at row $row, col $col',
          ));

          if (solve(row + 1)) return true;

          queens.remove(row);
          states.add(NQueensState(
            boardSize: _boardSize,
            queens: Map.of(queens),
            description: 'Backtrack: removed queen from row $row',
          ));
        } else {
          final conflicts = getConflicts(row, col);
          states.add(NQueensState(
            boardSize: _boardSize,
            queens: Map.of(queens),
            currentRow: row,
            currentCol: col,
            conflicts: conflicts,
            description:
                'Conflict at row $row, col $col — not safe',
          ));
        }
      }

      return false;
    }

    solve(0);
    return states;
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) {
    return _NQueensPainter(
      state: state as NQueensState,
      brightness: Theme.of(context).brightness,
    );
  }

  @override
  Widget? buildControls({required VoidCallback onChanged}) {
    return _BoardSizeControl(
      boardSize: _boardSize,
      onChanged: (size) {
        _boardSize = size;
        onChanged();
      },
    );
  }
}

class _NQueensPainter extends CustomPainter {
  _NQueensPainter({required this.state, required this.brightness});

  final NQueensState state;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final n = state.boardSize;
    final cellSize = size.shortestSide / n;
    final offsetX = (size.width - cellSize * n) / 2;
    final offsetY = (size.height - cellSize * n) / 2;

    final isDark = brightness == Brightness.dark;

    final lightCell = isDark ? const Color(0xFF424242) : const Color(0xFFE0E0E0);
    final darkCell = isDark ? const Color(0xFF616161) : const Color(0xFFBDBDBD);
    final conflictColor = isDark
        ? const Color(0xFFEF5350).withValues(alpha: 0.4)
        : const Color(0xFFD32F2F).withValues(alpha: 0.3);
    final tryingColor = isDark
        ? const Color(0xFF42A5F5).withValues(alpha: 0.4)
        : const Color(0xFF1976D2).withValues(alpha: 0.3);
    final queenColor = isDark
        ? const Color(0xFF4CAF50)
        : const Color(0xFF388E3C);
    final solvedQueenColor = isDark
        ? const Color(0xFFFFCA28)
        : const Color(0xFFF9A825);

    // Draw board
    for (var row = 0; row < n; row++) {
      for (var col = 0; col < n; col++) {
        final rect = Rect.fromLTWH(
          offsetX + col * cellSize,
          offsetY + row * cellSize,
          cellSize,
          cellSize,
        );

        // Base cell color
        final isLight = (row + col) % 2 == 0;
        var color = isLight ? lightCell : darkCell;

        // Conflict highlight
        if (state.conflicts.contains((row, col))) {
          color = conflictColor;
        }

        // Trying position
        if (state.currentRow == row && state.currentCol == col) {
          color = state.conflicts.isNotEmpty ? conflictColor : tryingColor;
        }

        canvas.drawRect(rect, Paint()..color = color);
      }
    }

    // Draw queens
    for (final entry in state.queens.entries) {
      final row = entry.key;
      final col = entry.value;
      final center = Offset(
        offsetX + col * cellSize + cellSize / 2,
        offsetY + row * cellSize + cellSize / 2,
      );

      final qColor = state.solved ? solvedQueenColor : queenColor;
      final radius = cellSize * 0.35;

      canvas.drawCircle(center, radius, Paint()..color = qColor);

      // Crown symbol
      final textPainter = TextPainter(
        text: TextSpan(
          text: '♛',
          style: TextStyle(
            fontSize: cellSize * 0.55,
            color: isDark ? Colors.black87 : Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        center - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }

    // Draw trying position marker (if no queen placed there yet)
    if (state.currentRow != null &&
        state.currentCol != null &&
        !state.queens.containsKey(state.currentRow)) {
      final center = Offset(
        offsetX + state.currentCol! * cellSize + cellSize / 2,
        offsetY + state.currentRow! * cellSize + cellSize / 2,
      );
      canvas.drawCircle(
        center,
        cellSize * 0.2,
        Paint()
          ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // Board border
    canvas.drawRect(
      Rect.fromLTWH(offsetX, offsetY, cellSize * n, cellSize * n),
      Paint()
        ..color = isDark ? Colors.white24 : Colors.black26
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _NQueensPainter oldDelegate) {
    return oldDelegate.state != state;
  }
}

class _BoardSizeControl extends StatefulWidget {
  const _BoardSizeControl({required this.boardSize, required this.onChanged});
  final int boardSize;
  final ValueChanged<int> onChanged;

  @override
  State<_BoardSizeControl> createState() => _BoardSizeControlState();
}

class _BoardSizeControlState extends State<_BoardSizeControl> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.boardSize.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('Board: ${_value.round()}×${_value.round()}',
            style: Theme.of(context).textTheme.bodySmall),
        Expanded(
          child: Slider(
            value: _value,
            min: 4,
            max: 12,
            divisions: 8,
            onChanged: (v) => setState(() => _value = v),
            onChangeEnd: (v) => widget.onChanged(v.round()),
          ),
        ),
      ],
    );
  }
}
