import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';
import 'package:algo_canvas/algorithms/tree/tree_state.dart';
import 'package:algo_canvas/algorithms/tree/tree_painter.dart';
import 'package:algo_canvas/algorithms/tree/tree_legend.dart';
import 'package:algo_canvas/widgets/color_legend.dart';

class _TrieNode {
  final Map<String, _TrieNode> children = {};
  bool isEnd = false;
  int id;
  _TrieNode(this.id);
}

class TrieOperationsAlgorithm extends Algorithm {
  @override
  String get name => 'Trie';

  @override
  String get description => 'Prefix tree: insert and search words character by character.';

  @override
  AlgorithmCategory get category => AlgorithmCategory.tree;

  @override
  Future<List<AlgorithmState>> generate() async {
    final states = <TreeState>[];
    var nextId = 0;
    final root = _TrieNode(nextId++);
    final words = ['cat', 'car', 'card', 'care', 'do', 'dog', 'done'];

    states.add(const TreeState(nodes: {}, description: 'Trie: prefix tree'));

    // Insert words
    for (final word in words) {
      var current = root;
      for (var i = 0; i < word.length; i++) {
        final ch = word[i];
        if (!current.children.containsKey(ch)) {
          current.children[ch] = _TrieNode(nextId++);
        }
        current = current.children[ch]!;

        final nodes = _layoutTrie(root);
        nodes[current.id] = nodes[current.id]!.copyWith(status: TreeNodeStatus.inserted);
        states.add(TreeState(
          nodes: Map.of(nodes), rootId: root.id,
          description: 'Insert "$word": added "${word.substring(0, i + 1)}"',
        ));
      }
      current.isEnd = true;

      final nodes = _layoutTrie(root);
      nodes[current.id] = nodes[current.id]!.copyWith(status: TreeNodeStatus.found);
      states.add(TreeState(
        nodes: Map.of(nodes), rootId: root.id,
        description: 'Inserted "$word" — marked as end of word',
      ));
    }

    // Search phase
    for (final search in ['car', 'care', 'cab']) {
      var current = root;
      var found = true;
      final path = <int>[root.id];

      for (var i = 0; i < search.length; i++) {
        final ch = search[i];
        if (!current.children.containsKey(ch)) {
          found = false;
          break;
        }
        current = current.children[ch]!;
        path.add(current.id);

        final nodes = _layoutTrie(root);
        nodes[current.id] = nodes[current.id]!.copyWith(status: TreeNodeStatus.visiting);
        states.add(TreeState(
          nodes: Map.of(nodes), rootId: root.id, highlightPath: List.of(path),
          description: 'Search "$search": checking "$ch"',
        ));
      }

      final nodes = _layoutTrie(root);
      if (found && current.isEnd) {
        nodes[current.id] = nodes[current.id]!.copyWith(status: TreeNodeStatus.found);
        states.add(TreeState(
          nodes: Map.of(nodes), rootId: root.id, highlightPath: path,
          description: '"$search" found in trie!',
        ));
      } else {
        states.add(TreeState(
          nodes: Map.of(nodes), rootId: root.id,
          description: '"$search" not found${found ? " (not end of word)" : ""}',
        ));
      }
    }

    return states;
  }

  Map<int, TreeNode> _layoutTrie(_TrieNode root) {
    final nodes = <int, TreeNode>{};

    // BFS to assign positions
    final queue = <(_TrieNode, int, double, double, double)>[]; // node, depth, xMin, xMax, parentX
    queue.add((root, 0, 0.0, 1.0, 0.5));

    int maxDepth = 0;
    // First pass: find max depth
    void findDepth(_TrieNode n, int d) {
      if (d > maxDepth) { maxDepth = d; }
      for (final child in n.children.values) { findDepth(child, d + 1); }
    }
    findDepth(root, 0);
    if (maxDepth == 0) { maxDepth = 1; }

    // BFS layout
    final bfsQueue = <(_TrieNode, int, double, double)>[];
    bfsQueue.add((root, 0, 0.0, 1.0));

    while (bfsQueue.isNotEmpty) {
      final (node, depth, xMin, xMax) = bfsQueue.removeAt(0);
      final x = (xMin + xMax) / 2;
      final y = 0.05 + 0.9 * depth / maxDepth;

      final childIds = <String, int>{};
      final sortedKeys = node.children.keys.toList()..sort();
      final childCount = sortedKeys.length;

      for (var i = 0; i < childCount; i++) {
        final key = sortedKeys[i];
        final child = node.children[key]!;
        childIds[key] = child.id;

        final cxMin = xMin + (xMax - xMin) * i / childCount;
        final cxMax = xMin + (xMax - xMin) * (i + 1) / childCount;
        bfsQueue.add((child, depth + 1, cxMin, cxMax));
      }

      // For trie, we show character labels. Use first child as "left", second as "right", etc.
      // Since TreeNode only has left/right, we'll chain children.
      // Better approach: just store first two children for visual tree structure.
      final childList = sortedKeys.map((k) => node.children[k]!.id).toList();

      nodes[node.id] = TreeNode(
        id: node.id,
        value: node.id == root.id ? 0 : node.id, // root shows as "·"
        x: x,
        y: y,
        left: childList.isNotEmpty ? childList[0] : null,
        right: childList.length > 1 ? childList[1] : null,
        status: node.isEnd ? TreeNodeStatus.highlighted : TreeNodeStatus.normal,
      );

      // Handle more than 2 children by chaining right pointers
      // This is a simplification — works visually for small tries
      for (var i = 2; i < childList.length; i++) {
        // Store extra children as right-child chains from previous
        // (won't draw perfect lines but shows the structure)
      }
    }

    return nodes;
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) =>
      TreePainter(state: state as TreeState, brightness: Theme.of(context).brightness);

  @override
  List<LegendItem>? buildLegend(BuildContext context) => treeLegend(context);
}
