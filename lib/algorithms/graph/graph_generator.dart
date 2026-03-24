import 'dart:math';
import 'package:algo_canvas/algorithms/graph/graph_state.dart';

class GraphGenerator {
  GraphGenerator._();

  /// Generate a random connected graph with decent spatial layout.
  static (List<GraphNode>, List<GraphEdge>) generate({
    required int nodeCount,
    required Random random,
    bool weighted = false,
    bool directed = false,
    double edgeDensity = 0.3,
  }) {
    // Generate node positions using Poisson-like distribution
    final nodes = <GraphNode>[];
    for (var i = 0; i < nodeCount; i++) {
      // Arrange in a rough circle with some randomness
      final angle = 2 * pi * i / nodeCount;
      final radius = 0.3 + random.nextDouble() * 0.1;
      final x = 0.5 + cos(angle) * radius + (random.nextDouble() - 0.5) * 0.1;
      final y = 0.5 + sin(angle) * radius + (random.nextDouble() - 0.5) * 0.1;
      nodes.add(GraphNode(
        id: i,
        x: x.clamp(0.05, 0.95),
        y: y.clamp(0.05, 0.95),
      ));
    }

    final edges = <GraphEdge>[];
    final connected = <int>{0};
    final remaining = List.generate(nodeCount - 1, (i) => i + 1)
      ..shuffle(random);

    // Ensure connectivity: spanning tree first
    for (final node in remaining) {
      final target = connected.elementAt(random.nextInt(connected.length));
      final w = weighted ? (random.nextInt(9) + 1).toDouble() : 1.0;
      edges.add(GraphEdge(
        from: node,
        to: target,
        weight: w,
        directed: directed,
      ));
      if (!directed) {
        edges.add(GraphEdge(
          from: target,
          to: node,
          weight: w,
          directed: directed,
        ));
      }
      connected.add(node);
    }

    // Add extra edges based on density
    final existingEdges = <String>{};
    for (final e in edges) {
      existingEdges.add('${e.from}-${e.to}');
    }

    final maxExtraEdges =
        (nodeCount * (nodeCount - 1) * edgeDensity / 2).round();
    var added = 0;
    for (var i = 0; i < nodeCount && added < maxExtraEdges; i++) {
      for (var j = i + 1; j < nodeCount && added < maxExtraEdges; j++) {
        if (existingEdges.contains('$i-$j')) continue;
        if (random.nextDouble() > edgeDensity) continue;

        final w = weighted ? (random.nextInt(9) + 1).toDouble() : 1.0;
        edges.add(GraphEdge(from: i, to: j, weight: w, directed: directed));
        existingEdges.add('$i-$j');
        if (!directed) {
          edges.add(GraphEdge(from: j, to: i, weight: w, directed: directed));
          existingEdges.add('$j-$i');
        }
        added++;
      }
    }

    return (nodes, edges);
  }

  /// Generate a DAG (Directed Acyclic Graph) for topological sort.
  static (List<GraphNode>, List<GraphEdge>) generateDAG({
    required int nodeCount,
    required Random random,
    double edgeDensity = 0.3,
  }) {
    final nodes = <GraphNode>[];
    // Layer-based layout for DAG
    final layers = (sqrt(nodeCount)).ceil();
    final nodesPerLayer = (nodeCount / layers).ceil();

    var id = 0;
    for (var layer = 0; layer < layers && id < nodeCount; layer++) {
      final count = min(nodesPerLayer, nodeCount - id);
      for (var j = 0; j < count; j++) {
        final x = (layer + 0.5) / layers;
        final y = count == 1
            ? 0.5
            : 0.1 + 0.8 * j / (count - 1);
        nodes.add(GraphNode(
          id: id,
          x: x + (random.nextDouble() - 0.5) * 0.05,
          y: y + (random.nextDouble() - 0.5) * 0.05,
        ));
        id++;
      }
    }

    final edges = <GraphEdge>[];
    // Edges only go from lower id to higher id (ensures DAG)
    for (var i = 0; i < nodeCount; i++) {
      for (var j = i + 1; j < nodeCount; j++) {
        if (random.nextDouble() < edgeDensity) {
          edges.add(GraphEdge(from: i, to: j, directed: true));
        }
      }
    }

    // Ensure all nodes are reachable from node 0
    final reachable = <int>{0};
    var changed = true;
    while (changed) {
      changed = false;
      for (final e in edges) {
        if (reachable.contains(e.from) && !reachable.contains(e.to)) {
          reachable.add(e.to);
          changed = true;
        }
      }
    }
    // Add edges to unreachable nodes
    for (var i = 0; i < nodeCount; i++) {
      if (!reachable.contains(i)) {
        final source = reachable.elementAt(random.nextInt(reachable.length));
        final from = min(source, i);
        final to = max(source, i);
        edges.add(GraphEdge(from: from, to: to, directed: true));
        reachable.add(i);
      }
    }

    return (nodes, edges);
  }
}
