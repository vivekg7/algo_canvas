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

class _TraversalAlgorithm extends Algorithm {
  _TraversalAlgorithm(this._name, this._desc, this._traverseFunc);

  final String _name;
  final String _desc;
  final void Function(BstNode?, List<TreeState>, Map<int, TreeNode>, int?, List<int>) _traverseFunc;

  @override
  String get name => _name;
  @override
  String get description => _desc;
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
      description: '$_name traversal',
    ));

    _traverseFunc(helper.root, states, nodes, helper.root?.id, order);

    // Final: highlight order
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

void _inorder(BstNode? node, List<TreeState> states, Map<int, TreeNode> nodes, int? rootId, List<int> order) {
  if (node == null) return;
  _inorder(node.left, states, nodes, rootId, order);

  nodes[node.id] = nodes[node.id]!.copyWith(status: TreeNodeStatus.visiting);
  states.add(TreeState(nodes: Map.of(nodes), rootId: rootId, description: 'Visit ${node.value}'));
  order.add(node.id);
  nodes[node.id] = nodes[node.id]!.copyWith(status: TreeNodeStatus.highlighted);

  _inorder(node.right, states, nodes, rootId, order);
}

void _preorder(BstNode? node, List<TreeState> states, Map<int, TreeNode> nodes, int? rootId, List<int> order) {
  if (node == null) return;

  nodes[node.id] = nodes[node.id]!.copyWith(status: TreeNodeStatus.visiting);
  states.add(TreeState(nodes: Map.of(nodes), rootId: rootId, description: 'Visit ${node.value}'));
  order.add(node.id);
  nodes[node.id] = nodes[node.id]!.copyWith(status: TreeNodeStatus.highlighted);

  _preorder(node.left, states, nodes, rootId, order);
  _preorder(node.right, states, nodes, rootId, order);
}

void _postorder(BstNode? node, List<TreeState> states, Map<int, TreeNode> nodes, int? rootId, List<int> order) {
  if (node == null) return;
  _postorder(node.left, states, nodes, rootId, order);
  _postorder(node.right, states, nodes, rootId, order);

  nodes[node.id] = nodes[node.id]!.copyWith(status: TreeNodeStatus.visiting);
  states.add(TreeState(nodes: Map.of(nodes), rootId: rootId, description: 'Visit ${node.value}'));
  order.add(node.id);
  nodes[node.id] = nodes[node.id]!.copyWith(status: TreeNodeStatus.highlighted);
}

class InorderTraversalAlgorithm extends _TraversalAlgorithm {
  InorderTraversalAlgorithm() : super(
    'Inorder Traversal', 'Left → Root → Right. Produces sorted output for BST.', _inorder);
}

class PreorderTraversalAlgorithm extends _TraversalAlgorithm {
  PreorderTraversalAlgorithm() : super(
    'Preorder Traversal', 'Root → Left → Right. Useful for copying/serializing a tree.', _preorder);
}

class PostorderTraversalAlgorithm extends _TraversalAlgorithm {
  PostorderTraversalAlgorithm() : super(
    'Postorder Traversal', 'Left → Right → Root. Useful for deleting a tree.', _postorder);
}
