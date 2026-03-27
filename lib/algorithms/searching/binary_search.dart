import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';
import 'package:algo_canvas/algorithms/searching/searching_state.dart';
import 'package:algo_canvas/algorithms/searching/searching_painter.dart';

class BinarySearchAlgorithm extends Algorithm {
  int _arraySize = 30;

  @override
  String get name => 'Binary Search';

  @override
  String get description =>
      'Halves the search space each step on a sorted array. O(log n).';

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
      description: 'Searching for $target in sorted array of $_arraySize elements',
    ));

    var low = 0;
    var high = array.length - 1;

    while (low <= high) {
      final mid = (low + high) ~/ 2;

      states.add(SearchingState(
        array: List.of(array),
        target: target,
        checking: mid,
        rangeStart: low,
        rangeEnd: high,
        eliminated: Set.of(eliminated),
        description: 'Checking midpoint $mid: ${array[mid]} == $target?',
      ));

      if (array[mid] == target) {
        states.add(SearchingState(
          array: List.of(array),
          target: target,
          found: mid,
          eliminated: Set.of(eliminated),
          description: 'Found $target at index $mid!',
        ));
        return states;
      } else if (array[mid] < target) {
        // Eliminate left half
        for (var i = low; i <= mid; i++) {
          eliminated.add(i);
        }
        states.add(SearchingState(
          array: List.of(array),
          target: target,
          rangeStart: mid + 1,
          rangeEnd: high,
          eliminated: Set.of(eliminated),
          description:
              '${array[mid]} < $target, eliminating left half [$low..$mid]',
        ));
        low = mid + 1;
      } else {
        // Eliminate right half
        for (var i = mid; i <= high; i++) {
          eliminated.add(i);
        }
        states.add(SearchingState(
          array: List.of(array),
          target: target,
          rangeStart: low,
          rangeEnd: mid - 1,
          eliminated: Set.of(eliminated),
          description:
              '${array[mid]} > $target, eliminating right half [$mid..$high]',
        ));
        high = mid - 1;
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
