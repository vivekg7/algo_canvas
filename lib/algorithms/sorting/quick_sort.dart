import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';
import 'package:algo_canvas/algorithms/sorting/sorting_state.dart';
import 'package:algo_canvas/algorithms/sorting/sorting_painter.dart';
import 'package:algo_canvas/algorithms/sorting/sorting_legend.dart';
import 'package:algo_canvas/widgets/color_legend.dart';

class QuickSortAlgorithm extends Algorithm {
  int _arraySize = 30;

  @override
  String get name => 'Quick Sort';

  @override
  String get description =>
      'Divide-and-conquer sorting using pivot partitioning. O(n log n) average.';

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

    void quickSort(List<int> arr, int low, int high) {
      if (low >= high) {
        if (low == high) {
          sorted.add(low);
          states.add(SortingState(
            array: List.of(arr),
            sorted: Set.of(sorted),
            description: 'Element at index $low is in its final position',
          ));
        }
        return;
      }

      // Choose pivot (last element)
      final pivotVal = arr[high];
      states.add(SortingState(
        array: List.of(arr),
        pivot: high,
        activeRange: (low, high),
        sorted: Set.of(sorted),
        description: 'Pivot selected: $pivotVal (index $high)',
      ));

      var i = low - 1;

      for (var j = low; j < high; j++) {
        // Comparing
        states.add(SortingState(
          array: List.of(arr),
          comparing: {j},
          pivot: high,
          activeRange: (low, high),
          sorted: Set.of(sorted),
          description: 'Comparing ${arr[j]} with pivot $pivotVal',
        ));

        if (arr[j] <= pivotVal) {
          i++;
          if (i != j) {
            // Swap
            states.add(SortingState(
              array: List.of(arr),
              swapping: {i, j},
              pivot: high,
              activeRange: (low, high),
              sorted: Set.of(sorted),
              description: 'Swapping ${arr[i]} and ${arr[j]}',
            ));
            final temp = arr[i];
            arr[i] = arr[j];
            arr[j] = temp;
            states.add(SortingState(
              array: List.of(arr),
              swapping: {i, j},
              pivot: high,
              activeRange: (low, high),
              sorted: Set.of(sorted),
              description: 'Swapped: ${arr[i]} and ${arr[j]}',
            ));
          }
        }
      }

      // Place pivot in correct position
      final pivotIndex = i + 1;
      if (pivotIndex != high) {
        states.add(SortingState(
          array: List.of(arr),
          swapping: {pivotIndex, high},
          pivot: high,
          activeRange: (low, high),
          sorted: Set.of(sorted),
          description:
              'Placing pivot $pivotVal at position $pivotIndex',
        ));
        final temp = arr[pivotIndex];
        arr[pivotIndex] = arr[high];
        arr[high] = temp;
      }

      sorted.add(pivotIndex);
      states.add(SortingState(
        array: List.of(arr),
        sorted: Set.of(sorted),
        description:
            'Pivot $pivotVal is now at its final position ($pivotIndex)',
      ));

      quickSort(arr, low, pivotIndex - 1);
      quickSort(arr, pivotIndex + 1, high);
    }

    quickSort(array, 0, array.length - 1);

    // Final state: everything sorted
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
    return _QuickSortControls(
      arraySize: _arraySize,
      onArraySizeChanged: (size) {
        _arraySize = size;
        onChanged();
      },
    );
  }

}

class _QuickSortControls extends StatefulWidget {
  const _QuickSortControls({
    required this.arraySize,
    required this.onArraySizeChanged,
  });

  final int arraySize;
  final ValueChanged<int> onArraySizeChanged;

  @override
  State<_QuickSortControls> createState() => _QuickSortControlsState();
}

class _QuickSortControlsState extends State<_QuickSortControls> {
  late double _sliderValue;

  @override
  void initState() {
    super.initState();
    _sliderValue = widget.arraySize.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Size: ${_sliderValue.round()}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Expanded(
          child: Slider(
            value: _sliderValue,
            min: 5,
            max: 200,
            divisions: 39,
            onChanged: (value) {
              setState(() => _sliderValue = value);
            },
            onChangeEnd: (value) {
              widget.onArraySizeChanged(value.round());
            },
          ),
        ),
      ],
    );
  }
}
