import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/algorithms/graph/a_star.dart';
import 'package:algo_canvas/algorithms/graph/bellman_ford.dart';
import 'package:algo_canvas/algorithms/graph/bfs.dart';
import 'package:algo_canvas/algorithms/graph/dfs.dart';
import 'package:algo_canvas/algorithms/graph/dijkstra.dart';
import 'package:algo_canvas/algorithms/graph/floyd_warshall.dart';
import 'package:algo_canvas/algorithms/graph/kruskal.dart';
import 'package:algo_canvas/algorithms/graph/prim.dart';
import 'package:algo_canvas/algorithms/graph/topological_sort.dart';
import 'package:algo_canvas/algorithms/math/euclidean_gcd.dart';
import 'package:algo_canvas/algorithms/math/fourier_transform.dart';
import 'package:algo_canvas/algorithms/math/monte_carlo_pi.dart';
import 'package:algo_canvas/algorithms/math/newtons_method.dart';
import 'package:algo_canvas/algorithms/math/sieve_of_eratosthenes.dart';
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
    // Graph Traversal
    BfsAlgorithm(),
    DfsAlgorithm(),
    DijkstraAlgorithm(),
    AStarAlgorithm(),
    BellmanFordAlgorithm(),
    KruskalAlgorithm(),
    PrimAlgorithm(),
    TopologicalSortAlgorithm(),
    FloydWarshallAlgorithm(),
    // Math / Signal
    SieveOfEratosthenesAlgorithm(),
    FourierTransformAlgorithm(),
    EuclideanGcdAlgorithm(),
    NewtonsMethodAlgorithm(),
    MonteCarloPiAlgorithm(),
  ];

  static List<Algorithm> get all => List.unmodifiable(_algorithms);
}
