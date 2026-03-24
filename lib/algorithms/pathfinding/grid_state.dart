import 'package:algo_canvas/core/algorithm_state.dart';

enum TileType { empty, wall, start, end, visited, queued, path }

class GridState extends AlgorithmState {
  const GridState({
    required this.grid,
    required this.rows,
    required this.cols,
    required this.step,
    required super.description,
  });

  /// Flattened row-major grid of tile types.
  final List<TileType> grid;
  final int rows;
  final int cols;
  final int step;
}
