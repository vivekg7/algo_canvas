import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';
import 'package:algo_canvas/algorithms/string/string_state.dart';
import 'package:algo_canvas/algorithms/string/string_painter.dart';
import 'package:algo_canvas/algorithms/string/string_legend.dart';
import 'package:algo_canvas/widgets/color_legend.dart';

class ManacherAlgorithm extends Algorithm {
  @override
  String get name => "Manacher's";

  @override
  String get description => 'Finds longest palindromic substring in O(n) using mirror property.';

  @override
  AlgorithmCategory get category => AlgorithmCategory.string;

  @override
  Future<List<AlgorithmState>> generate() async {
    const original = 'ABACABACABAD';
    // Transform: insert # between chars and at ends
    final t = StringBuffer('#');
    for (final ch in original.split('')) { t.write('$ch#'); }
    final text = t.toString();
    final n = text.length;
    final p = List.filled(n, 0);
    final states = <StringMatchState>[];

    var center = 0, right = 0;
    var bestCenter = 0, bestLen = 0;

    states.add(StringMatchState(
      text: original, pattern: '',
      textStatus: List.filled(original.length, CharStatus.normal),
      patternStatus: [],
      description: "Manacher's: finding longest palindromic substring in \"$original\"",
    ));

    for (var i = 0; i < n; i++) {
      final mirror = 2 * center - i;

      if (i < right) {
        p[i] = min(right - i, mirror >= 0 ? p[mirror] : 0);
      }

      // Expand
      while (i + p[i] + 1 < n && i - p[i] - 1 >= 0 &&
          text[i + p[i] + 1] == text[i - p[i] - 1]) {
        p[i]++;
      }

      // Map back to original string for highlighting
      final origCenter = i ~/ 2;
      final origRadius = p[i] ~/ 2;
      final origStart = origCenter - origRadius;
      final origEnd = origCenter + origRadius;

      if (p[i] > 1) { // Only show non-trivial palindromes
        final ts = List.filled(original.length, CharStatus.normal);
        for (var j = max(0, origStart); j <= min(origEnd, original.length - 1); j++) {
          ts[j] = CharStatus.matching;
        }
        if (origCenter < original.length) { ts[origCenter] = CharStatus.current; }

        states.add(StringMatchState(
          text: original, pattern: '',
          textStatus: ts, patternStatus: [],
          extraInfo: List.generate(
            min(original.length, (i + 1) ~/ 2 + 1),
            (j) => j * 2 + 1 < n ? p[j * 2 + 1] ~/ 2 : 0,
          ),
          description: 'Center $origCenter: palindrome radius $origRadius "${original.substring(max(0, origStart), min(origEnd + 1, original.length))}"',
        ));
      }

      if (i + p[i] > right) {
        center = i;
        right = i + p[i];
      }

      if (p[i] > bestLen) {
        bestLen = p[i];
        bestCenter = i;
      }
    }

    // Final: highlight longest palindrome
    final lStart = (bestCenter - bestLen) ~/ 2;
    final lEnd = lStart + bestLen - 1;
    final ts = List.filled(original.length, CharStatus.normal);
    for (var j = max(0, lStart); j <= min(lEnd, original.length - 1); j++) {
      ts[j] = CharStatus.matched;
    }

    final longest = original.substring(
      max(0, lStart), min(lEnd + 1, original.length));
    states.add(StringMatchState(
      text: original, pattern: '',
      textStatus: ts, patternStatus: [],
      matches: [lStart],
      description: 'Longest palindrome: "$longest" (length ${longest.length}) at index $lStart',
    ));

    return states;
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) =>
      StringMatchPainter(state: state as StringMatchState, brightness: Theme.of(context).brightness);

  @override
  List<LegendItem>? buildLegend(BuildContext context) => stringLegend(context);
}
