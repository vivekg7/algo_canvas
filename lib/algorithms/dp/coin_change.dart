import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';
import 'package:algo_canvas/algorithms/dp/dp_state.dart';
import 'package:algo_canvas/algorithms/dp/dp_painter.dart';
import 'package:algo_canvas/algorithms/dp/dp_legend.dart';
import 'package:algo_canvas/widgets/color_legend.dart';

class CoinChangeAlgorithm extends Algorithm {
  int _amount = 11;

  @override
  String get name => 'Coin Change';

  @override
  String get description => 'Minimum coins to make a given amount. O(amount × coins).';

  @override
  AlgorithmCategory get category => AlgorithmCategory.dynamicProgramming;

  @override
  Future<List<AlgorithmState>> generate() async {
    const coins = [1, 3, 4, 5];
    final amount = _amount;
    final cols = amount + 1;
    final states = <DpState>[];

    // 1D DP table displayed as a single row
    final dp = List.filled(cols, amount + 1);
    dp[0] = 0;
    final table = List<String>.filled(cols, '');
    final status = List.filled(cols, CellStatus.empty);
    final colLabels = List.generate(cols, (i) => '$i');

    table[0] = '0';
    status[0] = CellStatus.filled;

    states.add(DpState(
      table: List.of(table), cellStatus: List.of(status),
      rows: 1, cols: cols, colLabels: colLabels,
      description: 'Coins: $coins, Amount: $amount',
    ));

    for (var i = 1; i <= amount; i++) {
      status[i] = CellStatus.computing;
      states.add(DpState(
        table: List.of(table), cellStatus: List.of(status),
        rows: 1, cols: cols, colLabels: colLabels, currentRow: 0, currentCol: i,
        description: 'Computing min coins for amount $i',
      ));

      for (final coin in coins) {
        if (coin <= i && dp[i - coin] + 1 < dp[i]) {
          dp[i] = dp[i - coin] + 1;
          states.add(DpState(
            table: List.of(table), cellStatus: List.of(status),
            rows: 1, cols: cols, colLabels: colLabels, currentRow: 0, currentCol: i,
            description: 'Using coin $coin: dp[$i] = dp[${i - coin}] + 1 = ${dp[i]}',
          ));
        }
      }

      table[i] = dp[i] > amount ? '∞' : '${dp[i]}';
      status[i] = CellStatus.filled;
      states.add(DpState(
        table: List.of(table), cellStatus: List.of(status),
        rows: 1, cols: cols, colLabels: colLabels, currentRow: 0, currentCol: i,
        description: 'dp[$i] = ${dp[i] > amount ? "∞" : dp[i]}',
      ));
    }

    // Backtrack to find coins used
    if (dp[amount] <= amount) {
      var rem = amount;
      while (rem > 0) {
        status[rem] = CellStatus.onPath;
        for (final coin in coins) {
          if (coin <= rem && dp[rem] == dp[rem - coin] + 1) {
            rem -= coin;
            break;
          }
        }
      }
      status[0] = CellStatus.onPath;
    }

    final result = dp[amount] > amount ? 'impossible' : '${dp[amount]}';
    states.add(DpState(
      table: List.of(table), cellStatus: List.of(status),
      rows: 1, cols: cols, colLabels: colLabels,
      result: result, description: 'Minimum coins for $amount: $result',
    ));

    return states;
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) =>
      DpPainter(state: state as DpState, brightness: Theme.of(context).brightness);

  @override
  List<LegendItem>? buildLegend(BuildContext context) => dpLegend(context);

  @override
  Widget? buildControls({required VoidCallback onChanged}) =>
      _Ctrl(amount: _amount, onChanged: (v) { _amount = v; onChanged(); });
}

class _Ctrl extends StatefulWidget {
  const _Ctrl({required this.amount, required this.onChanged});
  final int amount; final ValueChanged<int> onChanged;
  @override State<_Ctrl> createState() => _CtrlState();
}
class _CtrlState extends State<_Ctrl> {
  late double _v;
  @override void initState() { super.initState(); _v = widget.amount.toDouble(); }
  @override Widget build(BuildContext context) => Row(children: [
    Text('Amount: ${_v.round()}', style: Theme.of(context).textTheme.bodySmall),
    Expanded(child: Slider(value: _v, min: 5, max: 30, divisions: 25,
      onChanged: (v) => setState(() => _v = v), onChangeEnd: (v) => widget.onChanged(v.round()))),
  ]);
}
