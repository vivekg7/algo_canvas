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

class DijkstraAlgorithm extends Algorithm {
  int _nodeCount = 12;

  @override
  String get name => "Dijkstra's";

  @override
  String get description =>
      'Finds shortest paths from source using a priority queue. O((V+E) log V).';

  @override
  AlgorithmCategory get category => AlgorithmCategory.graphTraversal;

  @override
  Future<List<AlgorithmState>> generate() async {
    final random = Random();
    final (nodes, edges) = GraphGenerator.generate(
      nodeCount: _nodeCount, random: random, weighted: true);
    final states = <GraphState>[];
    final n = nodes.length;
    final adj = <int, List<(int, double)>>{};
    for (var i = 0; i < n; i++) { adj[i] = []; }
    for (final e in edges) {
      adj[e.from]!.add((e.to, e.weight));
    }

    var currentNodes = List.of(nodes);
    var currentEdges = List.of(edges);
    final dist = List<double>.filled(n, double.infinity);
    final visited = <bool>[...List.filled(n, false)];

    dist[0] = 0;
    currentNodes[0] = currentNodes[0].copyWith(status: NodeStatus.source, distance: 0);
    states.add(GraphState(
      nodes: List.of(currentNodes), edges: List.of(currentEdges),
      weighted: true, description: "Dijkstra's from node 0",
    ));

    for (var i = 0; i < n; i++) {
      // Find unvisited node with smallest distance
      var u = -1;
      var minDist = double.infinity;
      for (var v = 0; v < n; v++) {
        if (!visited[v] && dist[v] < minDist) {
          minDist = dist[v];
          u = v;
        }
      }
      if (u == -1) break;

      visited[u] = true;
      currentNodes[u] = currentNodes[u].copyWith(status: NodeStatus.visiting, distance: dist[u]);
      states.add(GraphState(
        nodes: List.of(currentNodes), edges: List.of(currentEdges),
        weighted: true, description: 'Visiting node $u (dist=${dist[u].round()})',
      ));

      for (final (v, w) in adj[u]!) {
        currentEdges = _setEdgeStatus(currentEdges, u, v, EdgeStatus.exploring);
        states.add(GraphState(
          nodes: List.of(currentNodes), edges: List.of(currentEdges),
          weighted: true, description: 'Relaxing edge $u → $v (w=$w)',
        ));

        if (dist[u] + w < dist[v]) {
          dist[v] = dist[u] + w;
          currentNodes[v] = currentNodes[v].copyWith(
            status: visited[v] ? NodeStatus.visited : NodeStatus.queued,
            distance: dist[v],
          );
          currentEdges = _setEdgeStatus(currentEdges, u, v, EdgeStatus.inTree);
          states.add(GraphState(
            nodes: List.of(currentNodes), edges: List.of(currentEdges),
            weighted: true,
            description: 'Updated dist[$v] = ${dist[v].round()}',
          ));
        } else {
          currentEdges = _setEdgeStatus(currentEdges, u, v, EdgeStatus.rejected);
        }
      }

      currentNodes[u] = currentNodes[u].copyWith(status: NodeStatus.visited);
    }

    states.add(GraphState(
      nodes: List.of(currentNodes), edges: List.of(currentEdges),
      weighted: true, description: "Dijkstra's complete",
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
    Expanded(child: Slider(value: _v, min: 5, max: 20, divisions: 15,
      onChanged: (v) => setState(() => _v = v), onChangeEnd: (v) => widget.onChanged(v.round()))),
  ]);
}
