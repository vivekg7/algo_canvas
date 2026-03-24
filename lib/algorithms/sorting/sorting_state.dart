import 'package:algo_canvas/core/algorithm_state.dart';

class SortingState extends AlgorithmState {
  const SortingState({
    required this.array,
    this.comparing = const {},
    this.swapping = const {},
    this.pivot,
    this.sorted = const {},
    this.activeRange,
    required super.description,
  });

  final List<int> array;
  final Set<int> comparing;
  final Set<int> swapping;
  final int? pivot;
  final Set<int> sorted;

  /// The sub-array range currently being processed, as (start, end) inclusive.
  final (int, int)? activeRange;
}
