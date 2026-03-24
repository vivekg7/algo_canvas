import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';

class KnightsTourState extends AlgorithmState {
  const KnightsTourState({
    required this.boardSize,
    required this.board,
    this.currentRow,
    this.currentCol,
    this.moveNumber = 0,
    this.backtracking = false,
    this.solved = false,
    required super.description,
  });

  final int boardSize;

  /// Board where each cell is the move number (0 = unvisited).
  final List<List<int>> board;
  final int? currentRow;
  final int? currentCol;
  final int moveNumber;
  final bool backtracking;
  final bool solved;
}

class KnightsTourAlgorithm extends Algorithm {
  int _boardSize = 6;

  // Knight move offsets
  static const _dx = [2, 1, -1, -2, -2, -1, 1, 2];
  static const _dy = [1, 2, 2, 1, -1, -2, -2, -1];

  @override
  String get name => "Knight's Tour";

  @override
  String get description =>
      'Find a path for a knight to visit every square exactly once.';

  @override
  AlgorithmCategory get category => AlgorithmCategory.backtracking;

  @override
  Future<List<AlgorithmState>> generate() async {
    final n = _boardSize;
    final board = List.generate(n, (_) => List.filled(n, 0));
    final states = <KnightsTourState>[];

    states.add(KnightsTourState(
      boardSize: n,
      board: _copyBoard(board),
      description: "Knight's tour on a ${n}x$n board",
    ));

    board[0][0] = 1;
    states.add(KnightsTourState(
      boardSize: n,
      board: _copyBoard(board),
      currentRow: 0,
      currentCol: 0,
      moveNumber: 1,
      description: 'Starting at (0, 0) — move 1',
    ));

    // Warnsdorff's heuristic: sort next moves by degree (fewest onward moves first)
    List<(int, int)> getOrderedMoves(int row, int col) {
      final moves = <(int, int, int)>[];
      for (var i = 0; i < 8; i++) {
        final nr = row + _dx[i];
        final nc = col + _dy[i];
        if (nr >= 0 && nr < n && nc >= 0 && nc < n && board[nr][nc] == 0) {
          // Count onward moves from this position
          var degree = 0;
          for (var j = 0; j < 8; j++) {
            final nnr = nr + _dx[j];
            final nnc = nc + _dy[j];
            if (nnr >= 0 &&
                nnr < n &&
                nnc >= 0 &&
                nnc < n &&
                board[nnr][nnc] == 0) {
              degree++;
            }
          }
          moves.add((nr, nc, degree));
        }
      }
      moves.sort((a, b) => a.$3.compareTo(b.$3));
      return moves.map((m) => (m.$1, m.$2)).toList();
    }

    bool solve(int row, int col, int move) {
      if (move > n * n) {
        states.add(KnightsTourState(
          boardSize: n,
          board: _copyBoard(board),
          currentRow: row,
          currentCol: col,
          moveNumber: move - 1,
          solved: true,
          description: 'Tour complete! All ${n * n} squares visited.',
        ));
        return true;
      }

      final moves = getOrderedMoves(row, col);

      for (final (nr, nc) in moves) {
        board[nr][nc] = move;

        states.add(KnightsTourState(
          boardSize: n,
          board: _copyBoard(board),
          currentRow: nr,
          currentCol: nc,
          moveNumber: move,
          description: 'Move $move: knight to ($nr, $nc)',
        ));

        if (solve(nr, nc, move + 1)) return true;

        board[nr][nc] = 0;

        states.add(KnightsTourState(
          boardSize: n,
          board: _copyBoard(board),
          currentRow: row,
          currentCol: col,
          moveNumber: move - 1,
          backtracking: true,
          description: 'Backtrack from ($nr, $nc), back to ($row, $col)',
        ));
      }

      return false;
    }

    if (!solve(0, 0, 2)) {
      states.add(KnightsTourState(
        boardSize: n,
        board: _copyBoard(board),
        description: 'No complete tour found from (0, 0)',
      ));
    }

    return states;
  }

  List<List<int>> _copyBoard(List<List<int>> board) {
    return [for (final row in board) List<int>.of(row)];
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) {
    return _KnightsTourPainter(
      state: state as KnightsTourState,
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

class _KnightsTourPainter extends CustomPainter {
  _KnightsTourPainter({required this.state, required this.brightness});

  final KnightsTourState state;
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
    final visitedColor = isDark
        ? const Color(0xFF42A5F5).withValues(alpha: 0.3)
        : const Color(0xFF1976D2).withValues(alpha: 0.2);
    final currentColor = isDark
        ? const Color(0xFF4CAF50)
        : const Color(0xFF388E3C);
    final backtrackColor = isDark
        ? const Color(0xFFEF5350)
        : const Color(0xFFD32F2F);
    final numberColor = isDark ? Colors.white70 : Colors.black54;
    final solvedColor = isDark
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

        final isLight = (row + col) % 2 == 0;
        var color = isLight ? lightCell : darkCell;

        if (state.board[row][col] > 0) {
          color = Color.alphaBlend(visitedColor, color);
        }

        canvas.drawRect(rect, Paint()..color = color);

        // Move number
        if (state.board[row][col] > 0) {
          final tp = TextPainter(
            text: TextSpan(
              text: '${state.board[row][col]}',
              style: TextStyle(
                fontSize: cellSize * 0.35,
                color: numberColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();

          final center = Offset(
            offsetX + col * cellSize + cellSize / 2,
            offsetY + row * cellSize + cellSize / 2,
          );
          tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
        }
      }
    }

    // Draw path lines between consecutive moves
    final positions = <int, (int, int)>{};
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        if (state.board[r][c] > 0) {
          positions[state.board[r][c]] = (r, c);
        }
      }
    }

    final pathPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (var i = 1; i < positions.length; i++) {
      final from = positions[i];
      final to = positions[i + 1];
      if (from != null && to != null) {
        canvas.drawLine(
          Offset(
            offsetX + from.$2 * cellSize + cellSize / 2,
            offsetY + from.$1 * cellSize + cellSize / 2,
          ),
          Offset(
            offsetX + to.$2 * cellSize + cellSize / 2,
            offsetY + to.$1 * cellSize + cellSize / 2,
          ),
          pathPaint,
        );
      }
    }

    // Current knight position
    if (state.currentRow != null && state.currentCol != null) {
      final center = Offset(
        offsetX + state.currentCol! * cellSize + cellSize / 2,
        offsetY + state.currentRow! * cellSize + cellSize / 2,
      );

      Color knightColor;
      if (state.solved) {
        knightColor = solvedColor;
      } else if (state.backtracking) {
        knightColor = backtrackColor;
      } else {
        knightColor = currentColor;
      }

      canvas.drawCircle(center, cellSize * 0.3, Paint()..color = knightColor);

      final tp = TextPainter(
        text: TextSpan(
          text: '♞',
          style: TextStyle(
            fontSize: cellSize * 0.5,
            color: isDark ? Colors.black87 : Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
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
  bool shouldRepaint(covariant _KnightsTourPainter oldDelegate) {
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
            min: 5,
            max: 8,
            divisions: 3,
            onChanged: (v) => setState(() => _value = v),
            onChangeEnd: (v) => widget.onChanged(v.round()),
          ),
        ),
      ],
    );
  }
}
