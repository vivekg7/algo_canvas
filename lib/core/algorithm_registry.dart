import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/algorithms/backtracking/knights_tour.dart';
import 'package:algo_canvas/algorithms/backtracking/n_queens.dart';
import 'package:algo_canvas/algorithms/backtracking/sudoku_solver.dart';
import 'package:algo_canvas/algorithms/simulation/boids.dart';
import 'package:algo_canvas/algorithms/simulation/wave_equation.dart';
import 'package:algo_canvas/algorithms/simulation/double_pendulum.dart';
import 'package:algo_canvas/algorithms/simulation/fluid_simulation.dart';
import 'package:algo_canvas/algorithms/simulation/game_of_life.dart';
import 'package:algo_canvas/algorithms/simulation/n_body.dart';
import 'package:algo_canvas/algorithms/simulation/langtons_ant.dart';
import 'package:algo_canvas/algorithms/searching/binary_search.dart';
import 'package:algo_canvas/algorithms/searching/jump_search.dart';
import 'package:algo_canvas/algorithms/searching/linear_search.dart';
import 'package:algo_canvas/algorithms/searching/ternary_search.dart';
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
    // Searching
    LinearSearchAlgorithm(),
    BinarySearchAlgorithm(),
    TernarySearchAlgorithm(),
    JumpSearchAlgorithm(),
    // Backtracking
    NQueensAlgorithm(),
    SudokuSolverAlgorithm(),
    KnightsTourAlgorithm(),
    // Physics / Simulation
    GameOfLifeAlgorithm(),
    LangtonsAntAlgorithm(),
    DoublePendulumAlgorithm(),
    BoidsAlgorithm(),
    WaveEquationAlgorithm(),
    NBodyAlgorithm(),
    FluidSimulationAlgorithm(),
  ];

  static List<Algorithm> get all => List.unmodifiable(_algorithms);
}
