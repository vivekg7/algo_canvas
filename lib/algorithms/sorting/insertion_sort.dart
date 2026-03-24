import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';
import 'package:algo_canvas/algorithms/sorting/sorting_state.dart';
import 'package:algo_canvas/algorithms/sorting/sorting_painter.dart';
import 'package:algo_canvas/algorithms/sorting/sorting_legend.dart';
import 'package:algo_canvas/widgets/color_legend.dart';

class InsertionSortAlgorithm extends Algorithm {
  int _arraySize = 30;

  @override
  String get name => 'Insertion Sort';

  @override
  String get description =>
      'Builds the sorted array one element at a time by inserting into position. O(n²).';

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

    for (var i = 1; i < array.length; i++) {
      final key = array[i];

      states.add(SortingState(
        array: List.of(array),
        pivot: i,
        sorted: Set.of(List.generate(i, (j) => j)),
        description: 'Picking element $key to insert into sorted portion',
      ));

      var j = i - 1;
      while (j >= 0 && array[j] > key) {
        states.add(SortingState(
          array: List.of(array),
          comparing: {j},
          pivot: j + 1,
          sorted: Set.of(List.generate(i, (k) => k)),
          description: '${array[j]} > $key, shifting ${array[j]} right',
        ));

        array[j + 1] = array[j];
        j--;

        states.add(SortingState(
          array: List.of(array),
          swapping: {j + 1, j + 2},
          sorted: Set.of(List.generate(i, (k) => k)),
          description: 'Shifted to make room for $key',
        ));
      }

      array[j + 1] = key;
      states.add(SortingState(
        array: List.of(array),
        sorted: Set.of(List.generate(i + 1, (k) => k)),
        description: 'Inserted $key at position ${j + 1}',
      ));
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
