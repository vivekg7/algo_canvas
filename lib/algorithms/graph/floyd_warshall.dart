import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';
import 'package:algo_canvas/algorithms/graph/graph_state.dart';
import 'package:algo_canvas/algorithms/graph/graph_painter.dart';
import 'package:algo_canvas/algorithms/graph/graph_generator.dart';

class FloydWarshallAlgorithm extends Algorithm {
  int _nodeCount = 7;

  @override
  String get name => 'Floyd-Warshall';

  @override
  String get description =>
      'All-pairs shortest paths using dynamic programming. O(V³).';

  @override
  AlgorithmCategory get category => AlgorithmCategory.graphTraversal;

  @override
  Future<List<AlgorithmState>> generate() async {
    final random = Random();
    final (nodes, edges) = GraphGenerator.generate(
      nodeCount: _nodeCount, random: random, weighted: true);
    final states = <GraphState>[];
    final n = nodes.length;

    // Build adjacency matrix
    final dist = List.generate(
      n, (_) => List<double>.filled(n, double.infinity));
    for (var i = 0; i < n; i++) { dist[i][i] = 0; }
    for (final e in edges) {
      dist[e.from][e.to] = min(dist[e.from][e.to], e.weight);
    }

    var currentNodes = List.of(nodes);
    var currentEdges = List.of(edges);

    states.add(GraphState(
      nodes: List.of(currentNodes), edges: List.of(currentEdges),
      weighted: true, description: 'Floyd-Warshall: all-pairs shortest paths',
    ));

    for (var k = 0; k < n; k++) {
      currentNodes[k] = currentNodes[k].copyWith(status: NodeStatus.visiting);
      states.add(GraphState(
        nodes: List.of(currentNodes), edges: List.of(currentEdges),
        weighted: true, description: 'Intermediate vertex: $k',
      ));

      for (var i = 0; i < n; i++) {
        for (var j = 0; j < n; j++) {
          if (dist[i][k] + dist[k][j] < dist[i][j]) {
            dist[i][j] = dist[i][k] + dist[k][j];

            // Highlight the relaxed path
            if (i != j) {
              currentEdges = _setEdgeStatus(currentEdges, i, j, EdgeStatus.inTree);
              states.add(GraphState(
                nodes: List.of(currentNodes), edges: List.of(currentEdges),
                weighted: true,
                description: 'Relaxed: dist[$i][$j] = ${dist[i][j].round()} via $k',
              ));
              currentEdges = _setEdgeStatus(currentEdges, i, j, EdgeStatus.none);
            }
          }
        }
      }

      currentNodes[k] = currentNodes[k].copyWith(status: NodeStatus.visited);
    }

    // Final: show all distances from node 0
    for (var i = 0; i < n; i++) {
      currentNodes[i] = currentNodes[i].copyWith(
        status: NodeStatus.visited,
        distance: dist[0][i],
      );
    }
    currentNodes[0] = currentNodes[0].copyWith(status: NodeStatus.source);

    states.add(GraphState(
      nodes: List.of(currentNodes), edges: List.of(currentEdges),
      weighted: true, description: 'Floyd-Warshall complete — showing distances from node 0',
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
    Expanded(child: Slider(value: _v, min: 4, max: 10, divisions: 6,
      onChanged: (v) => setState(() => _v = v), onChangeEnd: (v) => widget.onChanged(v.round()))),
  ]);
}
