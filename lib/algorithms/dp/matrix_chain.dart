import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';
import 'package:algo_canvas/algorithms/dp/dp_state.dart';
import 'package:algo_canvas/algorithms/dp/dp_painter.dart';
import 'package:algo_canvas/algorithms/dp/dp_legend.dart';
import 'package:algo_canvas/widgets/color_legend.dart';

class MatrixChainAlgorithm extends Algorithm {
  @override
  String get name => 'Matrix Chain';

  @override
  String get description => 'Optimal parenthesization for matrix multiplication. O(n³).';

  @override
  AlgorithmCategory get category => AlgorithmCategory.dynamicProgramming;

  @override
  Future<List<AlgorithmState>> generate() async {
    final random = Random();
    final n = 4 + random.nextInt(3); // 4-6 matrices
    final dims = List.generate(n + 1, (_) => (random.nextInt(9) + 2) * 5); // dimensions

    final states = <DpState>[];
    final dp = List.generate(n, (_) => List.filled(n, 0));
    final table = List<String>.filled(n * n, '');
    final status = List.filled(n * n, CellStatus.empty);
    final labels = List.generate(n, (i) => 'M${i + 1}');

    // Diagonal = 0
    for (var i = 0; i < n; i++) {
      table[i * n + i] = '0';
      status[i * n + i] = CellStatus.filled;
    }

    final dimsStr = List.generate(n, (i) => '${dims[i]}×${dims[i + 1]}').join(', ');
    states.add(DpState(
      table: List.of(table), cellStatus: List.of(status),
      rows: n, cols: n, rowLabels: labels, colLabels: labels,
      description: 'Matrix chain: $dimsStr',
    ));

    // Fill by chain length
    for (var len = 2; len <= n; len++) {
      for (var i = 0; i <= n - len; i++) {
        final j = i + len - 1;
        final idx = i * n + j;
        dp[i][j] = 1 << 30; // infinity
        status[idx] = CellStatus.computing;

        states.add(DpState(
          table: List.of(table), cellStatus: List.of(status),
          rows: n, cols: n, rowLabels: labels, colLabels: labels,
          currentRow: i, currentCol: j,
          description: 'Computing cost for M${i + 1}..M${j + 1} (chain length $len)',
        ));

        for (var k = i; k < j; k++) {
          final cost = dp[i][k] + dp[k + 1][j] + dims[i] * dims[k + 1] * dims[j + 1];
          if (cost < dp[i][j]) {
            dp[i][j] = cost;
            table[idx] = '${dp[i][j]}';
            states.add(DpState(
              table: List.of(table), cellStatus: List.of(status),
              rows: n, cols: n, rowLabels: labels, colLabels: labels,
              currentRow: i, currentCol: j,
              description: 'Split at k=${k + 1}: ${dp[i][k]} + ${dp[k + 1][j]} + ${dims[i]}×${dims[k + 1]}×${dims[j + 1]} = $cost',
            ));
          }
        }

        status[idx] = CellStatus.filled;
      }
    }

    states.add(DpState(
      table: List.of(table), cellStatus: List.of(status),
      rows: n, cols: n, rowLabels: labels, colLabels: labels,
      result: '${dp[0][n - 1]}',
      description: 'Minimum multiplications: ${dp[0][n - 1]}',
    ));

    return states;
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) =>
      DpPainter(state: state as DpState, colorScheme: Theme.of(context).colorScheme);

  @override
  List<LegendItem>? buildLegend(BuildContext context) => dpLegend(context);
}
