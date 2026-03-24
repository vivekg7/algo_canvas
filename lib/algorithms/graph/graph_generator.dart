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
    // Initial positions: circular with randomness
    final x = List<double>.generate(nodeCount, (i) {
      final angle = 2 * pi * i / nodeCount;
      return 0.5 + cos(angle) * 0.3 + (random.nextDouble() - 0.5) * 0.1;
    });
    final y = List<double>.generate(nodeCount, (i) {
      final angle = 2 * pi * i / nodeCount;
      return 0.5 + sin(angle) * 0.3 + (random.nextDouble() - 0.5) * 0.1;
    });

    // Build edges first so force-directed layout knows connectivity
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

    // Force-directed layout
    _forceDirectedLayout(x, y, edges, nodeCount);

    // Create nodes from final positions
    final nodes = <GraphNode>[];
    for (var i = 0; i < nodeCount; i++) {
      nodes.add(GraphNode(
        id: i,
        x: x[i].clamp(0.05, 0.95),
        y: y[i].clamp(0.05, 0.95),
      ));
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

  /// Simple force-directed layout: repulsion between all nodes,
  /// attraction along edges, iterated to convergence.
  static void _forceDirectedLayout(
    List<double> x,
    List<double> y,
    List<GraphEdge> edges,
    int n,
  ) {
    const iterations = 150;
    const repulsion = 0.002;
    const attraction = 0.08;
    const damping = 0.9;
    const minDist = 0.01;

    final vx = List<double>.filled(n, 0);
    final vy = List<double>.filled(n, 0);

    // Unique edges for attraction
    final uniqueEdges = <(int, int)>{};
    for (final e in edges) {
      final a = min(e.from, e.to);
      final b = max(e.from, e.to);
      uniqueEdges.add((a, b));
    }

    for (var iter = 0; iter < iterations; iter++) {
      final temp = 1.0 - iter / iterations; // cooling

      // Repulsion: all pairs
      for (var i = 0; i < n; i++) {
        for (var j = i + 1; j < n; j++) {
          var dx = x[i] - x[j];
          var dy = y[i] - y[j];
          var dist = sqrt(dx * dx + dy * dy);
          if (dist < minDist) { dist = minDist; }

          final force = repulsion / (dist * dist);
          final fx = dx / dist * force;
          final fy = dy / dist * force;
          vx[i] += fx;
          vy[i] += fy;
          vx[j] -= fx;
          vy[j] -= fy;
        }
      }

      // Attraction: edges
      for (final (a, b) in uniqueEdges) {
        final dx = x[b] - x[a];
        final dy = y[b] - y[a];
        final dist = sqrt(dx * dx + dy * dy);
        if (dist < minDist) { continue; }

        final force = dist * attraction;
        final fx = dx / dist * force;
        final fy = dy / dist * force;
        vx[a] += fx;
        vy[a] += fy;
        vx[b] -= fx;
        vy[b] -= fy;
      }

      // Center gravity: pull toward (0.5, 0.5)
      for (var i = 0; i < n; i++) {
        vx[i] += (0.5 - x[i]) * 0.01;
        vy[i] += (0.5 - y[i]) * 0.01;
      }

      // Apply velocities with damping and cooling
      for (var i = 0; i < n; i++) {
        vx[i] *= damping;
        vy[i] *= damping;
        x[i] += vx[i] * temp;
        y[i] += vy[i] * temp;
        x[i] = x[i].clamp(0.05, 0.95);
        y[i] = y[i].clamp(0.05, 0.95);
      }
    }
  }
}
