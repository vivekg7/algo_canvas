import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';
import 'package:algo_canvas/algorithms/sorting/sorting_state.dart';
import 'package:algo_canvas/algorithms/sorting/sorting_painter.dart';
import 'package:algo_canvas/algorithms/sorting/sorting_legend.dart';
import 'package:algo_canvas/widgets/color_legend.dart';

class ShellSortAlgorithm extends Algorithm {
  int _arraySize = 30;

  @override
  String get name => 'Shell Sort';

  @override
  String get description =>
      'Generalized insertion sort with decreasing gap sequence. O(n log²n).';

  @override
  AlgorithmCategory get category => AlgorithmCategory.sorting;

  @override
  Future<List<AlgorithmState>> generate() async {
    final random = Random();
    final array = List.generate(_arraySize, (_) => random.nextInt(100) + 1);
    final states = <SortingState>[];

    states.add(SortingState(
      array: List.of(array),
      description: 'Initial array with $_arraySize elements',
    ));

    var gap = array.length ~/ 2;

    while (gap > 0) {
      states.add(SortingState(
        array: List.of(array),
        description: 'Gap = $gap: performing gapped insertion sort',
      ));

      for (var i = gap; i < array.length; i++) {
        final key = array[i];
        var j = i;

        states.add(SortingState(
          array: List.of(array),
          pivot: i,
          description: 'Inserting ${array[i]} with gap $gap',
        ));

        while (j >= gap && array[j - gap] > key) {
          states.add(SortingState(
            array: List.of(array),
            comparing: {j, j - gap},
            description:
                '${array[j - gap]} > $key, shifting ${array[j - gap]}',
          ));

          array[j] = array[j - gap];

          states.add(SortingState(
            array: List.of(array),
            swapping: {j, j - gap},
            description: 'Shifted ${array[j]} to position $j',
          ));

          j -= gap;
        }

        array[j] = key;
        if (j != i) {
          states.add(SortingState(
            array: List.of(array),
            swapping: {j},
            description: 'Placed $key at position $j',
          ));
        }
      }

      states.add(SortingState(
        array: List.of(array),
        description: 'Gap $gap pass complete',
      ));

      gap ~/= 2;
    }

    states.add(SortingState(
      array: List.of(array),
      sorted: Set.of(List.generate(array.length, (i) => i)),
      description: 'Array is fully sorted!',
    ));

    return states;
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) {
    return SortingPainter(
      state: state as SortingState,
      brightness: Theme.of(context).brightness,
    );
  }

  @override
  List<LegendItem>? buildLegend(BuildContext context) => sortingLegend(context);

  @override
  Widget? buildControls({required VoidCallback onChanged}) {
    return _SizeControl(
      arraySize: _arraySize,
      onChanged: (size) {
        _arraySize = size;
        onChanged();
      },
    );
  }
}

class _SizeControl extends StatefulWidget {
  const _SizeControl({required this.arraySize, required this.onChanged});
  final int arraySize;
  final ValueChanged<int> onChanged;

  @override
  State<_SizeControl> createState() => _SizeControlState();
}

class _SizeControlState extends State<_SizeControl> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.arraySize.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('Size: ${_value.round()}',
            style: Theme.of(context).textTheme.bodySmall),
        Expanded(
          child: Slider(
            value: _value,
            min: 5,
            max: 200,
            divisions: 39,
            onChanged: (v) => setState(() => _value = v),
            onChangeEnd: (v) => widget.onChanged(v.round()),
          ),
        ),
      ],
    );
  }
}
