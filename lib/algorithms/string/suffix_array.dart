import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';
import 'package:algo_canvas/algorithms/string/string_state.dart';
import 'package:algo_canvas/algorithms/string/string_painter.dart';
import 'package:algo_canvas/algorithms/string/string_legend.dart';
import 'package:algo_canvas/widgets/color_legend.dart';

class SuffixArrayAlgorithm extends Algorithm {
  @override
  String get name => 'Suffix Array';

  @override
  String get description => 'Build sorted array of all suffixes. Foundation for many string algorithms.';

  @override
  AlgorithmCategory get category => AlgorithmCategory.string;

  @override
  Future<List<AlgorithmState>> generate() async {
    const text = 'BANANA\$';
    final n = text.length;
    final states = <StringMatchState>[];

    // Generate all suffixes
    final suffixes = List.generate(n, (i) => i);

    states.add(StringMatchState(
      text: text, pattern: '',
      textStatus: List.filled(n, CharStatus.normal),
      patternStatus: [],
      description: 'Building suffix array for "$text"',
    ));

    // Show unsorted suffixes
    for (var i = 0; i < n; i++) {
      final ts = List.filled(n, CharStatus.normal);
      for (var j = i; j < n; j++) { ts[j] = CharStatus.current; }
      states.add(StringMatchState(
        text: text, pattern: '',
        textStatus: ts, patternStatus: [],
        description: 'Suffix $i: "${text.substring(i)}"',
      ));
    }

    // Sort suffixes
    suffixes.sort((a, b) => text.substring(a).compareTo(text.substring(b)));

    states.add(StringMatchState(
      text: text, pattern: '',
      textStatus: List.filled(n, CharStatus.normal),
      patternStatus: [],
      extraInfo: suffixes,
      description: 'Sorting suffixes lexicographically...',
    ));

    // Show sorted order
    for (var rank = 0; rank < n; rank++) {
      final idx = suffixes[rank];
      final ts = List.filled(n, CharStatus.normal);
      for (var j = idx; j < n; j++) { ts[j] = CharStatus.matching; }

      states.add(StringMatchState(
        text: text, pattern: '',
        textStatus: ts, patternStatus: [],
        extraInfo: suffixes,
        description: 'Rank $rank: suffix[$idx] = "${text.substring(idx)}"',
      ));
    }

    states.add(StringMatchState(
      text: text, pattern: '',
      textStatus: List.filled(n, CharStatus.normal),
      patternStatus: [],
      extraInfo: suffixes,
      description: 'Suffix array: [${suffixes.join(", ")}]',
    ));

    return states;
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) =>
      StringMatchPainter(state: state as StringMatchState, brightness: Theme.of(context).brightness);

  @override
  List<LegendItem>? buildLegend(BuildContext context) => stringLegend(context);
}
