import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';
import 'package:algo_canvas/algorithms/graph/graph_state.dart';
import 'package:algo_canvas/algorithms/graph/graph_painter.dart';
import 'package:algo_canvas/algorithms/graph/graph_generator.dart';

class KruskalAlgorithm extends Algorithm {
  int _nodeCount = 12;

  @override
  String get name => "Kruskal's MST";

  @override
  String get description =>
      "Builds minimum spanning tree by adding cheapest edges. O(E log E).";

  @override
  AlgorithmCategory get category => AlgorithmCategory.graphTraversal;

  @override
  Future<List<AlgorithmState>> generate() async {
    final random = Random();
    final (nodes, edges) = GraphGenerator.generate(
      nodeCount: _nodeCount, random: random, weighted: true);
    final states = <GraphState>[];
    final n = nodes.length;

    var currentNodes = List.of(nodes);
    var currentEdges = List.of(edges);

    // Get unique edges (undirected: keep one per pair)
    final uniqueEdges = <GraphEdge>[];
    final seen = <String>{};
    for (final e in edges) {
      final key = '${min(e.from, e.to)}-${max(e.from, e.to)}';
      if (!seen.contains(key)) {
        seen.add(key);
        uniqueEdges.add(e);
      }
    }
    uniqueEdges.sort((a, b) => a.weight.compareTo(b.weight));

    states.add(GraphState(
      nodes: List.of(currentNodes), edges: List.of(currentEdges),
      weighted: true, description: "Kruskal's: ${uniqueEdges.length} edges sorted by weight",
    ));

    // Union-Find
    final parent = List.generate(n, (i) => i);
    final rank = List.filled(n, 0);

    int find(int x) {
      if (parent[x] != x) parent[x] = find(parent[x]);
      return parent[x];
    }

    bool union(int x, int y) {
      final px = find(x), py = find(y);
      if (px == py) return false;
      if (rank[px] < rank[py]) { parent[px] = py; }
      else if (rank[px] > rank[py]) { parent[py] = px; }
      else { parent[py] = px; rank[px]++; }
      return true;
    }

    var mstWeight = 0.0;
    var edgesAdded = 0;

    for (final edge in uniqueEdges) {
      currentEdges = _setEdgeStatus(currentEdges, edge.from, edge.to, EdgeStatus.exploring);
      states.add(GraphState(
        nodes: List.of(currentNodes), edges: List.of(currentEdges),
        weighted: true,
        description: 'Considering edge ${edge.from}↔${edge.to} (w=${edge.weight.round()})',
      ));

      if (union(edge.from, edge.to)) {
        currentEdges = _setEdgeStatus(currentEdges, edge.from, edge.to, EdgeStatus.inTree);
        currentNodes[edge.from] = currentNodes[edge.from].copyWith(status: NodeStatus.visited);
        currentNodes[edge.to] = currentNodes[edge.to].copyWith(status: NodeStatus.visited);
        mstWeight += edge.weight;
        edgesAdded++;
        states.add(GraphState(
          nodes: List.of(currentNodes), edges: List.of(currentEdges),
          weighted: true,
          description: 'Added edge ${edge.from}↔${edge.to} to MST (total=${mstWeight.round()})',
        ));
        if (edgesAdded == n - 1) break;
      } else {
        currentEdges = _setEdgeStatus(currentEdges, edge.from, edge.to, EdgeStatus.rejected);
        states.add(GraphState(
          nodes: List.of(currentNodes), edges: List.of(currentEdges),
          weighted: true,
          description: 'Rejected: ${edge.from}↔${edge.to} would create cycle',
        ));
      }
    }

    states.add(GraphState(
      nodes: List.of(currentNodes), edges: List.of(currentEdges),
      weighted: true, description: 'MST complete — total weight: ${mstWeight.round()}',
    ));

    return states;
  }

  List<GraphEdge> _setEdgeStatus(List<GraphEdge> edges, int from, int to, EdgeStatus status) {
    return edges.map((e) {
      if ((e.from == from && e.to == to) || (e.from == to && e.to == from)) {
        return e.copyWith(status: status);
      }
      return e;
    }).toList();
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) {
    return GraphPainter(state: state as GraphState, brightness: Theme.of(context).brightness);
  }

  @override
  Widget? buildControls({required VoidCallback onChanged}) {
    return _Control(count: _nodeCount, onChanged: (v) { _nodeCount = v; onChanged(); });
  }
}

class _Control extends StatefulWidget {
  const _Control({required this.count, required this.onChanged});
  final int count; final ValueChanged<int> onChanged;
  @override State<_Control> createState() => _ControlState();
}
class _ControlState extends State<_Control> {
  late double _v;
  @override void initState() { super.initState(); _v = widget.count.toDouble(); }
  @override Widget build(BuildContext context) => Row(children: [
    Text('Nodes: ${_v.round()}', style: Theme.of(context).textTheme.bodySmall),
    Expanded(child: Slider(value: _v, min: 5, max: 20, divisions: 15,
      onChanged: (v) => setState(() => _v = v), onChangeEnd: (v) => widget.onChanged(v.round()))),
  ]);
}
