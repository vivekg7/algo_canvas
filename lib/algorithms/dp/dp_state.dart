import 'package:algo_canvas/core/algorithm_state.dart';

enum CellStatus { empty, computing, filled, onPath }

class DpState extends AlgorithmState {
  const DpState({
    required this.table,
    required this.cellStatus,
    required this.rows,
    required this.cols,
    this.rowLabels,
    this.colLabels,
    this.currentRow,
    this.currentCol,
    this.result,
    required super.description,
  });

  /// DP table values (flattened row-major, rows x cols).
  final List<String> table;

  /// Status of each cell (flattened).
  final List<CellStatus> cellStatus;
  final int rows;
  final int cols;

  /// Optional labels for row/column headers.
  final List<String>? rowLabels;
  final List<String>? colLabels;

  final int? currentRow;
  final int? currentCol;
  final String? result;
}
