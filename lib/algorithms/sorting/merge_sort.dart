import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';
import 'package:algo_canvas/algorithms/sorting/sorting_state.dart';
import 'package:algo_canvas/algorithms/sorting/sorting_painter.dart';
import 'package:algo_canvas/algorithms/sorting/sorting_legend.dart';
import 'package:algo_canvas/widgets/color_legend.dart';

class MergeSortAlgorithm extends Algorithm {
  int _arraySize = 30;

  @override
  String get name => 'Merge Sort';

  @override
  String get description =>
      'Divide-and-conquer: split in half, sort each, then merge. O(n log n).';

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

    void merge(List<int> arr, int left, int mid, int right) {
      final leftArr = arr.sublist(left, mid + 1);
      final rightArr = arr.sublist(mid + 1, right + 1);

      states.add(SortingState(
        array: List.of(arr),
        activeRange: (left, right),
        description: 'Merging [$left..$mid] and [${mid + 1}..$right]',
      ));

      var i = 0, j = 0, k = left;

      while (i < leftArr.length && j < rightArr.length) {
        states.add(SortingState(
          array: List.of(arr),
          comparing: {left + i, mid + 1 + j},
          activeRange: (left, right),
          sorted: Set.of(sorted),
          description:
              'Comparing ${leftArr[i]} and ${rightArr[j]}',
        ));

        if (leftArr[i] <= rightArr[j]) {
          arr[k] = leftArr[i];
          i++;
        } else {
          arr[k] = rightArr[j];
          j++;
        }

        states.add(SortingState(
          array: List.of(arr),
          swapping: {k},
          activeRange: (left, right),
          sorted: Set.of(sorted),
          description: 'Placed ${arr[k]} at position $k',
        ));
        k++;
      }

      while (i < leftArr.length) {
        arr[k] = leftArr[i];
        states.add(SortingState(
          array: List.of(arr),
          swapping: {k},
          activeRange: (left, right),
          sorted: Set.of(sorted),
          description: 'Placed remaining ${arr[k]} at position $k',
        ));
        i++;
        k++;
      }

      while (j < rightArr.length) {
        arr[k] = rightArr[j];
        states.add(SortingState(
          array: List.of(arr),
          swapping: {k},
          activeRange: (left, right),
          sorted: Set.of(sorted),
          description: 'Placed remaining ${arr[k]} at position $k',
        ));
        j++;
        k++;
      }
    }

    void mergeSort(List<int> arr, int left, int right) {
      if (left >= right) {
        if (left == right) {
          sorted.add(left);
        }
        return;
      }

      final mid = (left + right) ~/ 2;

      states.add(SortingState(
        array: List.of(arr),
        activeRange: (left, right),
        pivot: mid,
        sorted: Set.of(sorted),
        description: 'Splitting [$left..$right] at midpoint $mid',
      ));

      mergeSort(arr, left, mid);
      mergeSort(arr, mid + 1, right);
      merge(arr, left, mid, right);

      for (var i = left; i <= right; i++) {
        sorted.add(i);
      }
      states.add(SortingState(
        array: List.of(arr),
        sorted: Set.of(sorted),
        description: 'Merged range [$left..$right]',
      ));
    }

    mergeSort(array, 0, array.length - 1);

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
