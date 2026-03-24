import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';
import 'package:algo_canvas/algorithms/sorting/sorting_state.dart';
import 'package:algo_canvas/algorithms/sorting/sorting_painter.dart';
import 'package:algo_canvas/algorithms/sorting/sorting_legend.dart';
import 'package:algo_canvas/widgets/color_legend.dart';

class CountingSortAlgorithm extends Algorithm {
  int _arraySize = 30;

  @override
  String get name => 'Counting Sort';

  @override
  String get description =>
      'Counts occurrences of each value to determine positions. O(n + k).';

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

    final maxVal = array.reduce((a, b) => a > b ? a : b);
    final count = List<int>.filled(maxVal + 1, 0);

    // Count occurrences
    for (var i = 0; i < array.length; i++) {
      count[array[i]]++;
      states.add(SortingState(
        array: List.of(array),
        comparing: {i},
        description: 'Counting ${array[i]} (count: ${count[array[i]]})',
      ));
    }

    states.add(SortingState(
      array: List.of(array),
      description: 'Counting complete. Building sorted array...',
    ));

    // Cumulative count
    for (var i = 1; i <= maxVal; i++) {
      count[i] += count[i - 1];
    }

    // Build output (stable, right to left)
    final output = List<int>.filled(array.length, 0);
    final placed = <int>{};

    for (var i = array.length - 1; i >= 0; i--) {
      final pos = count[array[i]] - 1;
      output[pos] = array[i];
      count[array[i]]--;
      placed.add(pos);

      states.add(SortingState(
        array: List.of(output),
        swapping: {pos},
        sorted: Set.of(placed),
        description: 'Placing ${array[i]} at position $pos',
      ));
    }

    states.add(SortingState(
      array: List.of(output),
      sorted: Set.of(List.generate(output.length, (i) => i)),
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
