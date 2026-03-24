import 'package:algo_canvas/core/algorithm_state.dart';

enum CharStatus { normal, matching, mismatched, matched, current }

class StringMatchState extends AlgorithmState {
  const StringMatchState({
    required this.text,
    required this.pattern,
    required this.textStatus,
    required this.patternStatus,
    this.textOffset = 0,
    this.matches = const [],
    this.extraInfo,
    required super.description,
  });

  final String text;
  final String pattern;

  /// Status per character in text.
  final List<CharStatus> textStatus;

  /// Status per character in pattern.
  final List<CharStatus> patternStatus;

  /// Current alignment offset of pattern within text.
  final int textOffset;

  /// Indices where pattern was found.
  final List<int> matches;

  /// Extra visualization data (e.g., failure table for KMP).
  final List<int>? extraInfo;
}
