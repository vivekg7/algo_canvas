# Algo Canvas

An open-source, cross-platform algorithm visualizer built with Flutter. Watch algorithms come to life step by step — from sorting and graph traversal to fluid simulations and fractal geometry.

**90 algorithms. 15 categories. Zero internet. Zero ads. Zero tracking.**

## Philosophy

- **No Internet** — everything runs offline, on-device
- **No Ads** — ever
- **No Tracking** — no analytics, no telemetry, no crash reporting
- **Always Free & Open Source** — GPLv3
- **For Learning** — every design decision prioritizes clarity and educational value

## Algorithms

| Category                                                            | Count | Highlights                                           |
| ------------------------------------------------------------------- | ----- | ---------------------------------------------------- |
| [Sorting](docs/ALGORITHMS.md#sorting)                               | 10    | Quick, Merge, Heap, Tim, Radix, and more             |
| [Graph Traversal](docs/ALGORITHMS.md#graph-traversal)               | 9     | BFS, DFS, Dijkstra's, A\*, Kruskal's, Prim's         |
| [Pathfinding](docs/ALGORITHMS.md#pathfinding)                       | 5     | A\* Grid, Maze Generation & Solving                  |
| [Searching](docs/ALGORITHMS.md#searching)                           | 4     | Binary, Ternary, Jump, Linear                        |
| [Tree](docs/ALGORITHMS.md#tree)                                     | 8     | BST, AVL, Heap, Trie, Traversals                     |
| [Dynamic Programming](docs/ALGORITHMS.md#dynamic-programming)       | 7     | Knapsack, LCS, Edit Distance, Coin Change            |
| [Math / Signal](docs/ALGORITHMS.md#math--signal)                    | 5     | Fourier Transform, Sieve, Monte Carlo Pi             |
| [Physics / Simulation](docs/ALGORITHMS.md#physics--simulation)      | 7     | Game of Life, Fluid Sim, N-Body, Boids               |
| [String](docs/ALGORITHMS.md#string)                                 | 5     | KMP, Rabin-Karp, Boyer-Moore, Manacher's             |
| [Computational Geometry](docs/ALGORITHMS.md#computational-geometry) | 5     | Convex Hull, Voronoi, Delaunay                       |
| [Backtracking](docs/ALGORITHMS.md#backtracking)                     | 3     | N-Queens, Sudoku Solver, Knight's Tour               |
| [Compression](docs/ALGORITHMS.md#compression--encoding)             | 3     | Huffman, RLE, LZW                                    |
| [Fractals](docs/ALGORITHMS.md#fractals)                             | 7     | Mandelbrot, Julia, Sierpinski, Koch                  |
| [Space-Filling Curves](docs/ALGORITHMS.md#space-filling-curves)     | 3     | Hilbert, Peano, Z-Order                              |
| [Interactive](docs/ALGORITHMS.md#interactive)                       | 8     | Bezier, Splines, Pendulums, Spring-Mass, Pathfinding |

See the full list: [docs/ALGORITHMS.md](docs/ALGORITHMS.md)

## Features

- **Step-by-step playback** — play, pause, step forward/backward, scrub through any batch algorithm
- **Live simulations** — physics and cellular automata run indefinitely with a rolling 50-state buffer
- **Interactive mode** — drag control points, draw walls, manipulate physics objects directly on the canvas
- **Speed control** — 0.25x to 16x playback speed
- **Configurable inputs** — array sizes, grid dimensions, node counts, simulation parameters
- **Color legends** — each algorithm shows what the colors mean
- **Mode badges** — each card shows its execution mode (Step-by-step, Live, Interactive)
- **4 themes** — System, Light, Dark, AMOLED (pure black)
- **10 accent colors** — personalize the look
- **Search & filter** — find algorithms by name or category
- **Cross-platform** — Android, iOS, Web, macOS, Windows, Linux

## Architecture

The codebase is designed so adding a new algorithm is straightforward:

```
lib/
  core/
    algorithm.dart           # Base class with 4 execution modes
    algorithm_state.dart     # Snapshot of algorithm at a point in time
    visualizer_controller.dart  # Shared playback engine
    algorithm_registry.dart  # One-line registration
  algorithms/
    sorting/                 # Each category has its own directory
      sorting_state.dart     # Shared state for the category
      sorting_painter.dart   # Shared CustomPainter
      quick_sort.dart        # One file per algorithm
      ...
  screens/
    home_screen.dart         # Grid of algorithm cards with search/filter
    visualizer_screen.dart   # Generic screen that works for any algorithm
    settings_screen.dart     # Theme and accent color
  theme/
    app_theme.dart           # System/Light/Dark/AMOLED themes
    theme_controller.dart    # Persisted via shared_preferences
  widgets/
    playback_controls.dart   # Play/pause/step/speed/scrub
    algorithm_card.dart      # Card on home screen with category + mode badges
    color_legend.dart        # Color key below canvas
```

### Four Execution Modes

| Mode            | Use Case                        | Controls                     | Example                       |
| --------------- | ------------------------------- | ---------------------------- | ----------------------------- |
| **Batch**       | Pre-compute all steps           | Play/pause, scrub, step      | Sorting, Searching, DP        |
| **Streaming**   | On-the-fly via `Stream`         | Play/pause, buffered history | Expensive computations        |
| **Live**        | Indefinite via `tick()`         | Play/pause, 50-state buffer  | Game of Life, Boids, Fluid    |
| **Interactive** | User-driven via canvas gestures | Direct manipulation          | Bezier, Pendulum, Pathfinding |

Interactive algorithms can also implement `tick()` for hybrid behavior — physics simulates when the user isn't dragging (e.g., Pendulum, Spring-Mass).

### Adding a New Algorithm

1. Create a file under the appropriate `algorithms/` directory
2. Extend `Algorithm`, override the mode and implement the relevant methods
3. Create a `CustomPainter` or reuse a shared one
4. Add one line to `algorithm_registry.dart`

## Getting Started

```bash
# Clone
git clone https://github.com/vivekg7/algo_canvas.git
cd algo_canvas

# Run
flutter run
```

Requires Flutter 3.41+ and Dart 3.11+.

## Dependencies

Intentionally minimal:

- `flutter` — SDK
- `shared_preferences` — theme persistence (Flutter team package)

That's it. No state management packages, no routing packages, no animation libraries.

## License

[GPLv3](LICENSE)
