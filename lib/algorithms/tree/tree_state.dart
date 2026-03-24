import 'package:algo_canvas/core/algorithm_state.dart';

enum TreeNodeStatus { normal, highlighted, visiting, found, inserted, deleted }

class TreeNode {
  const TreeNode({
    required this.id,
    required this.value,
    this.x = 0,
    this.y = 0,
    this.left,
    this.right,
    this.status = TreeNodeStatus.normal,
    this.balanceFactor,
  });

  final int id;
  final int value;
  final double x; // normalized 0..1
  final double y; // normalized 0..1
  final int? left; // id of left child
  final int? right; // id of right child
  final TreeNodeStatus status;
  final int? balanceFactor; // for AVL

  TreeNode copyWith({
    double? x,
    double? y,
    int? Function()? left,
    int? Function()? right,
    TreeNodeStatus? status,
    int? Function()? balanceFactor,
  }) {
    return TreeNode(
      id: id,
      value: value,
      x: x ?? this.x,
      y: y ?? this.y,
      left: left != null ? left() : this.left,
      right: right != null ? right() : this.right,
      status: status ?? this.status,
      balanceFactor: balanceFactor != null ? balanceFactor() : this.balanceFactor,
    );
  }
}

class TreeState extends AlgorithmState {
  const TreeState({
    required this.nodes,
    this.rootId,
    this.highlightPath = const [],
    required super.description,
  });

  /// All nodes by their id.
  final Map<int, TreeNode> nodes;
  final int? rootId;

  /// Ids of nodes forming a highlighted path (e.g., search path).
  final List<int> highlightPath;
}
