import 'package:algo_canvas/algorithms/tree/tree_state.dart';

/// Simple BST node used during construction.
class BstNode {
  int value;
  int id;
  BstNode? left, right;
  int height; // for AVL
  BstNode(this.value, this.id, {this.height = 1});
}

/// Build and layout a BST for visualization.
class BstHelper {
  int _nextId = 0;
  BstNode? root;

  int get nextId => _nextId++;

  BstNode insert(BstNode? node, int value) {
    if (node == null) return BstNode(value, nextId);
    if (value < node.value) {
      node.left = insert(node.left, value);
    } else if (value > node.value) {
      node.right = insert(node.right, value);
    }
    return node;
  }

  /// Convert BST to TreeState nodes with layout positions.
  Map<int, TreeNode> layoutNodes(BstNode? root) {
    final nodes = <int, TreeNode>{};
    if (root == null) return nodes;

    // Inorder to assign x positions
    final inorder = <BstNode>[];
    void traverse(BstNode? n) {
      if (n == null) return;
      traverse(n.left);
      inorder.add(n);
      traverse(n.right);
    }
    traverse(root);

    // Compute depth for y positions
    final depths = <int, int>{};
    void computeDepth(BstNode? n, int depth) {
      if (n == null) return;
      depths[n.id] = depth;
      computeDepth(n.left, depth + 1);
      computeDepth(n.right, depth + 1);
    }
    computeDepth(root, 0);

    final maxDepth = depths.values.reduce((a, b) => a > b ? a : b);

    for (var i = 0; i < inorder.length; i++) {
      final n = inorder[i];
      final x = inorder.length <= 1 ? 0.5 : i / (inorder.length - 1);
      final y = maxDepth == 0 ? 0.1 : 0.05 + 0.9 * depths[n.id]! / maxDepth;

      nodes[n.id] = TreeNode(
        id: n.id,
        value: n.value,
        x: x,
        y: y,
        left: n.left?.id,
        right: n.right?.id,
        balanceFactor: n.height > 0 ? _bf(n) : null,
      );
    }

    return nodes;
  }

  // AVL helpers
  int _height(BstNode? n) => n?.height ?? 0;
  int _bf(BstNode n) => _height(n.left) - _height(n.right);

  void _updateHeight(BstNode n) {
    n.height = 1 + (_height(n.left) > _height(n.right) ? _height(n.left) : _height(n.right));
  }

  BstNode _rotateRight(BstNode y) {
    final x = y.left!;
    y.left = x.right;
    x.right = y;
    _updateHeight(y);
    _updateHeight(x);
    return x;
  }

  BstNode _rotateLeft(BstNode x) {
    final y = x.right!;
    x.right = y.left;
    y.left = x;
    _updateHeight(x);
    _updateHeight(y);
    return y;
  }

  BstNode insertAVL(BstNode? node, int value) {
    if (node == null) return BstNode(value, nextId);

    if (value < node.value) {
      node.left = insertAVL(node.left, value);
    } else if (value > node.value) {
      node.right = insertAVL(node.right, value);
    } else {
      return node;
    }

    _updateHeight(node);
    final balance = _bf(node);

    // Left-Left
    if (balance > 1 && value < node.left!.value) return _rotateRight(node);
    // Right-Right
    if (balance < -1 && value > node.right!.value) return _rotateLeft(node);
    // Left-Right
    if (balance > 1 && value > node.left!.value) {
      node.left = _rotateLeft(node.left!);
      return _rotateRight(node);
    }
    // Right-Left
    if (balance < -1 && value < node.right!.value) {
      node.right = _rotateRight(node.right!);
      return _rotateLeft(node);
    }

    return node;
  }

  /// Layout AVL nodes with balance factors shown.
  Map<int, TreeNode> layoutAVLNodes(BstNode? root) {
    final nodes = <int, TreeNode>{};
    if (root == null) return nodes;

    final inorder = <BstNode>[];
    void traverse(BstNode? n) {
      if (n == null) return;
      traverse(n.left);
      inorder.add(n);
      traverse(n.right);
    }
    traverse(root);

    final depths = <int, int>{};
    void computeDepth(BstNode? n, int depth) {
      if (n == null) return;
      depths[n.id] = depth;
      computeDepth(n.left, depth + 1);
      computeDepth(n.right, depth + 1);
    }
    computeDepth(root, 0);

    final maxDepth = depths.values.isEmpty ? 0 : depths.values.reduce((a, b) => a > b ? a : b);

    for (var i = 0; i < inorder.length; i++) {
      final n = inorder[i];
      final x = inorder.length <= 1 ? 0.5 : i / (inorder.length - 1);
      final y = maxDepth == 0 ? 0.1 : 0.05 + 0.9 * depths[n.id]! / maxDepth;

      nodes[n.id] = TreeNode(
        id: n.id,
        value: n.value,
        x: x,
        y: y,
        left: n.left?.id,
        right: n.right?.id,
        balanceFactor: _bf(n),
      );
    }

    return nodes;
  }
}
