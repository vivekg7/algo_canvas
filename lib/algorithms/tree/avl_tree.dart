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

class AvlTreeAlgorithm extends Algorithm {
  @override
  String get name => 'AVL Tree';

  @override
  String get description => 'Self-balancing BST with rotations to maintain O(log n) height.';

  @override
  AlgorithmCategory get category => AlgorithmCategory.tree;

  @override
  Future<List<AlgorithmState>> generate() async {
    final random = Random();
    final helper = BstHelper();
    final states = <TreeState>[];
    final values = <int>{};
    while (values.length < 12) { values.add(random.nextInt(50) + 1); }

    states.add(const TreeState(
      nodes: {}, description: 'AVL Tree: self-balancing insertions'));

    for (final value in values) {
      helper.root = helper.insertAVL(helper.root, value);
      final nodes = helper.layoutAVLNodes(helper.root);

      final inserted = nodes.values.firstWhere((n) => n.value == value);
      nodes[inserted.id] = inserted.copyWith(status: TreeNodeStatus.inserted);

      states.add(TreeState(
        nodes: Map.of(nodes), rootId: helper.root?.id,
        description: 'Inserted $value (balanced)',
      ));

      nodes[inserted.id] = inserted.copyWith(status: TreeNodeStatus.normal);
    }

    states.add(TreeState(
      nodes: helper.layoutAVLNodes(helper.root), rootId: helper.root?.id,
      description: 'AVL tree complete — all balance factors shown',
    ));

    return states;
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) =>
      TreePainter(state: state as TreeState, brightness: Theme.of(context).brightness);

  @override
  List<LegendItem>? buildLegend(BuildContext context) => treeLegend(context);
}
