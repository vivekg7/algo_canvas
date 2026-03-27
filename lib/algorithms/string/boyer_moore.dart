import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';
import 'package:algo_canvas/algorithms/string/string_state.dart';
import 'package:algo_canvas/algorithms/string/string_painter.dart';
import 'package:algo_canvas/algorithms/string/string_legend.dart';
import 'package:algo_canvas/widgets/color_legend.dart';

class BoyerMooreAlgorithm extends Algorithm {
  @override
  String get name => 'Boyer-Moore';

  @override
  String get description => 'Compares right-to-left, uses bad character rule to skip. O(n/m) best.';

  @override
  AlgorithmCategory get category => AlgorithmCategory.string;

  @override
  Future<List<AlgorithmState>> generate() async {
    const text = 'TRUSTHARDTHRUSTERSRUST';
    const pattern = 'RUST';
    final n = text.length, m = pattern.length;
    final states = <StringMatchState>[];
    final matches = <int>[];

    // Bad character table
    final badChar = <int, int>{};
    for (var i = 0; i < m; i++) {
      badChar[pattern.codeUnitAt(i)] = i;
    }

    states.add(StringMatchState(
      text: text, pattern: pattern,
      textStatus: List.filled(n, CharStatus.normal),
      patternStatus: List.filled(m, CharStatus.normal),
      description: 'Boyer-Moore: compare right-to-left with bad character rule',
    ));

    var i = 0;
    while (i <= n - m) {
      final ts = List.filled(n, CharStatus.normal);
      final ps = List.filled(m, CharStatus.normal);

      var j = m - 1;
      // Compare right to left
      while (j >= 0 && pattern[j] == text[i + j]) {
        ts[i + j] = CharStatus.matching;
        ps[j] = CharStatus.matching;
        states.add(StringMatchState(
          text: text, pattern: pattern,
          textStatus: List.of(ts), patternStatus: List.of(ps),
          textOffset: i, matches: List.of(matches),
          description: 'Match at j=$j: "${pattern[j]}" == "${text[i + j]}"',
        ));
        j--;
      }

      if (j < 0) {
        matches.add(i);
        for (var k = 0; k < m; k++) { ts[i + k] = CharStatus.matched; }
        states.add(StringMatchState(
          text: text, pattern: pattern,
          textStatus: List.of(ts), patternStatus: List.filled(m, CharStatus.matched),
          textOffset: i, matches: List.of(matches),
          description: 'Pattern found at index $i!',
        ));
        i += (i + m < n) ? m - (badChar[text.codeUnitAt(i + m)] ?? -1) : 1;
      } else {
        ts[i + j] = CharStatus.mismatched;
        ps[j] = CharStatus.mismatched;
        final shift = max(1, j - (badChar[text.codeUnitAt(i + j)] ?? -1));
        states.add(StringMatchState(
          text: text, pattern: pattern,
          textStatus: List.of(ts), patternStatus: List.of(ps),
          textOffset: i, matches: List.of(matches),
          description: 'Mismatch at j=$j: "${pattern[j]}" != "${text[i + j]}". Shift by $shift',
        ));
        i += shift;
      }
    }

    states.add(StringMatchState(
      text: text, pattern: pattern,
      textStatus: List.filled(n, CharStatus.normal),
      patternStatus: List.filled(m, CharStatus.normal),
      matches: matches,
      description: 'Boyer-Moore complete: ${matches.length} match(es)',
    ));

    return states;
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) =>
      StringMatchPainter(state: state as StringMatchState, colorScheme: Theme.of(context).colorScheme);

  @override
  List<LegendItem>? buildLegend(BuildContext context) => stringLegend(context);
}
