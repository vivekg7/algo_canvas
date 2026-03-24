import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';
import 'package:algo_canvas/algorithms/graph/graph_state.dart';
import 'package:algo_canvas/algorithms/graph/graph_painter.dart';
import 'package:algo_canvas/algorithms/graph/graph_generator.dart';

class DfsAlgorithm extends Algorithm {
  int _nodeCount = 12;

  @override
  String get name => 'DFS';

  @override
  String get description =>
      'Depth-First Search explores as far as possible before backtracking. O(V+E).';

  @override
  AlgorithmCategory get category => AlgorithmCategory.graphTraversal;

  @override
  Future<List<AlgorithmState>> generate() async {
    final random = Random();
    final (nodes, edges) = GraphGenerator.generate(
      nodeCount: _nodeCount, random: random);
    final states = <GraphState>[];
    final adj = _buildAdj(nodes.length, edges);

    var currentNodes = List.of(nodes);
    var currentEdges = List.of(edges);
    final visited = <int>{};

    currentNodes[0] = currentNodes[0].copyWith(status: NodeStatus.source);
    states.add(GraphState(
      nodes: List.of(currentNodes),
      edges: List.of(currentEdges),
      description: 'DFS from node 0',
    ));

    void dfs(int node) {
      visited.add(node);
      currentNodes[node] = currentNodes[node].copyWith(status: NodeStatus.visiting);
      states.add(GraphState(
        nodes: List.of(currentNodes),
        edges: List.of(currentEdges),
        description: 'Visiting node $node',
      ));

      for (final neighbor in adj[node]!) {
        currentEdges = _setEdgeStatus(currentEdges, node, neighbor, EdgeStatus.exploring);
        states.add(GraphState(
          nodes: List.of(currentNodes),
          edges: List.of(currentEdges),
          description: 'Exploring edge $node → $neighbor',
        ));

        if (!visited.contains(neighbor)) {
          currentEdges = _setEdgeStatus(currentEdges, node, neighbor, EdgeStatus.inTree);
          dfs(neighbor);
        } else {
          currentEdges = _setEdgeStatus(currentEdges, node, neighbor, EdgeStatus.rejected);
        }
      }

      currentNodes[node] = currentNodes[node].copyWith(status: NodeStatus.visited);
      states.add(GraphState(
        nodes: List.of(currentNodes),
        edges: List.of(currentEdges),
        description: 'Backtrack from node $node',
      ));
    }

    dfs(0);

    states.add(GraphState(
      nodes: List.of(currentNodes),
      edges: List.of(currentEdges),
      description: 'DFS complete — ${visited.length} nodes visited',
    ));

    return states;
  }

  Map<int, List<int>> _buildAdj(int n, List<GraphEdge> edges) {
    final adj = <int, List<int>>{};
    for (var i = 0; i < n; i++) { adj[i] = []; }
    for (final e in edges) {
      if (!adj[e.from]!.contains(e.to)) adj[e.from]!.add(e.to);
    }
    return adj;
  }

  List<GraphEdge> _setEdgeStatus(
      List<GraphEdge> edges, int from, int to, EdgeStatus status) {
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
    return _NodeCountControl(count: _nodeCount, onChanged: (v) { _nodeCount = v; onChanged(); });
  }
}

class _NodeCountControl extends StatefulWidget {
  const _NodeCountControl({required this.count, required this.onChanged});
  final int count;
  final ValueChanged<int> onChanged;
  @override
  State<_NodeCountControl> createState() => _NodeCountControlState();
}

class _NodeCountControlState extends State<_NodeCountControl> {
  late double _value;
  @override
  void initState() { super.initState(); _value = widget.count.toDouble(); }
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text('Nodes: ${_value.round()}', style: Theme.of(context).textTheme.bodySmall),
      Expanded(child: Slider(value: _value, min: 5, max: 25, divisions: 20,
        onChanged: (v) => setState(() => _value = v),
        onChangeEnd: (v) => widget.onChanged(v.round()),
      )),
    ]);
  }
}
