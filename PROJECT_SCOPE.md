# Project Scope — Algo Canvas

## What This Project Is

A cross-platform Flutter application that visualizes algorithms through interactive animations. Built purely for learning and hobby purposes.

## Core Philosophy

- **No Internet** — The app works entirely offline. No network calls, no remote assets, no cloud dependencies.
- **No Ads** — Zero advertising, ever.
- **No Tracking or Analytics** — No telemetry, no crash reporting services, no usage data collection.
- **Always Free and Open Source** — Licensed openly, contributions welcome.
- **For Learning** — Every design decision prioritizes clarity and educational value.

## Guiding Principles

### Lightweight by Default

- Use **Flutter's built-in primitives** wherever possible.
- **No state management packages** (no Provider, Riverpod, Bloc, etc.) — use `ValueNotifier`, `ChangeNotifier`, `ValueListenableBuilder`, `setState`, and `StreamBuilder`.
- **No routing packages** — use `Navigator.push` / `Navigator.pop` directly.
- **Minimal dependencies** — a package is added only when writing it from scratch would be unreasonable. Every dependency must justify its presence.

### Extensible Architecture

- Adding a new algorithm visualizer should be straightforward — follow a pattern, implement the logic and its painter, register it, done.
- Algorithms are self-contained modules. One algorithm's code should not bleed into another's.
- Shared utilities (animation helpers, common controls like speed sliders, play/pause) live in a common layer that all visualizers can use.

## Algorithm Categories (Non-Exhaustive)

| Category               | Examples                                                                                   |
| ---------------------- | ------------------------------------------------------------------------------------------ |
| Sorting                | Bubble Sort, Selection Sort, Insertion Sort, Merge Sort, Quick Sort, Heap Sort, Radix Sort |
| Graph Traversal        | BFS, DFS, Dijkstra's, A\*, Bellman-Ford, Kruskal's, Prim's                                 |
| Pathfinding            | A\* on grids, maze generation and solving                                                  |
| Searching              | Binary Search, Linear Search                                                               |
| Tree                   | BST operations, AVL rotations, tree traversals                                             |
| Dynamic Programming    | Knapsack, LCS, edit distance (visualized as tables)                                        |
| Math / Signal          | Fourier Transform, Sieve of Eratosthenes                                                   |
| Physics / Simulation   | Fluid motion, N-body, Conway's Game of Life                                                |
| String                 | KMP, Rabin-Karp pattern matching                                                           |
| Computational Geometry | Convex Hull, line intersection                                                             |

This list is a starting direction, not a hard boundary. New categories and algorithms can be added as interest or contributions arise.

## Target Platforms

- Android
- iOS
- Web
- macOS
- Windows
- Linux

All platforms are targets. Platform-specific code should be avoided unless absolutely necessary.

## What Is Out of Scope

- **Backend / server components** — There is no server. Everything runs on-device.
- **User accounts or cloud sync** — No sign-in, no cloud storage.
- **Competitive programming / judge features** — This is a visualizer, not an online judge.
- **Code editor or playground** — The app visualizes algorithms, it does not compile or run user-written code.
- **Monetization of any kind** — No in-app purchases, no premium tier, no donations integration inside the app.
- **Heavy packages for cosmetic purposes** — No animation libraries, charting libraries, or UI kits when Flutter's `CustomPainter` and built-in widgets suffice.

## Quality Boundaries

- Visualizations should be **correct** — they must faithfully represent how the algorithm works, step by step.
- Performance matters — visualizers should run smoothly on mid-range devices.
- Code should be readable — this is a learning project, the source itself should be easy to follow.
