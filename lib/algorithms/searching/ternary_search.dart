import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';
import 'package:algo_canvas/algorithms/searching/searching_state.dart';
import 'package:algo_canvas/algorithms/searching/searching_painter.dart';

class TernarySearchAlgorithm extends Algorithm {
  int _arraySize = 30;

  @override
  String get name => 'Ternary Search';

  @override
  String get description =>
      'Divides the search space into three parts each step. O(log₃ n).';

  @override
  AlgorithmCategory get category => AlgorithmCategory.searching;

  @override
  Future<List<AlgorithmState>> generate() async {
    final random = Random();
    final array = List.generate(_arraySize, (_) => random.nextInt(100) + 1);
    array.sort();
    final target = array[random.nextInt(array.length)];
    final states = <SearchingState>[];
    final eliminated = <int>{};

    states.add(SearchingState(
      array: List.of(array),
      target: target,
      rangeStart: 0,
      rangeEnd: array.length - 1,
      description:
          'Searching for $target in sorted array of $_arraySize elements',
    ));

    var low = 0;
    var high = array.length - 1;

    while (low <= high) {
      final third = (high - low) ~/ 3;
      final mid1 = low + third;
      final mid2 = high - third;

      // Check mid1
      states.add(SearchingState(
        array: List.of(array),
        target: target,
        checking: mid1,
        rangeStart: low,
        rangeEnd: high,
        eliminated: Set.of(eliminated),
        description: 'Checking first third at $mid1: ${array[mid1]} == $target?',
      ));

      if (array[mid1] == target) {
        states.add(SearchingState(
          array: List.of(array),
          target: target,
          found: mid1,
          eliminated: Set.of(eliminated),
          description: 'Found $target at index $mid1!',
        ));
        return states;
      }

      // Check mid2
      states.add(SearchingState(
        array: List.of(array),
        target: target,
        checking: mid2,
        rangeStart: low,
        rangeEnd: high,
        eliminated: Set.of(eliminated),
        description:
            'Checking second third at $mid2: ${array[mid2]} == $target?',
      ));

      if (array[mid2] == target) {
        states.add(SearchingState(
          array: List.of(array),
          target: target,
          found: mid2,
          eliminated: Set.of(eliminated),
          description: 'Found $target at index $mid2!',
        ));
        return states;
      }

      if (target < array[mid1]) {
        for (var i = mid1; i <= high; i++) {
          eliminated.add(i);
        }
        states.add(SearchingState(
          array: List.of(array),
          target: target,
          rangeStart: low,
          rangeEnd: mid1 - 1,
          eliminated: Set.of(eliminated),
          description:
              '$target < ${array[mid1]}, searching first third [$low..${mid1 - 1}]',
        ));
        high = mid1 - 1;
      } else if (target > array[mid2]) {
        for (var i = low; i <= mid2; i++) {
          eliminated.add(i);
        }
        states.add(SearchingState(
          array: List.of(array),
          target: target,
          rangeStart: mid2 + 1,
          rangeEnd: high,
          eliminated: Set.of(eliminated),
          description:
              '$target > ${array[mid2]}, searching last third [${mid2 + 1}..$high]',
        ));
        low = mid2 + 1;
      } else {
        for (var i = low; i <= mid1; i++) {
          eliminated.add(i);
        }
        for (var i = mid2; i <= high; i++) {
          eliminated.add(i);
        }
        states.add(SearchingState(
          array: List.of(array),
          target: target,
          rangeStart: mid1 + 1,
          rangeEnd: mid2 - 1,
          eliminated: Set.of(eliminated),
          description:
              '$target is between ${array[mid1]} and ${array[mid2]}, searching middle [${mid1 + 1}..${mid2 - 1}]',
        ));
        low = mid1 + 1;
        high = mid2 - 1;
      }
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
