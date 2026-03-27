import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';

class SudokuState extends AlgorithmState {
  const SudokuState({
    required this.board,
    this.currentRow,
    this.currentCol,
    this.trying,
    this.conflict = false,
    this.given = const {},
    this.solved = false,
    required super.description,
  });

  final List<List<int>> board; // 9x9, 0 = empty
  final int? currentRow;
  final int? currentCol;
  final int? trying;
  final bool conflict;

  /// Set of (row, col) for pre-filled cells.
  final Set<(int, int)> given;
  final bool solved;
}

class SudokuSolverAlgorithm extends Algorithm {
  @override
  String get name => 'Sudoku Solver';

  @override
  String get description =>
      'Solves a Sudoku puzzle using backtracking, trying digits 1-9.';

  @override
  AlgorithmCategory get category => AlgorithmCategory.backtracking;

  @override
  Future<List<AlgorithmState>> generate() async {
    final board = _generatePuzzle();
    final given = <(int, int)>{};
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (board[r][c] != 0) given.add((r, c));
      }
    }

    final states = <SudokuState>[];

    states.add(SudokuState(
      board: _copyBoard(board),
      given: given,
      description: 'Sudoku puzzle with ${given.length} given cells',
    ));

    bool isValid(int row, int col, int num) {
      for (var i = 0; i < 9; i++) {
        if (board[row][i] == num || board[i][col] == num) return false;
      }
      final boxRow = (row ~/ 3) * 3;
      final boxCol = (col ~/ 3) * 3;
      for (var r = boxRow; r < boxRow + 3; r++) {
        for (var c = boxCol; c < boxCol + 3; c++) {
          if (board[r][c] == num) return false;
        }
      }
      return true;
    }

    bool solve() {
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (board[r][c] != 0) continue;

          for (var num = 1; num <= 9; num++) {
            states.add(SudokuState(
              board: _copyBoard(board),
              currentRow: r,
              currentCol: c,
              trying: num,
              given: given,
              description: 'Trying $num at row $r, col $c',
            ));

            if (isValid(r, c, num)) {
              board[r][c] = num;
              states.add(SudokuState(
                board: _copyBoard(board),
                currentRow: r,
                currentCol: c,
                given: given,
                description: 'Placed $num at row $r, col $c',
              ));

              if (solve()) return true;

              board[r][c] = 0;
              states.add(SudokuState(
                board: _copyBoard(board),
                currentRow: r,
                currentCol: c,
                given: given,
                description: 'Backtrack: removed $num from row $r, col $c',
              ));
            } else {
              states.add(SudokuState(
                board: _copyBoard(board),
                currentRow: r,
                currentCol: c,
                trying: num,
                conflict: true,
                given: given,
                description: '$num conflicts at row $r, col $c',
              ));
            }
          }
          return false;
        }
      }

      states.add(SudokuState(
        board: _copyBoard(board),
        given: given,
        solved: true,
        description: 'Sudoku solved!',
      ));
      return true;
    }

    solve();
    return states;
  }

  List<List<int>> _copyBoard(List<List<int>> board) {
    return [for (final row in board) List<int>.of(row)];
  }

  List<List<int>> _generatePuzzle() {
    final board = List.generate(9, (_) => List.filled(9, 0));
    final random = Random();

    // Fill diagonal 3x3 boxes (they don't affect each other)
    for (var box = 0; box < 3; box++) {
      final nums = List.generate(9, (i) => i + 1)..shuffle(random);
      var idx = 0;
      for (var r = box * 3; r < box * 3 + 3; r++) {
        for (var c = box * 3; c < box * 3 + 3; c++) {
          board[r][c] = nums[idx++];
        }
      }
    }

    // Solve the rest
    _solveFull(board);

    // Remove cells while maintaining unique solution (keep ~40 givens)
    final cells = <(int, int)>[];
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        cells.add((r, c));
      }
    }
    cells.shuffle(random);

    var removed = 0;
    final maxRemove = 41; // Remove up to 41, leaving ~40 givens
    for (final (r, c) in cells) {
      if (removed >= maxRemove) break;
      final backup = board[r][c];
      board[r][c] = 0;

      if (_countSolutions(board, 2) != 1) {
        // Removing this cell breaks uniqueness — put it back
        board[r][c] = backup;
      } else {
        removed++;
      }
    }

    return board;
  }

  bool _solveFull(List<List<int>> board) {
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (board[r][c] != 0) continue;
        for (var num = 1; num <= 9; num++) {
          if (_isValidFull(board, r, c, num)) {
            board[r][c] = num;
            if (_solveFull(board)) return true;
            board[r][c] = 0;
          }
        }
        return false;
      }
    }
    return true;
  }

  /// Counts solutions up to [limit]. Returns early once limit is reached.
  int _countSolutions(List<List<int>> board, int limit) {
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (board[r][c] != 0) continue;
        var count = 0;
        for (var num = 1; num <= 9; num++) {
          if (_isValidFull(board, r, c, num)) {
            board[r][c] = num;
            count += _countSolutions(board, limit - count);
            board[r][c] = 0;
            if (count >= limit) return count;
          }
        }
        return count;
      }
    }
    return 1; // All cells filled = one solution found
  }

  bool _isValidFull(List<List<int>> board, int row, int col, int num) {
    for (var i = 0; i < 9; i++) {
      if (board[row][i] == num || board[i][col] == num) return false;
    }
    final boxRow = (row ~/ 3) * 3;
    final boxCol = (col ~/ 3) * 3;
    for (var r = boxRow; r < boxRow + 3; r++) {
      for (var c = boxCol; c < boxCol + 3; c++) {
        if (board[r][c] == num) return false;
      }
    }
    return true;
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) {
    return _SudokuPainter(
      state: state as SudokuState,
      colorScheme: Theme.of(context).colorScheme,
    );
  }
}

class _SudokuPainter extends CustomPainter {
  _SudokuPainter({required this.state, required this.colorScheme});

  final SudokuState state;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final boardSize = size.shortestSide;
    final cellSize = boardSize / 9;
    final offsetX = (size.width - boardSize) / 2;
    final offsetY = (size.height - boardSize) / 2;

    final isDark = colorScheme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF303030) : Colors.white;
    final givenColor = isDark ? Colors.white : Colors.black;
    final placedColor = isDark
        ? const Color(0xFF4CAF50)
        : const Color(0xFF388E3C);
    final tryingColor = colorScheme.primary;
    final conflictColor = isDark
        ? const Color(0xFFEF5350)
        : const Color(0xFFD32F2F);
    final solvedColor = colorScheme.tertiary;

    // Background
    canvas.drawRect(
      Rect.fromLTWH(offsetX, offsetY, boardSize, boardSize),
      Paint()..color = bgColor,
    );

    // Highlight current cell
    if (state.currentRow != null && state.currentCol != null) {
      final highlightColor = state.conflict
          ? conflictColor.withValues(alpha: 0.3)
          : tryingColor.withValues(alpha: 0.3);
      canvas.drawRect(
        Rect.fromLTWH(
          offsetX + state.currentCol! * cellSize,
          offsetY + state.currentRow! * cellSize,
          cellSize,
          cellSize,
        ),
        Paint()..color = highlightColor,
      );
    }

    // Draw numbers
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (state.board[r][c] == 0) continue;

        Color textColor;
        if (state.solved) {
          textColor = state.given.contains((r, c)) ? givenColor : solvedColor;
        } else if (state.given.contains((r, c))) {
          textColor = givenColor;
        } else {
          textColor = placedColor;
        }

        final tp = TextPainter(
          text: TextSpan(
            text: '${state.board[r][c]}',
            style: TextStyle(
              fontSize: cellSize * 0.55,
              fontWeight: state.given.contains((r, c))
                  ? FontWeight.w700
                  : FontWeight.w400,
              color: textColor,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        final center = Offset(
          offsetX + c * cellSize + cellSize / 2,
          offsetY + r * cellSize + cellSize / 2,
        );
        tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
      }
    }

    // Trying number preview
    if (state.trying != null &&
        state.currentRow != null &&
        state.currentCol != null &&
        state.board[state.currentRow!][state.currentCol!] == 0) {
      final color = state.conflict ? conflictColor : tryingColor;
      final tp = TextPainter(
        text: TextSpan(
          text: '${state.trying}',
          style: TextStyle(
            fontSize: cellSize * 0.45,
            fontWeight: FontWeight.w400,
            color: color.withValues(alpha: 0.7),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final center = Offset(
        offsetX + state.currentCol! * cellSize + cellSize / 2,
        offsetY + state.currentRow! * cellSize + cellSize / 2,
      );
      tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
    }

    // Grid lines
    final thinPaint = Paint()
      ..color = isDark ? Colors.white24 : Colors.black26
      ..strokeWidth = 0.5;
    final thickPaint = Paint()
      ..color = isDark ? Colors.white54 : Colors.black54
      ..strokeWidth = 2;

    for (var i = 0; i <= 9; i++) {
      final paint = i % 3 == 0 ? thickPaint : thinPaint;
      final pos = i * cellSize;
      canvas.drawLine(
        Offset(offsetX + pos, offsetY),
        Offset(offsetX + pos, offsetY + boardSize),
        paint,
      );
      canvas.drawLine(
        Offset(offsetX, offsetY + pos),
        Offset(offsetX + boardSize, offsetY + pos),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SudokuPainter oldDelegate) {
    return oldDelegate.state != state || oldDelegate.colorScheme != colorScheme;
  }
}
