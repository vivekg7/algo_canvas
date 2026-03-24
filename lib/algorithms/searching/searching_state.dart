import 'package:algo_canvas/core/algorithm_state.dart';

class SearchingState extends AlgorithmState {
  const SearchingState({
    required this.array,
    required this.target,
    this.checking,
    this.rangeStart,
    this.rangeEnd,
    this.found,
    this.eliminated = const {},
    required super.description,
  });

  final List<int> array;
  final int target;

  /// Index currently being examined.
  final int? checking;

  /// Active search range (inclusive).
  final int? rangeStart;
  final int? rangeEnd;

  /// Index where target was found, or -1 if search concluded not found.
  final int? found;

  /// Indices that have been ruled out.
  final Set<int> eliminated;
}
