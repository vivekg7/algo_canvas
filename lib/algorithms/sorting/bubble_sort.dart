import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';
import 'package:algo_canvas/algorithms/sorting/sorting_state.dart';
import 'package:algo_canvas/algorithms/sorting/sorting_painter.dart';

class BubbleSortAlgorithm extends Algorithm {
  int _arraySize = 30;

  @override
  String get name => 'Bubble Sort';

  @override
  String get description =>
      'Repeatedly swaps adjacent elements if they are in the wrong order. O(n²).';

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

    for (var i = array.length - 1; i > 0; i--) {
      var swapped = false;
      for (var j = 0; j < i; j++) {
        states.add(SortingState(
          array: List.of(array),
          comparing: {j, j + 1},
          sorted: Set.of(sorted),
          description: 'Comparing ${array[j]} and ${array[j + 1]}',
        ));

        if (array[j] > array[j + 1]) {
          states.add(SortingState(
            array: List.of(array),
            swapping: {j, j + 1},
            sorted: Set.of(sorted),
            description: 'Swapping ${array[j]} and ${array[j + 1]}',
          ));
          final temp = array[j];
          array[j] = array[j + 1];
          array[j + 1] = temp;
          swapped = true;
        }
      }
      sorted.add(i);
      states.add(SortingState(
        array: List.of(array),
        sorted: Set.of(sorted),
        description: '${array[i]} is in its final position',
      ));
      if (!swapped) break;
    }

    sorted.add(0);
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
