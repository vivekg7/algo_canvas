import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';
import 'package:algo_canvas/algorithms/dp/dp_state.dart';
import 'package:algo_canvas/algorithms/dp/dp_painter.dart';
import 'package:algo_canvas/algorithms/dp/dp_legend.dart';
import 'package:algo_canvas/widgets/color_legend.dart';

class LisAlgorithm extends Algorithm {
  int _size = 10;

  @override
  String get name => 'LIS';

  @override
  String get description => 'Longest Increasing Subsequence using DP. O(n²).';

  @override
  AlgorithmCategory get category => AlgorithmCategory.dynamicProgramming;

  @override
  Future<List<AlgorithmState>> generate() async {
    final random = Random();
    final arr = List.generate(_size, (_) => random.nextInt(20) + 1);
    final n = arr.length;
    final dp = List.filled(n, 1);
    final states = <DpState>[];

    // Two rows: array values and dp values
    final rows = 2;
    final cols = n;
    final table = List<String>.filled(rows * cols, '');
    final status = List.filled(rows * cols, CellStatus.empty);
    final colLabels = List.generate(n, (i) => '$i');
    final rowLabels = ['arr', 'dp'];

    // Fill array row
    for (var i = 0; i < n; i++) {
      table[i] = '${arr[i]}';
      status[i] = CellStatus.filled;
    }
    // Initialize dp row
    for (var i = 0; i < n; i++) {
      table[cols + i] = '1';
      status[cols + i] = CellStatus.filled;
    }

    states.add(DpState(
      table: List.of(table), cellStatus: List.of(status),
      rows: rows, cols: cols, colLabels: colLabels, rowLabels: rowLabels,
      description: 'Array: ${arr.join(", ")}. Finding LIS.',
    ));

    for (var i = 1; i < n; i++) {
      status[cols + i] = CellStatus.computing;
      for (var j = 0; j < i; j++) {
        states.add(DpState(
          table: List.of(table), cellStatus: List.of(status),
          rows: rows, cols: cols, colLabels: colLabels, rowLabels: rowLabels,
          currentRow: 1, currentCol: i,
          description: 'Comparing arr[$j]=${arr[j]} < arr[$i]=${arr[i]}?',
        ));

        if (arr[j] < arr[i] && dp[j] + 1 > dp[i]) {
          dp[i] = dp[j] + 1;
          table[cols + i] = '${dp[i]}';
          states.add(DpState(
            table: List.of(table), cellStatus: List.of(status),
            rows: rows, cols: cols, colLabels: colLabels, rowLabels: rowLabels,
            currentRow: 1, currentCol: i,
            description: 'dp[$i] = dp[$j] + 1 = ${dp[i]}',
          ));
        }
      }
      status[cols + i] = CellStatus.filled;
    }

    // Backtrack LIS
    final lisLen = dp.reduce(max);
    var current = lisLen;
    for (var i = n - 1; i >= 0; i--) {
      if (dp[i] == current) {
        status[cols + i] = CellStatus.onPath;
        current--;
      }
    }

    states.add(DpState(
      table: List.of(table), cellStatus: List.of(status),
      rows: rows, cols: cols, colLabels: colLabels, rowLabels: rowLabels,
      result: '$lisLen', description: 'LIS length = $lisLen',
    ));

    return states;
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) =>
      DpPainter(state: state as DpState, colorScheme: Theme.of(context).colorScheme);

  @override
  List<LegendItem>? buildLegend(BuildContext context) => dpLegend(context);

  @override
  Widget? buildControls({required VoidCallback onChanged}) =>
      _Ctrl(size: _size, onChanged: (v) { _size = v; onChanged(); });
}

class _Ctrl extends StatefulWidget {
  const _Ctrl({required this.size, required this.onChanged});
  final int size; final ValueChanged<int> onChanged;
  @override State<_Ctrl> createState() => _CtrlState();
}
class _CtrlState extends State<_Ctrl> {
  late double _v;
  @override void initState() { super.initState(); _v = widget.size.toDouble(); }
  @override Widget build(BuildContext context) => Row(children: [
    Text('Size: ${_v.round()}', style: Theme.of(context).textTheme.bodySmall),
    Expanded(child: Slider(value: _v, min: 5, max: 20, divisions: 15,
      onChanged: (v) => setState(() => _v = v), onChangeEnd: (v) => widget.onChanged(v.round()))),
  ]);
}
