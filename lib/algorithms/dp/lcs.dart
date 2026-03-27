import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';
import 'package:algo_canvas/algorithms/dp/dp_state.dart';
import 'package:algo_canvas/algorithms/dp/dp_painter.dart';
import 'package:algo_canvas/algorithms/dp/dp_legend.dart';
import 'package:algo_canvas/widgets/color_legend.dart';

class LcsAlgorithm extends Algorithm {
  @override
  String get name => 'LCS';

  @override
  String get description => 'Longest Common Subsequence between two strings. O(mn).';

  @override
  AlgorithmCategory get category => AlgorithmCategory.dynamicProgramming;

  @override
  Future<List<AlgorithmState>> generate() async {
    final random = Random();
    const chars = 'ABCDEFGH';
    final a = String.fromCharCodes(List.generate(5 + random.nextInt(4), (_) => chars.codeUnitAt(random.nextInt(chars.length))));
    final b = String.fromCharCodes(List.generate(5 + random.nextInt(4), (_) => chars.codeUnitAt(random.nextInt(chars.length))));

    final m = a.length;
    final n = b.length;
    final rows = m + 1;
    final cols = n + 1;
    final dp = List.generate(rows, (_) => List.filled(cols, 0));
    final states = <DpState>[];
    final table = List<String>.filled(rows * cols, '');
    final status = List.filled(rows * cols, CellStatus.empty);
    final rowLabels = ['∅', ...a.split('')];
    final colLabels = ['∅', ...b.split('')];

    // Fill first row and column with 0
    for (var i = 0; i <= m; i++) { table[i * cols] = '0'; status[i * cols] = CellStatus.filled; }
    for (var j = 0; j <= n; j++) { table[j] = '0'; status[j] = CellStatus.filled; }

    states.add(DpState(
      table: List.of(table), cellStatus: List.of(status),
      rows: rows, cols: cols, rowLabels: rowLabels, colLabels: colLabels,
      description: 'LCS of "$a" and "$b"',
    ));

    for (var i = 1; i <= m; i++) {
      for (var j = 1; j <= n; j++) {
        final idx = i * cols + j;
        status[idx] = CellStatus.computing;
        states.add(DpState(
          table: List.of(table), cellStatus: List.of(status),
          rows: rows, cols: cols, rowLabels: rowLabels, colLabels: colLabels,
          currentRow: i, currentCol: j,
          description: 'Comparing "${a[i - 1]}" and "${b[j - 1]}"',
        ));

        if (a[i - 1] == b[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1] + 1;
        } else {
          dp[i][j] = max(dp[i - 1][j], dp[i][j - 1]);
        }

        table[idx] = '${dp[i][j]}';
        status[idx] = CellStatus.filled;
        states.add(DpState(
          table: List.of(table), cellStatus: List.of(status),
          rows: rows, cols: cols, rowLabels: rowLabels, colLabels: colLabels,
          currentRow: i, currentCol: j,
          description: a[i - 1] == b[j - 1]
              ? 'Match! dp[$i][$j] = ${dp[i][j]}'
              : 'No match: dp[$i][$j] = max(${dp[i - 1][j]}, ${dp[i][j - 1]}) = ${dp[i][j]}',
        ));
      }
    }

    // Backtrack LCS
    var i = m, j = n;
    var lcs = '';
    while (i > 0 && j > 0) {
      if (a[i - 1] == b[j - 1]) {
        status[i * cols + j] = CellStatus.onPath;
        lcs = a[i - 1] + lcs;
        i--; j--;
      } else if (dp[i - 1][j] > dp[i][j - 1]) {
        i--;
      } else {
        j--;
      }
    }

    states.add(DpState(
      table: List.of(table), cellStatus: List.of(status),
      rows: rows, cols: cols, rowLabels: rowLabels, colLabels: colLabels,
      result: lcs, description: 'LCS = "$lcs" (length ${dp[m][n]})',
    ));

    return states;
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) =>
      DpPainter(state: state as DpState, colorScheme: Theme.of(context).colorScheme);

  @override
  List<LegendItem>? buildLegend(BuildContext context) => dpLegend(context);
}
