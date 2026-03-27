import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';
import 'package:algo_canvas/algorithms/searching/searching_state.dart';
import 'package:algo_canvas/algorithms/searching/searching_painter.dart';

class JumpSearchAlgorithm extends Algorithm {
  int _arraySize = 30;

  @override
  String get name => 'Jump Search';

  @override
  String get description =>
      'Jumps ahead by √n steps, then linear searches the block. O(√n).';

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
    final n = array.length;
    final jump = sqrt(n).floor();

    states.add(SearchingState(
      array: List.of(array),
      target: target,
      rangeStart: 0,
      rangeEnd: n - 1,
      description:
          'Searching for $target with jump size $jump (√$n)',
    ));

    // Jump phase
    var prev = 0;
    var curr = 0;

    while (curr < n && array[curr] < target) {
      states.add(SearchingState(
        array: List.of(array),
        target: target,
        checking: curr,
        rangeStart: prev,
        rangeEnd: min(curr + jump, n) - 1,
        eliminated: Set.of(eliminated),
        description:
            'Jump: checking index $curr (${array[curr]}). ${array[curr]} < $target, jumping ahead',
      ));

      for (var i = prev; i < curr; i++) {
        eliminated.add(i);
      }
      prev = curr;
      curr = min(curr + jump, n);
    }

    if (curr < n) {
      states.add(SearchingState(
        array: List.of(array),
        target: target,
        checking: curr,
        rangeStart: prev,
        rangeEnd: min(curr, n - 1),
        eliminated: Set.of(eliminated),
        description:
            'Jump: ${array[curr]} >= $target. Linear search in block [$prev..${min(curr, n - 1)}]',
      ));
    } else {
      states.add(SearchingState(
        array: List.of(array),
        target: target,
        rangeStart: prev,
        rangeEnd: n - 1,
        eliminated: Set.of(eliminated),
        description:
            'Reached end. Linear search in block [$prev..${n - 1}]',
      ));
    }

    // Linear phase within block
    for (var i = prev; i < min(curr + 1, n); i++) {
      states.add(SearchingState(
        array: List.of(array),
        target: target,
        checking: i,
        rangeStart: prev,
        rangeEnd: min(curr, n - 1),
        eliminated: Set.of(eliminated),
        description: 'Linear: checking index $i: ${array[i]} == $target?',
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
