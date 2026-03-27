import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';
import 'package:algo_canvas/algorithms/string/string_state.dart';
import 'package:algo_canvas/algorithms/string/string_painter.dart';
import 'package:algo_canvas/algorithms/string/string_legend.dart';
import 'package:algo_canvas/widgets/color_legend.dart';

class RabinKarpAlgorithm extends Algorithm {
  @override
  String get name => 'Rabin-Karp';

  @override
  String get description => 'Rolling hash comparison: only verify on hash match. O(n+m) average.';

  @override
  AlgorithmCategory get category => AlgorithmCategory.string;

  @override
  Future<List<AlgorithmState>> generate() async {
    const text = 'ABRACADABRABRABRA';
    const pattern = 'ABRA';
    final n = text.length, m = pattern.length;
    const base = 256, mod = 101;
    final states = <StringMatchState>[];
    final matches = <int>[];

    // Compute pattern hash
    var patHash = 0;
    var textHash = 0;
    var h = 1;
    for (var i = 0; i < m - 1; i++) { h = (h * base) % mod; }

    for (var i = 0; i < m; i++) {
      patHash = (base * patHash + pattern.codeUnitAt(i)) % mod;
      textHash = (base * textHash + text.codeUnitAt(i)) % mod;
    }

    states.add(StringMatchState(
      text: text, pattern: pattern,
      textStatus: List.filled(n, CharStatus.normal),
      patternStatus: List.filled(m, CharStatus.normal),
      description: 'Rabin-Karp: pattern hash = $patHash',
    ));

    for (var i = 0; i <= n - m; i++) {
      final ts = List.filled(n, CharStatus.normal);
      final ps = List.filled(m, CharStatus.normal);
      for (var k = 0; k < m; k++) { ts[i + k] = CharStatus.current; }

      if (textHash == patHash) {
        // Hash match — verify character by character
        var match = true;
        for (var j = 0; j < m; j++) {
          ts[i + j] = CharStatus.matching;
          ps[j] = CharStatus.matching;
          if (text[i + j] != pattern[j]) {
            ts[i + j] = CharStatus.mismatched;
            ps[j] = CharStatus.mismatched;
            match = false;
            states.add(StringMatchState(
              text: text, pattern: pattern,
              textStatus: ts, patternStatus: ps,
              textOffset: i, matches: List.of(matches),
              description: 'Hash match at $i (hash=$textHash), but chars differ at $j',
            ));
            break;
          }
        }
        if (match) {
          matches.add(i);
          for (var j = 0; j < m; j++) { ts[i + j] = CharStatus.matched; }
          states.add(StringMatchState(
            text: text, pattern: pattern,
            textStatus: ts, patternStatus: List.filled(m, CharStatus.matched),
            textOffset: i, matches: List.of(matches),
            description: 'Pattern found at index $i! (hash=$textHash)',
          ));
        }
      } else {
        states.add(StringMatchState(
          text: text, pattern: pattern,
          textStatus: ts, patternStatus: ps,
          textOffset: i, matches: List.of(matches),
          description: 'Hash mismatch at $i: text=$textHash, pattern=$patHash',
        ));
      }

      // Rolling hash
      if (i < n - m) {
        textHash = (base * (textHash - text.codeUnitAt(i) * h) + text.codeUnitAt(i + m)) % mod;
        if (textHash < 0) { textHash += mod; }
      }
    }

    states.add(StringMatchState(
      text: text, pattern: pattern,
      textStatus: List.filled(n, CharStatus.normal),
      patternStatus: List.filled(m, CharStatus.normal),
      matches: matches,
      description: 'Rabin-Karp complete: ${matches.length} match(es)',
    ));

    return states;
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) =>
      StringMatchPainter(state: state as StringMatchState, colorScheme: Theme.of(context).colorScheme);

  @override
  List<LegendItem>? buildLegend(BuildContext context) => stringLegend(context);
}
