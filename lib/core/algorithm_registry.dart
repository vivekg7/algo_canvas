import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/algorithms/geometry/convex_hull_graham.dart';
import 'package:algo_canvas/algorithms/geometry/convex_hull_jarvis.dart';
import 'package:algo_canvas/algorithms/geometry/delaunay.dart';
import 'package:algo_canvas/algorithms/geometry/line_intersection.dart';
import 'package:algo_canvas/algorithms/geometry/voronoi.dart';
import 'package:algo_canvas/algorithms/compression/huffman.dart';
import 'package:algo_canvas/algorithms/compression/lzw.dart';
import 'package:algo_canvas/algorithms/compression/rle.dart';
import 'package:algo_canvas/algorithms/dp/coin_change.dart';
import 'package:algo_canvas/algorithms/dp/edit_distance.dart';
import 'package:algo_canvas/algorithms/dp/fibonacci.dart';
import 'package:algo_canvas/algorithms/dp/knapsack.dart';
import 'package:algo_canvas/algorithms/dp/lcs.dart';
import 'package:algo_canvas/algorithms/dp/lis.dart';
import 'package:algo_canvas/algorithms/dp/matrix_chain.dart';
import 'package:algo_canvas/algorithms/string/boyer_moore.dart';
import 'package:algo_canvas/algorithms/string/kmp.dart';
import 'package:algo_canvas/algorithms/string/manacher.dart';
import 'package:algo_canvas/algorithms/string/rabin_karp.dart';
import 'package:algo_canvas/algorithms/string/suffix_array.dart';
import 'package:algo_canvas/algorithms/tree/avl_tree.dart';
import 'package:algo_canvas/algorithms/tree/bst_operations.dart';
import 'package:algo_canvas/algorithms/tree/heap_operations.dart';
import 'package:algo_canvas/algorithms/tree/level_order.dart';
import 'package:algo_canvas/algorithms/tree/tree_traversals.dart';
import 'package:algo_canvas/algorithms/tree/trie_operations.dart';
import 'package:algo_canvas/algorithms/pathfinding/a_star_grid.dart';
import 'package:algo_canvas/algorithms/pathfinding/maze_gen_backtracker.dart';
import 'package:algo_canvas/algorithms/pathfinding/maze_gen_prim.dart';
import 'package:algo_canvas/algorithms/pathfinding/maze_solve_bfs.dart';
import 'package:algo_canvas/algorithms/pathfinding/maze_solve_wall_follower.dart';
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
    // Tree
    BstOperationsAlgorithm(),
    AvlTreeAlgorithm(),
    InorderTraversalAlgorithm(),
    PreorderTraversalAlgorithm(),
    PostorderTraversalAlgorithm(),
    LevelOrderTraversalAlgorithm(),
    HeapOperationsAlgorithm(),
    TrieOperationsAlgorithm(),
    // Pathfinding
    AStarGridAlgorithm(),
    MazeGenBacktrackerAlgorithm(),
    MazeGenPrimAlgorithm(),
    MazeSolveWallFollowerAlgorithm(),
    MazeSolveBfsAlgorithm(),
    // Dynamic Programming
    FibonacciAlgorithm(),
    KnapsackAlgorithm(),
    LcsAlgorithm(),
    EditDistanceAlgorithm(),
    CoinChangeAlgorithm(),
    LisAlgorithm(),
    MatrixChainAlgorithm(),
    // String
    KmpAlgorithm(),
    RabinKarpAlgorithm(),
    BoyerMooreAlgorithm(),
    ManacherAlgorithm(),
    SuffixArrayAlgorithm(),
    // Math / Signal
    SieveOfEratosthenesAlgorithm(),
    FourierTransformAlgorithm(),
    EuclideanGcdAlgorithm(),
    NewtonsMethodAlgorithm(),
    MonteCarloPiAlgorithm(),
    // Compression / Encoding
    HuffmanAlgorithm(),
    RleAlgorithm(),
    LzwAlgorithm(),
    // Computational Geometry
    ConvexHullGrahamAlgorithm(),
    ConvexHullJarvisAlgorithm(),
    LineIntersectionAlgorithm(),
    VoronoiAlgorithm(),
    DelaunayAlgorithm(),
  ];

  static List<Algorithm> get all => List.unmodifiable(_algorithms);
}
