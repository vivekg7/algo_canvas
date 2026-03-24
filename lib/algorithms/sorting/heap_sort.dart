import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';
import 'package:algo_canvas/algorithms/sorting/sorting_state.dart';
import 'package:algo_canvas/algorithms/sorting/sorting_painter.dart';

class HeapSortAlgorithm extends Algorithm {
  int _arraySize = 30;

  @override
  String get name => 'Heap Sort';

  @override
  String get description =>
      'Builds a max-heap, then repeatedly extracts the maximum. O(n log n).';

  @override
  AlgorithmCategory get category => AlgorithmCategory.sorting;

  @override
  Future<List<AlgorithmState>> generate() async {
    final random = Random();
    final array = List.generate(_arraySize, (_) => random.nextInt(100) + 1);
    final states = <SortingState>[];
    final sorted = <int>{};
    final n = array.length;

    states.add(SortingState(
      array: List.of(array),
      description: 'Initial array with $_arraySize elements',
    ));

    void heapify(List<int> arr, int size, int root) {
      var largest = root;
      final left = 2 * root + 1;
      final right = 2 * root + 2;

      if (left < size) {
        states.add(SortingState(
          array: List.of(arr),
          comparing: {largest, left},
          sorted: Set.of(sorted),
          description: 'Comparing ${arr[largest]} with left child ${arr[left]}',
        ));
        if (arr[left] > arr[largest]) largest = left;
      }

      if (right < size) {
        states.add(SortingState(
          array: List.of(arr),
          comparing: {largest, right},
          sorted: Set.of(sorted),
          description:
              'Comparing ${arr[largest]} with right child ${arr[right]}',
        ));
        if (arr[right] > arr[largest]) largest = right;
      }

      if (largest != root) {
        states.add(SortingState(
          array: List.of(arr),
          swapping: {root, largest},
          sorted: Set.of(sorted),
          description: 'Swapping ${arr[root]} and ${arr[largest]}',
        ));
        final temp = arr[root];
        arr[root] = arr[largest];
        arr[largest] = temp;

        heapify(arr, size, largest);
      }
    }

    // Build max heap
    states.add(SortingState(
      array: List.of(array),
      description: 'Building max heap...',
    ));

    for (var i = n ~/ 2 - 1; i >= 0; i--) {
      heapify(array, n, i);
    }

    states.add(SortingState(
      array: List.of(array),
      description: 'Max heap built. Largest element is ${array[0]}',
    ));

    // Extract elements from heap one by one
    for (var i = n - 1; i > 0; i--) {
      states.add(SortingState(
        array: List.of(array),
        swapping: {0, i},
        sorted: Set.of(sorted),
        description: 'Moving max ${array[0]} to position $i',
      ));

      final temp = array[0];
      array[0] = array[i];
      array[i] = temp;

      sorted.add(i);
      states.add(SortingState(
        array: List.of(array),
        sorted: Set.of(sorted),
        description: '${array[i]} is in its final position',
      ));

      heapify(array, i, 0);
    }

    sorted.add(0);
    states.add(SortingState(
      array: List.of(array),
      sorted: Set.of(List.generate(n, (i) => i)),
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
