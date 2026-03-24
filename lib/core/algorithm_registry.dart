import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/algorithms/sorting/bubble_sort.dart';
import 'package:algo_canvas/algorithms/sorting/counting_sort.dart';
import 'package:algo_canvas/algorithms/sorting/heap_sort.dart';
import 'package:algo_canvas/algorithms/sorting/insertion_sort.dart';
import 'package:algo_canvas/algorithms/sorting/merge_sort.dart';
import 'package:algo_canvas/algorithms/sorting/quick_sort.dart';
import 'package:algo_canvas/algorithms/sorting/radix_sort.dart';
import 'package:algo_canvas/algorithms/sorting/selection_sort.dart';
import 'package:algo_canvas/algorithms/sorting/shell_sort.dart';
import 'package:algo_canvas/algorithms/sorting/tim_sort.dart';

class AlgorithmRegistry {
  AlgorithmRegistry._();

  static final List<Algorithm> _algorithms = [
    // Sorting
    BubbleSortAlgorithm(),
    SelectionSortAlgorithm(),
    InsertionSortAlgorithm(),
    MergeSortAlgorithm(),
    QuickSortAlgorithm(),
    HeapSortAlgorithm(),
    ShellSortAlgorithm(),
    TimSortAlgorithm(),
    CountingSortAlgorithm(),
    RadixSortAlgorithm(),
  ];

  static List<Algorithm> get all => List.unmodifiable(_algorithms);
}
