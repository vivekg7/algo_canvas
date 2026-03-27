import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';
import 'package:algo_canvas/algorithms/searching/searching_state.dart';
import 'package:algo_canvas/algorithms/searching/searching_painter.dart';

class LinearSearchAlgorithm extends Algorithm {
  int _arraySize = 30;

  @override
  String get name => 'Linear Search';

  @override
  String get description =>
      'Scans each element sequentially until the target is found. O(n).';

  @override
  AlgorithmCategory get category => AlgorithmCategory.searching;

  @override
  Future<List<AlgorithmState>> generate() async {
    final random = Random();
    final array = List.generate(_arraySize, (_) => random.nextInt(100) + 1);
    final target = array[random.nextInt(array.length)];
    final states = <SearchingState>[];
    final eliminated = <int>{};

    states.add(SearchingState(
      array: List.of(array),
      target: target,
      description: 'Searching for $target in unsorted array of $_arraySize elements',
    ));

    for (var i = 0; i < array.length; i++) {
      states.add(SearchingState(
        array: List.of(array),
        target: target,
        checking: i,
        eliminated: Set.of(eliminated),
        description: 'Checking index $i: ${array[i]} == $target?',
      ));

      if (array[i] == target) {
        states.add(SearchingState(
          array: List.of(array),
          target: target,
          found: i,
          eliminated: Set.of(eliminated),
          description: 'Found $target at index $i!',
        ));
        return states;
      }

      eliminated.add(i);
      states.add(SearchingState(
        array: List.of(array),
        target: target,
        eliminated: Set.of(eliminated),
        description: '${array[i]} != $target, moving on',
      ));
    }

    states.add(SearchingState(
      array: List.of(array),
      target: target,
      found: -1,
      eliminated: Set.of(eliminated),
      description: '$target not found in array',
    ));

    return states;
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) {
    return SearchingPainter(
      state: state as SearchingState,
      colorScheme: Theme.of(context).colorScheme,
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
