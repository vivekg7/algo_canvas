import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';
import 'package:algo_canvas/algorithms/dp/dp_state.dart';
import 'package:algo_canvas/algorithms/dp/dp_painter.dart';
import 'package:algo_canvas/algorithms/dp/dp_legend.dart';
import 'package:algo_canvas/widgets/color_legend.dart';

class KnapsackAlgorithm extends Algorithm {
  @override
  String get name => '0/1 Knapsack';

  @override
  String get description => 'Maximize value within weight capacity using DP table. O(nW).';

  @override
  AlgorithmCategory get category => AlgorithmCategory.dynamicProgramming;

  @override
  Future<List<AlgorithmState>> generate() async {
    final random = Random();
    final n = 5 + random.nextInt(3); // 5-7 items
    final capacity = 8 + random.nextInt(5); // 8-12
    final weights = List.generate(n, (_) => random.nextInt(5) + 1);
    final values = List.generate(n, (_) => random.nextInt(10) + 1);

    final rows = n + 1;
    final cols = capacity + 1;
    final states = <DpState>[];
    final dp = List.generate(rows, (_) => List.filled(cols, 0));
    final table = List<String>.filled(rows * cols, '');
    final status = List.filled(rows * cols, CellStatus.empty);
    final rowLabels = ['0', ...List.generate(n, (i) => 'i${i + 1}(w${weights[i]},v${values[i]})')];
    final colLabels = List.generate(cols, (w) => '$w');

    // Fill first row with zeros
    for (var w = 0; w <= capacity; w++) {
      table[w] = '0';
      status[w] = CellStatus.filled;
    }

    states.add(DpState(
      table: List.of(table), cellStatus: List.of(status),
      rows: rows, cols: cols, rowLabels: rowLabels, colLabels: colLabels,
      description: 'Knapsack: $n items, capacity $capacity',
    ));

    for (var i = 1; i <= n; i++) {
      for (var w = 0; w <= capacity; w++) {
        final idx = i * cols + w;
        status[idx] = CellStatus.computing;
        states.add(DpState(
          table: List.of(table), cellStatus: List.of(status),
          rows: rows, cols: cols, rowLabels: rowLabels, colLabels: colLabels,
          currentRow: i, currentCol: w,
          description: 'Item $i (w=${weights[i - 1]}, v=${values[i - 1]}), capacity $w',
        ));

        if (weights[i - 1] <= w) {
          dp[i][w] = max(dp[i - 1][w], dp[i - 1][w - weights[i - 1]] + values[i - 1]);
        } else {
          dp[i][w] = dp[i - 1][w];
        }

        table[idx] = '${dp[i][w]}';
        status[idx] = CellStatus.filled;
        states.add(DpState(
          table: List.of(table), cellStatus: List.of(status),
          rows: rows, cols: cols, rowLabels: rowLabels, colLabels: colLabels,
          currentRow: i, currentCol: w,
          description: 'dp[$i][$w] = ${dp[i][w]}',
        ));
      }
    }

    // Backtrack to find items
    var w = capacity;
    for (var i = n; i > 0; i--) {
      if (dp[i][w] != dp[i - 1][w]) {
        status[i * cols + w] = CellStatus.onPath;
        w -= weights[i - 1];
      }
    }

    states.add(DpState(
      table: List.of(table), cellStatus: List.of(status),
      rows: rows, cols: cols, rowLabels: rowLabels, colLabels: colLabels,
      result: '${dp[n][capacity]}',
      description: 'Maximum value: ${dp[n][capacity]}',
    ));

    return states;
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) =>
      DpPainter(state: state as DpState, colorScheme: Theme.of(context).colorScheme);

  @override
  List<LegendItem>? buildLegend(BuildContext context) => dpLegend(context);
}
