import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/algorithms/sorting/quick_sort.dart';

class AlgorithmRegistry {
  AlgorithmRegistry._();

  static final List<Algorithm> _algorithms = [
    QuickSortAlgorithm(),
  ];

  static List<Algorithm> get all => List.unmodifiable(_algorithms);
}
