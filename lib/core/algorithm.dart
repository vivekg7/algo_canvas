import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';

/// Base class for all algorithm visualizers.
///
/// Subclasses must override either [generate] (batch) or [stream] (on-the-fly).
/// The default implementations delegate to each other, so overriding one is
/// sufficient.
abstract class Algorithm {
  const Algorithm();

  String get name;
  String get description;
  AlgorithmCategory get category;

  /// Whether this algorithm produces steps on-the-fly via [stream] rather than
  /// pre-computing all steps via [generate].
  ///
  /// The visualizer controller uses this to decide its playback strategy.
  bool get isStreaming => false;

  /// Pre-compute all steps and return them as a list.
  ///
  /// Default: collects all states from [stream].
  Future<List<AlgorithmState>> generate() async {
    return stream().toList();
  }

  /// Yield states one at a time as they are computed.
  ///
  /// Default: emits all states from [generate].
  Stream<AlgorithmState> stream() async* {
    final states = await generate();
    for (final state in states) {
      yield state;
    }
  }

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
}
