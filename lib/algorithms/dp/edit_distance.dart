import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';
import 'package:algo_canvas/algorithms/dp/dp_state.dart';
import 'package:algo_canvas/algorithms/dp/dp_painter.dart';
import 'package:algo_canvas/algorithms/dp/dp_legend.dart';
import 'package:algo_canvas/widgets/color_legend.dart';

class EditDistanceAlgorithm extends Algorithm {
  @override
  String get name => 'Edit Distance';

  @override
  String get description => 'Minimum insertions, deletions, substitutions to transform one string to another. O(mn).';

  @override
  AlgorithmCategory get category => AlgorithmCategory.dynamicProgramming;

  @override
  Future<List<AlgorithmState>> generate() async {
    final random = Random();
    const words = ['kitten', 'sitting', 'sunday', 'saturday', 'horse', 'ros', 'algorithm', 'altruistic', 'flaw', 'lawn'];
    final a = words[random.nextInt(words.length)];
    var b = words[random.nextInt(words.length)];
    while (b == a) { b = words[random.nextInt(words.length)]; }

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

    // Base cases
    for (var i = 0; i <= m; i++) {
      dp[i][0] = i;
      table[i * cols] = '$i';
      status[i * cols] = CellStatus.filled;
    }
    for (var j = 0; j <= n; j++) {
      dp[0][j] = j;
      table[j] = '$j';
      status[j] = CellStatus.filled;
    }

    states.add(DpState(
      table: List.of(table), cellStatus: List.of(status),
      rows: rows, cols: cols, rowLabels: rowLabels, colLabels: colLabels,
      description: 'Edit distance: "$a" → "$b"',
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
          dp[i][j] = dp[i - 1][j - 1];
        } else {
          dp[i][j] = 1 + [dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]].reduce(min);
        }

        table[idx] = '${dp[i][j]}';
        status[idx] = CellStatus.filled;
        states.add(DpState(
          table: List.of(table), cellStatus: List.of(status),
          rows: rows, cols: cols, rowLabels: rowLabels, colLabels: colLabels,
          currentRow: i, currentCol: j,
          description: a[i - 1] == b[j - 1]
              ? 'Match! dp[$i][$j] = ${dp[i][j]}'
              : 'dp[$i][$j] = 1 + min(${dp[i - 1][j]}, ${dp[i][j - 1]}, ${dp[i - 1][j - 1]}) = ${dp[i][j]}',
        ));
      }
    }

    // Backtrack
    var i = m, j = n;
    while (i > 0 || j > 0) {
      status[i * cols + j] = CellStatus.onPath;
      if (i > 0 && j > 0 && a[i - 1] == b[j - 1]) {
        i--; j--;
      } else if (i > 0 && j > 0 && dp[i][j] == dp[i - 1][j - 1] + 1) {
        i--; j--;
      } else if (i > 0 && dp[i][j] == dp[i - 1][j] + 1) {
        i--;
      } else {
        j--;
      }
    }
    status[0] = CellStatus.onPath;

    states.add(DpState(
      table: List.of(table), cellStatus: List.of(status),
      rows: rows, cols: cols, rowLabels: rowLabels, colLabels: colLabels,
      result: '${dp[m][n]}', description: 'Edit distance = ${dp[m][n]}',
    ));

    return states;
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) =>
      DpPainter(state: state as DpState, colorScheme: Theme.of(context).colorScheme);

  @override
  List<LegendItem>? buildLegend(BuildContext context) => dpLegend(context);
}
