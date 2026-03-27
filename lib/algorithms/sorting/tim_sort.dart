import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';
import 'package:algo_canvas/algorithms/sorting/sorting_state.dart';
import 'package:algo_canvas/algorithms/sorting/sorting_painter.dart';
import 'package:algo_canvas/algorithms/sorting/sorting_legend.dart';
import 'package:algo_canvas/widgets/color_legend.dart';

class TimSortAlgorithm extends Algorithm {
  int _arraySize = 30;
  static const _minRun = 4;

  @override
  String get name => 'Tim Sort';

  @override
  String get description =>
      'Hybrid of insertion sort and merge sort, used in Python and Java. O(n log n).';

  @override
  AlgorithmCategory get category => AlgorithmCategory.sorting;

  @override
  Future<List<AlgorithmState>> generate() async {
    final random = Random();
    final array = List.generate(_arraySize, (_) => random.nextInt(100) + 1);
    final states = <SortingState>[];
    final sorted = <int>{};

    // Use a smaller minRun for visualization clarity
    final minRun = _arraySize < 16 ? 2 : _minRun;

    states.add(SortingState(
      array: List.of(array),
      description: 'Initial array with $_arraySize elements (minRun=$minRun)',
    ));

    // Insertion sort for small runs
    void insertionSort(int left, int right) {
      states.add(SortingState(
        array: List.of(array),
        activeRange: (left, right),
        description: 'Insertion sort on run [$left..$right]',
      ));

      for (var i = left + 1; i <= right; i++) {
        final key = array[i];
        var j = i - 1;

        while (j >= left && array[j] > key) {
          states.add(SortingState(
            array: List.of(array),
            comparing: {j, j + 1},
            activeRange: (left, right),
            description: '${array[j]} > $key, shifting right',
          ));
          array[j + 1] = array[j];
          j--;
        }

        array[j + 1] = key;
        if (j + 1 != i) {
          states.add(SortingState(
            array: List.of(array),
            swapping: {j + 1},
            activeRange: (left, right),
            description: 'Inserted $key at position ${j + 1}',
          ));
        }
      }

      states.add(SortingState(
        array: List.of(array),
        activeRange: (left, right),
        description: 'Run [$left..$right] sorted via insertion sort',
      ));
    }

    // Merge two sorted runs
    void merge(int left, int mid, int right) {
      final leftArr = array.sublist(left, mid + 1);
      final rightArr = array.sublist(mid + 1, right + 1);

      states.add(SortingState(
        array: List.of(array),
        activeRange: (left, right),
        description: 'Merging runs [$left..$mid] and [${mid + 1}..$right]',
      ));

      var i = 0, j = 0, k = left;

      while (i < leftArr.length && j < rightArr.length) {
        states.add(SortingState(
          array: List.of(array),
          comparing: {left + i, mid + 1 + j},
          activeRange: (left, right),
          sorted: Set.of(sorted),
          description: 'Comparing ${leftArr[i]} and ${rightArr[j]}',
        ));

        if (leftArr[i] <= rightArr[j]) {
          array[k] = leftArr[i];
          i++;
        } else {
          array[k] = rightArr[j];
          j++;
        }

        states.add(SortingState(
          array: List.of(array),
          swapping: {k},
          activeRange: (left, right),
          sorted: Set.of(sorted),
          description: 'Placed ${array[k]} at position $k',
        ));
        k++;
      }

      while (i < leftArr.length) {
        array[k] = leftArr[i];
        i++;
        k++;
      }

      while (j < rightArr.length) {
        array[k] = rightArr[j];
        j++;
        k++;
      }
    }

    // Sort individual runs with insertion sort
    for (var start = 0; start < array.length; start += minRun) {
      final end = min(start + minRun - 1, array.length - 1);
      insertionSort(start, end);
    }

    // Merge runs, doubling size each pass
    for (var size = minRun; size < array.length; size *= 2) {
      states.add(SortingState(
        array: List.of(array),
        description: 'Merge pass: merging runs of size $size',
      ));

      for (var left = 0; left < array.length; left += 2 * size) {
        final mid = min(left + size - 1, array.length - 1);
        final right = min(left + 2 * size - 1, array.length - 1);

        if (mid < right) {
          merge(left, mid, right);

          for (var i = left; i <= right; i++) {
            sorted.add(i);
          }
          states.add(SortingState(
            array: List.of(array),
            sorted: Set.of(sorted),
            description: 'Merged [$left..$right]',
          ));
        }
      }
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
      colorScheme: Theme.of(context).colorScheme,
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
