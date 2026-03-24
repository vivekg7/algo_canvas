import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';
import 'package:algo_canvas/algorithms/dp/dp_state.dart';
import 'package:algo_canvas/algorithms/dp/dp_painter.dart';
import 'package:algo_canvas/algorithms/dp/dp_legend.dart';
import 'package:algo_canvas/widgets/color_legend.dart';

class FibonacciAlgorithm extends Algorithm {
  int _n = 15;

  @override
  String get name => 'Fibonacci';

  @override
  String get description => 'Tabulation vs memoization: fill the table left to right. O(n).';

  @override
  AlgorithmCategory get category => AlgorithmCategory.dynamicProgramming;

  @override
  Future<List<AlgorithmState>> generate() async {
    final n = _n;
    final states = <DpState>[];
    final table = List<String>.filled(n + 1, '');
    final status = List.filled(n + 1, CellStatus.empty);
    final colLabels = List.generate(n + 1, (i) => '$i');

    states.add(DpState(
      table: List.of(table), cellStatus: List.of(status),
      rows: 1, cols: n + 1, colLabels: colLabels,
      description: 'Computing Fibonacci(0) to Fibonacci($n)',
    ));

    table[0] = '0'; status[0] = CellStatus.computing;
    states.add(DpState(
      table: List.of(table), cellStatus: List.of(status),
      rows: 1, cols: n + 1, colLabels: colLabels, currentRow: 0, currentCol: 0,
      description: 'F(0) = 0',
    ));
    status[0] = CellStatus.filled;

    if (n >= 1) {
      table[1] = '1'; status[1] = CellStatus.computing;
      states.add(DpState(
        table: List.of(table), cellStatus: List.of(status),
        rows: 1, cols: n + 1, colLabels: colLabels, currentRow: 0, currentCol: 1,
        description: 'F(1) = 1',
      ));
      status[1] = CellStatus.filled;
    }

    final fib = List<int>.filled(n + 1, 0);
    fib[0] = 0;
    if (n >= 1) { fib[1] = 1; }

    for (var i = 2; i <= n; i++) {
      fib[i] = fib[i - 1] + fib[i - 2];
      status[i] = CellStatus.computing;
      states.add(DpState(
        table: List.of(table), cellStatus: List.of(status),
        rows: 1, cols: n + 1, colLabels: colLabels, currentRow: 0, currentCol: i,
        description: 'F($i) = F(${i - 1}) + F(${i - 2}) = ${fib[i - 1]} + ${fib[i - 2]}',
      ));

      table[i] = '${fib[i]}';
      status[i] = CellStatus.filled;
      states.add(DpState(
        table: List.of(table), cellStatus: List.of(status),
        rows: 1, cols: n + 1, colLabels: colLabels, currentRow: 0, currentCol: i,
        description: 'F($i) = ${fib[i]}',
      ));
    }

    states.add(DpState(
      table: List.of(table), cellStatus: List.of(status),
      rows: 1, cols: n + 1, colLabels: colLabels,
      result: '${fib[n]}', description: 'Fibonacci($n) = ${fib[n]}',
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
      _Ctrl(n: _n, onChanged: (v) { _n = v; onChanged(); });
}

class _Ctrl extends StatefulWidget {
  const _Ctrl({required this.n, required this.onChanged});
  final int n; final ValueChanged<int> onChanged;
  @override State<_Ctrl> createState() => _CtrlState();
}
class _CtrlState extends State<_Ctrl> {
  late double _v;
  @override void initState() { super.initState(); _v = widget.n.toDouble(); }
  @override Widget build(BuildContext context) => Row(children: [
    Text('n: ${_v.round()}', style: Theme.of(context).textTheme.bodySmall),
    Expanded(child: Slider(value: _v, min: 5, max: 30, divisions: 25,
      onChanged: (v) => setState(() => _v = v), onChangeEnd: (v) => widget.onChanged(v.round()))),
  ]);
}
