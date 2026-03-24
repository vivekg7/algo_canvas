import 'package:algo_canvas/core/algorithm.dart';

class AlgorithmRegistry {
  AlgorithmRegistry._();

  static final List<Algorithm> _algorithms = [
    // Register algorithms here:
    // QuickSortAlgorithm(),
  ];

  static List<Algorithm> get all => List.unmodifiable(_algorithms);
}
