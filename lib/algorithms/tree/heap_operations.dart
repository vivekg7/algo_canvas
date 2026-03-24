import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';
import 'package:algo_canvas/algorithms/tree/tree_state.dart';
import 'package:algo_canvas/algorithms/tree/tree_painter.dart';
import 'package:algo_canvas/algorithms/tree/tree_legend.dart';
import 'package:algo_canvas/widgets/color_legend.dart';

class HeapOperationsAlgorithm extends Algorithm {
  @override
  String get name => 'Heap Operations';

  @override
  String get description => 'Max-heap insert and extract-max, visualized as a binary tree.';

  @override
  AlgorithmCategory get category => AlgorithmCategory.tree;

  @override
  Future<List<AlgorithmState>> generate() async {
    final random = Random();
    final states = <TreeState>[];
    final heap = <int>[];

    states.add(const TreeState(nodes: {}, description: 'Max-Heap: insert and extract'));

    // Insert phase
    final values = List.generate(8, (_) => random.nextInt(50) + 1);
    for (final value in values) {
      heap.add(value);
      var i = heap.length - 1;

      var nodes = _layoutHeap(heap);
      nodes[i] = nodes[i]!.copyWith(status: TreeNodeStatus.inserted);
      states.add(TreeState(nodes: Map.of(nodes), rootId: 0,
        description: 'Inserted $value at index $i'));

      // Bubble up
      while (i > 0) {
        final parent = (i - 1) ~/ 2;
        if (heap[i] <= heap[parent]) { break; }

        nodes = _layoutHeap(heap);
        nodes[i] = nodes[i]!.copyWith(status: TreeNodeStatus.visiting);
        nodes[parent] = nodes[parent]!.copyWith(status: TreeNodeStatus.visiting);
        states.add(TreeState(nodes: Map.of(nodes), rootId: 0,
          description: 'Swap ${heap[i]} with parent ${heap[parent]}'));

        final temp = heap[i];
        heap[i] = heap[parent];
        heap[parent] = temp;
        i = parent;
      }

      nodes = _layoutHeap(heap);
      states.add(TreeState(nodes: Map.of(nodes), rootId: 0,
        description: 'Heap property restored'));
    }

    // Extract max
    for (var e = 0; e < 3 && heap.isNotEmpty; e++) {
      final maxVal = heap[0];
      var nodes = _layoutHeap(heap);
      nodes[0] = nodes[0]!.copyWith(status: TreeNodeStatus.found);
      states.add(TreeState(nodes: Map.of(nodes), rootId: 0,
        description: 'Extract max: $maxVal'));

      heap[0] = heap.last;
      heap.removeLast();
      if (heap.isEmpty) { break; }

      // Bubble down
      var i = 0;
      while (true) {
        var largest = i;
        final left = 2 * i + 1, right = 2 * i + 2;
        if (left < heap.length && heap[left] > heap[largest]) { largest = left; }
        if (right < heap.length && heap[right] > heap[largest]) { largest = right; }
        if (largest == i) { break; }

        nodes = _layoutHeap(heap);
        nodes[i] = nodes[i]!.copyWith(status: TreeNodeStatus.visiting);
        nodes[largest] = nodes[largest]!.copyWith(status: TreeNodeStatus.visiting);
        states.add(TreeState(nodes: Map.of(nodes), rootId: 0,
          description: 'Swap ${heap[i]} with ${heap[largest]}'));

        final temp = heap[i];
        heap[i] = heap[largest];
        heap[largest] = temp;
        i = largest;
      }

      nodes = _layoutHeap(heap);
      states.add(TreeState(nodes: Map.of(nodes), rootId: 0,
        description: 'Heap property restored after extraction'));
    }

    return states;
  }

  Map<int, TreeNode> _layoutHeap(List<int> heap) {
    if (heap.isEmpty) { return {}; }

    final nodes = <int, TreeNode>{};
    final maxDepth = (log(heap.length) / log(2)).floor();

    for (var i = 0; i < heap.length; i++) {
      final depth = (log(i + 1) / log(2)).floor();
      final posInLevel = i - (1 << depth) + 1;
      final nodesInLevel = min(1 << depth, heap.length - (1 << depth) + 1);

      final x = nodesInLevel <= 1
          ? 0.5
          : 0.05 + 0.9 * posInLevel / (nodesInLevel - 1);
      final y = maxDepth == 0 ? 0.1 : 0.05 + 0.9 * depth / maxDepth;

      final left = 2 * i + 1 < heap.length ? 2 * i + 1 : null;
      final right = 2 * i + 2 < heap.length ? 2 * i + 2 : null;

      nodes[i] = TreeNode(
        id: i, value: heap[i], x: x, y: y,
        left: left, right: right,
      );
    }

    return nodes;
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) =>
      TreePainter(state: state as TreeState, brightness: Theme.of(context).brightness);

  @override
  List<LegendItem>? buildLegend(BuildContext context) => treeLegend(context);
}
