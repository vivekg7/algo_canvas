import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';
import 'package:algo_canvas/algorithms/sorting/sorting_state.dart';
import 'package:algo_canvas/algorithms/sorting/sorting_painter.dart';
import 'package:algo_canvas/algorithms/sorting/sorting_legend.dart';
import 'package:algo_canvas/widgets/color_legend.dart';

class RadixSortAlgorithm extends Algorithm {
  int _arraySize = 30;

  @override
  String get name => 'Radix Sort';

  @override
  String get description =>
      'Non-comparative sort processing digits from least to most significant. O(nk).';

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

    for (var exp = 1; maxVal ~/ exp > 0; exp *= 10) {
      states.add(SortingState(
        array: List.of(array),
        description: 'Sorting by ${exp == 1 ? "ones" : exp == 10 ? "tens" : "hundreds"} digit',
      ));

      final output = List<int>.filled(array.length, 0);
      final count = List<int>.filled(10, 0);

      // Count occurrences
      for (var i = 0; i < array.length; i++) {
        final digit = (array[i] ~/ exp) % 10;
        count[digit]++;
        states.add(SortingState(
          array: List.of(array),
          comparing: {i},
          description:
              '${array[i]} has digit $digit in ${exp == 1 ? "ones" : exp == 10 ? "tens" : "hundreds"} place',
        ));
      }

      // Cumulative count
      for (var i = 1; i < 10; i++) {
        count[i] += count[i - 1];
      }

      // Build output (stable, right to left)
      for (var i = array.length - 1; i >= 0; i--) {
        final digit = (array[i] ~/ exp) % 10;
        final pos = count[digit] - 1;
        output[pos] = array[i];
        count[digit]--;
      }

      // Copy back
      for (var i = 0; i < array.length; i++) {
        array[i] = output[i];
      }

      states.add(SortingState(
        array: List.of(array),
        description:
            'After sorting by ${exp == 1 ? "ones" : exp == 10 ? "tens" : "hundreds"} digit',
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
