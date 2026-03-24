import 'dart:collection';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';
import 'package:algo_canvas/algorithms/tree/tree_state.dart';
import 'package:algo_canvas/algorithms/tree/tree_painter.dart';
import 'package:algo_canvas/algorithms/tree/tree_legend.dart';
import 'package:algo_canvas/algorithms/tree/bst_helper.dart';
import 'package:algo_canvas/widgets/color_legend.dart';

class LevelOrderTraversalAlgorithm extends Algorithm {
  @override
  String get name => 'Level Order Traversal';

  @override
  String get description => 'BFS on a tree: visit all nodes at depth d before depth d+1.';

  @override
  AlgorithmCategory get category => AlgorithmCategory.tree;

  @override
  Future<List<AlgorithmState>> generate() async {
    final random = Random();
    final helper = BstHelper();
    final values = <int>{};
    while (values.length < 10) { values.add(random.nextInt(50) + 1); }
    for (final v in values) { helper.root = helper.insert(helper.root, v); }

    final nodes = helper.layoutNodes(helper.root);
    final states = <TreeState>[];
    final order = <int>[];

    states.add(TreeState(
      nodes: Map.of(nodes), rootId: helper.root?.id,
      description: 'Level order (BFS) traversal',
    ));

    if (helper.root == null) return states;

    final queue = Queue<BstNode>();
    queue.add(helper.root!);

    while (queue.isNotEmpty) {
      final node = queue.removeFirst();

      nodes[node.id] = nodes[node.id]!.copyWith(status: TreeNodeStatus.visiting);
      states.add(TreeState(
        nodes: Map.of(nodes), rootId: helper.root?.id,
        description: 'Visit ${node.value}',
      ));
      order.add(node.id);
      nodes[node.id] = nodes[node.id]!.copyWith(status: TreeNodeStatus.highlighted);

      if (node.left != null) { queue.add(node.left!); }
      if (node.right != null) { queue.add(node.right!); }
    }

    for (final id in order) {
      nodes[id] = nodes[id]!.copyWith(status: TreeNodeStatus.found);
    }
    final orderValues = order.map((id) => nodes[id]!.value).toList();
    states.add(TreeState(
      nodes: Map.of(nodes), rootId: helper.root?.id,
      description: 'Order: ${orderValues.join(" → ")}',
    ));

    return states;
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) =>
      TreePainter(state: state as TreeState, brightness: Theme.of(context).brightness);

  @override
  List<LegendItem>? buildLegend(BuildContext context) => treeLegend(context);
}
