import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';
import 'package:algo_canvas/algorithms/string/string_state.dart';
import 'package:algo_canvas/algorithms/string/string_painter.dart';
import 'package:algo_canvas/algorithms/string/string_legend.dart';
import 'package:algo_canvas/widgets/color_legend.dart';

class RleAlgorithm extends Algorithm {
  @override
  String get name => 'Run-Length Encoding';

  @override
  String get description => 'Compress consecutive repeated characters into count+char pairs.';

  @override
  AlgorithmCategory get category => AlgorithmCategory.compression;

  @override
  Future<List<AlgorithmState>> generate() async {
    const input = 'AAABBBCCDDDDEEEFFFA';
    final n = input.length;
    final states = <StringMatchState>[];
    var encoded = '';

    states.add(StringMatchState(
      text: input, pattern: encoded,
      textStatus: List.filled(n, CharStatus.normal),
      patternStatus: [],
      description: 'RLE: compress "$input"',
    ));

    var i = 0;
    while (i < n) {
      final ch = input[i];
      var count = 1;
      final runStart = i;

      while (i + count < n && input[i + count] == ch) { count++; }

      // Highlight the run
      final ts = List.filled(n, CharStatus.normal);
      for (var j = runStart; j < runStart + count; j++) { ts[j] = CharStatus.matching; }

      states.add(StringMatchState(
        text: input, pattern: encoded,
        textStatus: ts,
        patternStatus: List.filled(encoded.length, CharStatus.normal),
        description: 'Run of "$ch" × $count starting at index $runStart',
      ));

      encoded += '$count$ch';

      // Show encoded so far
      final ts2 = List.of(ts);
      for (var j = runStart; j < runStart + count; j++) { ts2[j] = CharStatus.matched; }

      states.add(StringMatchState(
        text: input, pattern: encoded,
        textStatus: ts2,
        patternStatus: List.filled(encoded.length, CharStatus.normal),
        description: 'Encoded: "$encoded"',
      ));

      i += count;
    }

    states.add(StringMatchState(
      text: input, pattern: encoded,
      textStatus: List.filled(n, CharStatus.matched),
      patternStatus: List.filled(encoded.length, CharStatus.matched),
      description: 'RLE complete: "$input" → "$encoded" ($n → ${encoded.length} chars)',
    ));

    return states;
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) =>
      StringMatchPainter(state: state as StringMatchState, colorScheme: Theme.of(context).colorScheme);

  @override
  List<LegendItem>? buildLegend(BuildContext context) => stringLegend(context);
}
