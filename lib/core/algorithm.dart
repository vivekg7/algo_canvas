import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';
import 'package:algo_canvas/widgets/color_legend.dart';

/// Execution mode for an algorithm.
enum AlgorithmMode {
  /// Pre-compute all steps, full history, scrubbing.
  batch,

  /// Steps produced on-the-fly via stream, buffered history.
  streaming,

  /// Runs indefinitely via [tick]. Rolling buffer of last N states.
  live,
}

/// Base class for all algorithm visualizers.
///
/// Subclasses choose an execution mode:
/// - **Batch**: override [generate].
/// - **Streaming**: override [stream] and set [mode] to [AlgorithmMode.streaming].
/// - **Live**: override [createInitialState] and [tick], set [mode] to [AlgorithmMode.live].
abstract class Algorithm {
  const Algorithm();

  String get name;
  String get description;
  AlgorithmCategory get category;

  /// The execution mode for this algorithm.
  AlgorithmMode get mode => AlgorithmMode.batch;

  // -- Batch mode --

  /// Pre-compute all steps and return them as a list.
  ///
  /// Default: collects all states from [stream].
  Future<List<AlgorithmState>> generate() async {
    return stream().toList();
  }

  // -- Streaming mode --

  /// Yield states one at a time as they are computed.
  ///
  /// Default: emits all states from [generate].
  Stream<AlgorithmState> stream() async* {
    final states = await generate();
    for (final state in states) {
      yield state;
    }
  }

  // -- Live mode --

  /// Create the initial state for live mode.
  AlgorithmState? createInitialState() => null;

  /// Compute the next state from the current one.
  /// Return null to signal the simulation has ended.
  AlgorithmState? tick(AlgorithmState current) => null;

  // -- Shared --

  /// Returns a [CustomPainter] that renders the given [state].
  ///
  /// [context] is provided so painters can read theme brightness, colors, etc.
  CustomPainter createPainter(AlgorithmState state, BuildContext context);

  /// Optional widget for algorithm-specific controls (e.g. array size slider).
  ///
  /// Return null for no extra controls.
  Widget? buildControls({
    required VoidCallback onChanged,
  }) => null;

  /// Optional color legend items for this algorithm.
  ///
  /// Override to show a legend below the canvas.
  List<LegendItem>? buildLegend(BuildContext context) => null;
}
