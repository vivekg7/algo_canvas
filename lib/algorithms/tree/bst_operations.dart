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

class BstOperationsAlgorithm extends Algorithm {
  @override
  String get name => 'BST Operations';

  @override
  String get description => 'Insert, search, and delete in a Binary Search Tree.';

  @override
  AlgorithmCategory get category => AlgorithmCategory.tree;

  @override
  Future<List<AlgorithmState>> generate() async {
    final random = Random();
    final helper = BstHelper();
    final states = <TreeState>[];
    final values = <int>{};
    while (values.length < 10) { values.add(random.nextInt(50) + 1); }
    final valueList = values.toList()..shuffle(random);

    // Insert phase
    for (var i = 0; i < valueList.length; i++) {
      helper.root = helper.insert(helper.root, valueList[i]);
      final nodes = helper.layoutNodes(helper.root);

      // Highlight the inserted node
      final inserted = nodes.values.firstWhere((n) => n.value == valueList[i]);
      nodes[inserted.id] = inserted.copyWith(status: TreeNodeStatus.inserted);

      states.add(TreeState(
        nodes: Map.of(nodes), rootId: helper.root?.id,
        description: 'Inserted ${valueList[i]}',
      ));

      // Reset status
      nodes[inserted.id] = inserted.copyWith(status: TreeNodeStatus.normal);
    }

    // Search phase
    final searchVal = valueList[random.nextInt(valueList.length)];
    var nodes = helper.layoutNodes(helper.root);
    final path = <int>[];
    BstNode? current = helper.root;

    while (current != null) {
      path.add(current.id);
      final n = nodes[current.id]!;
      nodes[current.id] = n.copyWith(status: TreeNodeStatus.visiting);
      states.add(TreeState(
        nodes: Map.of(nodes), rootId: helper.root?.id, highlightPath: List.of(path),
        description: 'Searching for $searchVal: visiting ${current.value}',
      ));
      nodes[current.id] = n.copyWith(status: TreeNodeStatus.highlighted);

      if (searchVal == current.value) {
        nodes[current.id] = n.copyWith(status: TreeNodeStatus.found);
        states.add(TreeState(
          nodes: Map.of(nodes), rootId: helper.root?.id, highlightPath: List.of(path),
          description: 'Found $searchVal!',
        ));
        break;
      } else if (searchVal < current.value) {
        current = current.left != null ? _findNode(helper.root!, current.left!.id) : null;
      } else {
        current = current.right != null ? _findNode(helper.root!, current.right!.id) : null;
      }
    }

    return states;
  }

  BstNode? _findNode(BstNode root, int id) {
    if (root.id == id) return root;
    final left = root.left != null ? _findNode(root.left!, id) : null;
    if (left != null) return left;
    return root.right != null ? _findNode(root.right!, id) : null;
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) =>
      TreePainter(state: state as TreeState, brightness: Theme.of(context).brightness);

  @override
  List<LegendItem>? buildLegend(BuildContext context) => treeLegend(context);
}
