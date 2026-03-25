# Plan — Project Setup + Quick Sort Visualizer

> **Historical document.** This was the initial implementation plan used to set up the project foundation. Kept for reference. See [ALGORITHMS.md](ALGORITHMS.md) for current status.

## Goal

Set up the Flutter project with a strong, extensible foundation and implement Quick Sort as the first visualizer to validate the architecture.

---

## Phase 1: Flutter Project Initialization

- [x] Run `flutter create` with org name and project name
- [x] Strip out default counter app boilerplate
- [x] Clean up `pubspec.yaml` — set description, remove comments, keep dependencies minimal
- [x] Verify the app runs on at least one platform

---

## Phase 2: Core Architecture ✅

### 2.1 Algorithm Abstraction

Create the contract that every algorithm visualizer must follow:

```
lib/
  core/
    algorithm.dart            # Abstract base: metadata + step generation
    algorithm_state.dart      # Base class for algorithm snapshots
    algorithm_category.dart   # Enum of categories (sorting, graph, etc.)
```

**`Algorithm` base class** — every algorithm provides:

- `name`, `description`, `category` (metadata)
- `createPainter(state)` → returns a `CustomPainter` for a given state
- `buildControls()` → optional widget for algorithm-specific inputs (e.g. array size)

**Two execution modes** — algorithms choose which fits:

1. **Batch (pre-computed)**: `generate()` → returns a `List<AlgorithmState>` upfront. Simple, enables scrubbing forward/backward. Good for sorting, searching, most deterministic algorithms.
2. **Streaming (on-the-fly)**: `stream()` → returns a `Stream<AlgorithmState>` that yields states as they're computed. Good for simulations (fluid, Game of Life), interactive algorithms (pathfinding where the user modifies the grid mid-run), or algorithms where pre-computing everything would be too expensive.

The base class provides default implementations: `generate()` defaults to collecting the stream, `stream()` defaults to emitting the pre-computed list. An algorithm only overrides the one that makes sense for it.

**`AlgorithmState` base class** — a snapshot of the algorithm at one point in time. Subclassed per category (e.g. `SortingState` holds the array + highlighted indices).

### 2.2 Algorithm Registry

```
lib/
  core/
    algorithm_registry.dart   # Central list of all available algorithms
```

A simple class with a static list. Adding a new algorithm = one line added here. The home screen reads from this registry.

### 2.3 Visualizer Engine (Shared Playback)

```
lib/
  core/
    visualizer_controller.dart  # Manages playback through steps
```

A `ChangeNotifier` that handles both execution modes transparently:

**Batch mode** — holds the full `List<AlgorithmState>`:

- Current step index, playback state (playing / paused / finished), speed multiplier
- Exposes: `play()`, `pause()`, `stepForward()`, `stepBackward()`, `reset()`, `setSpeed()`
- Backward stepping and scrubbing via progress bar work naturally

**Streaming mode** — listens to the algorithm's `Stream<AlgorithmState>`:

- Buffers received states (so backward stepping still works for visited states)
- Cannot scrub ahead of what's been computed
- Exposes the same `play()`, `pause()`, `stepForward()`, `stepBackward()`, `reset()`, `setSpeed()` interface — screens don't need to know which mode is active

Uses a `Timer` or `Ticker` internally to advance steps at the configured speed. Every visualizer reuses this — no algorithm reimplements playback logic.

---

## Phase 3: Screens ✅

### 3.1 Home Screen

```
lib/
  screens/
    home_screen.dart
```

- Grid of algorithm cards, grouped or filterable by category
- Each card shows: name, category, brief description
- Tap → `Navigator.push` to the visualizer screen
- Simple, clean, no over-design — a `GridView` of cards

### 3.2 Visualizer Screen

```
lib/
  screens/
    visualizer_screen.dart
```

A **generic screen** that works for any algorithm:

- Receives an `Algorithm` instance
- Creates a `VisualizerController` and generates steps
- Layout:
  - **Top**: Algorithm name + info
  - **Center**: `CustomPaint` canvas driven by the algorithm's painter and current state
  - **Bottom**: Playback controls (shared widget) + algorithm-specific controls if any
- Listens to `VisualizerController` via `ValueListenableBuilder` / `AnimatedBuilder` and repaints on step changes

### 3.3 Shared Widgets

```
lib/
  widgets/
    algorithm_card.dart       # Card used on home screen
    playback_controls.dart    # Play/pause, step, speed slider, progress bar
```

---

## Phase 4: Quick Sort Implementation ✅

### 4.1 Sorting State

```
lib/
  algorithms/
    sorting/
      sorting_state.dart      # Shared state for all sorting visualizers
```

`SortingState` extends `AlgorithmState`:

- `List<int> array` — current values
- `Set<int> comparing` — indices currently being compared
- `Set<int> swapping` — indices currently being swapped
- `int? pivot` — current pivot index
- `Set<int> sorted` — indices confirmed in final position
- `String description` — human-readable label for this step (e.g. "Comparing 5 and 3")

This state class will be reused by all future sorting algorithms.

### 4.2 Quick Sort Algorithm

```
lib/
  algorithms/
    sorting/
      quick_sort.dart         # Algorithm subclass + painter
```

- Implements `Algorithm` contract
- `generate()` runs Quick Sort on a random array, recording a `SortingState` snapshot at each meaningful step (comparison, swap, pivot selection, partition complete)
- Painter renders bars:
  - Default: neutral color
  - Comparing: highlight color A
  - Swapping: highlight color B
  - Pivot: distinct color
  - Sorted: muted/confirmed color
- Algorithm-specific control: array size slider (regenerate with new size)

---

## Phase 5: Theming and Polish ✅

### 5.1 Four Theme Modes

| Mode       | Description                                                                          |
| ---------- | ------------------------------------------------------------------------------------ |
| **System** | Follows OS light/dark preference                                                     |
| **Light**  | Light background, always                                                             |
| **Dark**   | Material 3 dark theme                                                                |
| **AMOLED** | Pure black (`#000000`) background for OLED screens, minimal surface elevation colors |

- Material 3 with `ColorScheme.fromSeed` as the base, then override surfaces for AMOLED
- Theme preference stored locally (shared_preferences or a simple file — TBD, kept minimal)
- Theme selector accessible from home screen (icon button in app bar)

### 5.2 Visualization Colors

- Consistent color palette for visualization states (comparing, swapping, sorted, etc.) defined in a central theme extension so all future algorithms share the same visual language
- Colors must work well across all four theme modes

### 5.3 Layout

- Responsive layout — works on phone and desktop window sizes

---

## File Structure (Final)

```
lib/
  main.dart
  app.dart
  core/
    algorithm.dart
    algorithm_state.dart
    algorithm_category.dart
    algorithm_registry.dart
    visualizer_controller.dart
  screens/
    home_screen.dart
    visualizer_screen.dart
  algorithms/
    sorting/
      sorting_state.dart
      sorting_painter.dart
      quick_sort.dart
  widgets/
    algorithm_card.dart
    playback_controls.dart
  theme/
    app_theme.dart
    theme_controller.dart
```

---

## What Success Looks Like

After this plan is executed:

1. `flutter run` launches the app on any platform
2. Home screen shows one card: "Quick Sort"
3. Tapping it opens the visualizer with a random array rendered as bars
4. User can play/pause, step forward/backward, adjust speed, and resize the array
5. The visualization is correct — pivot selection, partitioning, and swaps are clearly shown
6. Adding the next algorithm (e.g. Merge Sort) requires only:
   - One new file under `algorithms/sorting/`
   - One line in the registry

---

## Open Decisions (Noted, Not Blocking)

- **Algorithm explanation panel**: Could show pseudocode or step descriptions alongside the visualization. Nice to have, not needed for v1.
- **Settings screen**: Default speed, etc. Can be added later.
- **Theme persistence**: Using `shared_preferences` — Flutter team package, handles platform differences, simpler than manual JSON file I/O for key-value settings.
