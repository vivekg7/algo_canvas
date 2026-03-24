import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';
import 'package:algo_canvas/algorithms/sorting/sorting_state.dart';
import 'package:algo_canvas/algorithms/sorting/sorting_painter.dart';

class SelectionSortAlgorithm extends Algorithm {
  int _arraySize = 30;

  @override
  String get name => 'Selection Sort';

  @override
  String get description =>
      'Finds the minimum element and places it at the beginning. O(n²).';

  @override
  AlgorithmCategory get category => AlgorithmCategory.sorting;

  @override
  Future<List<AlgorithmState>> generate() async {
    final random = Random();
    final array = List.generate(_arraySize, (_) => random.nextInt(100) + 1);
    final states = <SortingState>[];
    final sorted = <int>{};

    states.add(SortingState(
      array: List.of(array),
      description: 'Initial array with $_arraySize elements',
    ));

    for (var i = 0; i < array.length - 1; i++) {
      var minIdx = i;

      for (var j = i + 1; j < array.length; j++) {
        states.add(SortingState(
          array: List.of(array),
          comparing: {j},
          pivot: minIdx,
          sorted: Set.of(sorted),
          description:
              'Comparing ${array[j]} with current min ${array[minIdx]}',
        ));

        if (array[j] < array[minIdx]) {
          minIdx = j;
          states.add(SortingState(
            array: List.of(array),
            pivot: minIdx,
            sorted: Set.of(sorted),
            description: 'New minimum found: ${array[minIdx]} at index $minIdx',
          ));
        }
      }

      if (minIdx != i) {
        states.add(SortingState(
          array: List.of(array),
          swapping: {i, minIdx},
          sorted: Set.of(sorted),
          description: 'Swapping ${array[i]} and ${array[minIdx]}',
        ));
        final temp = array[i];
        array[i] = array[minIdx];
        array[minIdx] = temp;
      }

      sorted.add(i);
      states.add(SortingState(
        array: List.of(array),
        sorted: Set.of(sorted),
        description: '${array[i]} placed at position $i',
      ));
    }

    sorted.add(array.length - 1);
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
