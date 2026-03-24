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
  static const _colsPerRow = 10;

  @override
  String get name => 'Fibonacci';

  @override
  String get description => 'Tabulation vs memoization: fill the table left to right. O(n).';

  @override
  AlgorithmCategory get category => AlgorithmCategory.dynamicProgramming;

  @override
  Future<List<AlgorithmState>> generate() async {
    final n = _n;
    final total = n + 1;
    final cols = _colsPerRow;
    final rows = (total / cols).ceil();
    final gridSize = rows * cols;

    final states = <DpState>[];
    final table = List<String>.filled(gridSize, '');
    final status = List.filled(gridSize, CellStatus.empty);
    final colLabels = List.generate(cols, (i) => '$i');
    final rowLabels = List.generate(rows, (r) => '${r * cols}');

    DpState snap(String desc, {int? curRow, int? curCol}) {
      return DpState(
        table: List.of(table),
        cellStatus: List.of(status),
        rows: rows,
        cols: cols,
        colLabels: colLabels,
        rowLabels: rowLabels,
        currentRow: curRow,
        currentCol: curCol,
        description: desc,
      );
    }

    states.add(snap('Computing Fibonacci(0) to Fibonacci($n)'));

    final fib = List<int>.filled(n + 1, 0);
    fib[0] = 0;
    table[0] = '0';
    status[0] = CellStatus.computing;
    states.add(snap('F(0) = 0', curRow: 0, curCol: 0));
    status[0] = CellStatus.filled;

    if (n >= 1) {
      fib[1] = 1;
      table[1] = '1';
      status[1] = CellStatus.computing;
      states.add(snap('F(1) = 1', curRow: 0, curCol: 1));
      status[1] = CellStatus.filled;
    }

    for (var i = 2; i <= n; i++) {
      fib[i] = fib[i - 1] + fib[i - 2];
      final r = i ~/ cols;
      final c = i % cols;

      status[i] = CellStatus.computing;
      states.add(snap(
        'F($i) = F(${i - 1}) + F(${i - 2}) = ${fib[i - 1]} + ${fib[i - 2]}',
        curRow: r, curCol: c,
      ));

      table[i] = '${fib[i]}';
      status[i] = CellStatus.filled;
      states.add(snap('F($i) = ${fib[i]}', curRow: r, curCol: c));
    }

    states.add(DpState(
      table: List.of(table),
      cellStatus: List.of(status),
      rows: rows,
      cols: cols,
      colLabels: colLabels,
      rowLabels: rowLabels,
      result: '${fib[n]}',
      description: 'Fibonacci($n) = ${fib[n]}',
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
