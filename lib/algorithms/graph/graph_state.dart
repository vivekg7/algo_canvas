import 'package:algo_canvas/core/algorithm_state.dart';

enum NodeStatus { unvisited, queued, visiting, visited, source, target }

enum EdgeStatus { none, exploring, inTree, rejected }

class GraphNode {
  const GraphNode({
    required this.id,
    required this.x,
    required this.y,
    this.label,
    this.status = NodeStatus.unvisited,
    this.distance,
  });

  final int id;
  final double x; // normalized 0..1
  final double y; // normalized 0..1
  final String? label;
  final NodeStatus status;
  final double? distance;

  GraphNode copyWith({
    NodeStatus? status,
    String? label,
    double? distance,
  }) {
    return GraphNode(
      id: id,
      x: x,
      y: y,
      label: label ?? this.label,
      status: status ?? this.status,
      distance: distance ?? this.distance,
    );
  }
}

class GraphEdge {
  const GraphEdge({
    required this.from,
    required this.to,
    this.weight = 1,
    this.status = EdgeStatus.none,
    this.directed = false,
  });

  final int from;
  final int to;
  final double weight;
  final EdgeStatus status;
  final bool directed;

  GraphEdge copyWith({EdgeStatus? status}) {
    return GraphEdge(
      from: from,
      to: to,
      weight: weight,
      status: status ?? this.status,
      directed: directed,
    );
  }
}

class GraphState extends AlgorithmState {
  const GraphState({
    required this.nodes,
    required this.edges,
    this.weighted = false,
    this.directed = false,
    required super.description,
  });

  final List<GraphNode> nodes;
  final List<GraphEdge> edges;
  final bool weighted;
  final bool directed;
}
