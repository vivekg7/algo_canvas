import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';
import 'package:algo_canvas/algorithms/graph/graph_state.dart';
import 'package:algo_canvas/algorithms/graph/graph_painter.dart';
import 'package:algo_canvas/algorithms/graph/graph_legend.dart';
import 'package:algo_canvas/widgets/color_legend.dart';
import 'package:algo_canvas/algorithms/graph/graph_generator.dart';

class TopologicalSortAlgorithm extends Algorithm {
  int _nodeCount = 10;

  @override
  String get name => 'Topological Sort';

  @override
  String get description =>
      'Linear ordering of DAG vertices such that every edge u→v has u before v. O(V+E).';

  @override
  AlgorithmCategory get category => AlgorithmCategory.graphTraversal;

  @override
  Future<List<AlgorithmState>> generate() async {
    final random = Random();
    final (nodes, edges) = GraphGenerator.generateDAG(
      nodeCount: _nodeCount, random: random);
    final states = <GraphState>[];
    final n = nodes.length;
    final adj = <int, List<int>>{};
    for (var i = 0; i < n; i++) { adj[i] = []; }
    for (final e in edges) {
      adj[e.from]!.add(e.to);
    }

    var currentNodes = List.of(nodes);
    var currentEdges = List.of(edges);
    final visited = <int>{};
    final order = <int>[];

    states.add(GraphState(
      nodes: List.of(currentNodes), edges: List.of(currentEdges),
      directed: true, description: 'Topological sort on DAG with $n nodes',
    ));

    void dfs(int u) {
      visited.add(u);
      currentNodes[u] = currentNodes[u].copyWith(status: NodeStatus.visiting);
      states.add(GraphState(
        nodes: List.of(currentNodes), edges: List.of(currentEdges),
        directed: true, description: 'DFS visiting node $u',
      ));

      for (final v in adj[u]!) {
        currentEdges = _setEdgeStatus(currentEdges, u, v, EdgeStatus.exploring);
        if (!visited.contains(v)) {
          currentEdges = _setEdgeStatus(currentEdges, u, v, EdgeStatus.inTree);
          dfs(v);
        } else {
          currentEdges = _setEdgeStatus(currentEdges, u, v, EdgeStatus.rejected);
        }
      }

      order.insert(0, u);
      currentNodes[u] = currentNodes[u].copyWith(
        status: NodeStatus.visited,
        label: '${order.length}',
      );
      states.add(GraphState(
        nodes: List.of(currentNodes), edges: List.of(currentEdges),
        directed: true, description: 'Node $u finished — order position ${order.length}',
      ));
    }

    for (var i = 0; i < n; i++) {
      if (!visited.contains(i)) dfs(i);
    }

    states.add(GraphState(
      nodes: List.of(currentNodes), edges: List.of(currentEdges),
      directed: true,
      description: 'Topological order: ${order.join(" → ")}',
    ));

    return states;
  }

  List<GraphEdge> _setEdgeStatus(List<GraphEdge> edges, int from, int to, EdgeStatus status) {
    return edges.map((e) {
      if (e.from == from && e.to == to) return e.copyWith(status: status);
      return e;
    }).toList();
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) {
    return GraphPainter(state: state as GraphState, colorScheme: Theme.of(context).colorScheme);
  }

  @override
  List<LegendItem>? buildLegend(BuildContext context) => graphLegend(context);

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
    Expanded(child: Slider(value: _v, min: 5, max: 15, divisions: 10,
      onChanged: (v) => setState(() => _v = v), onChangeEnd: (v) => widget.onChanged(v.round()))),
  ]);
}
