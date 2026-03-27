import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';
import 'package:algo_canvas/algorithms/string/string_state.dart';
import 'package:algo_canvas/algorithms/string/string_painter.dart';
import 'package:algo_canvas/algorithms/string/string_legend.dart';
import 'package:algo_canvas/widgets/color_legend.dart';

class KmpAlgorithm extends Algorithm {
  @override
  String get name => 'KMP';

  @override
  String get description => 'Knuth-Morris-Pratt: uses failure function to skip redundant comparisons. O(n+m).';

  @override
  AlgorithmCategory get category => AlgorithmCategory.string;

  @override
  Future<List<AlgorithmState>> generate() async {
    const text = 'ABABDABACDABABCABAB';
    const pattern = 'ABABCABAB';
    final n = text.length, m = pattern.length;
    final states = <StringMatchState>[];
    final matches = <int>[];

    // Build failure function
    final failure = List.filled(m, 0);
    var k = 0;
    for (var i = 1; i < m; i++) {
      while (k > 0 && pattern[k] != pattern[i]) { k = failure[k - 1]; }
      if (pattern[k] == pattern[i]) { k++; }
      failure[i] = k;
    }

    states.add(StringMatchState(
      text: text, pattern: pattern,
      textStatus: List.filled(n, CharStatus.normal),
      patternStatus: List.filled(m, CharStatus.normal),
      extraInfo: List.of(failure),
      description: 'KMP: failure table built',
    ));

    // Search
    var j = 0;
    for (var i = 0; i < n; i++) {
      while (j > 0 && text[i] != pattern[j]) {
        states.add(StringMatchState(
          text: text, pattern: pattern,
          textStatus: _statusList(n, {i: CharStatus.current}),
          patternStatus: _statusList(m, {j: CharStatus.mismatched}),
          textOffset: i - j,
          extraInfo: failure, matches: List.of(matches),
          description: 'Mismatch at text[$i]="${text[i]}", pattern[$j]="${pattern[j]}". Jump to failure[$j]=${failure[j - 1]}',
        ));
        j = failure[j - 1];
      }

      final ts = _statusList(n, {i: CharStatus.current});
      final ps = _statusList(m, {j: CharStatus.current});

      if (text[i] == pattern[j]) {
        // Mark matched portion
        for (var k = 0; k <= j; k++) {
          ts[i - j + k] = CharStatus.matching;
          ps[k] = CharStatus.matching;
        }
        states.add(StringMatchState(
          text: text, pattern: pattern,
          textStatus: ts, patternStatus: ps,
          textOffset: i - j,
          extraInfo: failure, matches: List.of(matches),
          description: 'Match: text[$i]="${text[i]}" == pattern[$j]="${pattern[j]}"',
        ));
        j++;

        if (j == m) {
          matches.add(i - m + 1);
          final mts = _statusList(n, {});
          for (var k = i - m + 1; k <= i; k++) { mts[k] = CharStatus.matched; }
          states.add(StringMatchState(
            text: text, pattern: pattern,
            textStatus: mts,
            patternStatus: List.filled(m, CharStatus.matched),
            textOffset: i - m + 1,
            extraInfo: failure, matches: List.of(matches),
            description: 'Pattern found at index ${i - m + 1}!',
          ));
          j = failure[j - 1];
        }
      } else {
        ts[i] = CharStatus.mismatched;
        ps[j] = CharStatus.mismatched;
        states.add(StringMatchState(
          text: text, pattern: pattern,
          textStatus: ts, patternStatus: ps,
          textOffset: i - j,
          extraInfo: failure, matches: List.of(matches),
          description: 'Mismatch: text[$i]="${text[i]}" != pattern[$j]="${pattern[j]}"',
        ));
      }
    }

    states.add(StringMatchState(
      text: text, pattern: pattern,
      textStatus: List.filled(n, CharStatus.normal),
      patternStatus: List.filled(m, CharStatus.normal),
      extraInfo: failure, matches: matches,
      description: 'KMP complete: ${matches.length} match(es) at ${matches.join(", ")}',
    ));

    return states;
  }

  List<CharStatus> _statusList(int len, Map<int, CharStatus> overrides) {
    final list = List.filled(len, CharStatus.normal);
    overrides.forEach((i, s) { if (i < len) { list[i] = s; } });
    return list;
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) =>
      StringMatchPainter(state: state as StringMatchState, colorScheme: Theme.of(context).colorScheme);

  @override
  List<LegendItem>? buildLegend(BuildContext context) => stringLegend(context);
}
