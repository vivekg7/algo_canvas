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

class BellmanFordAlgorithm extends Algorithm {
  int _nodeCount = 10;

  @override
  String get name => 'Bellman-Ford';

  @override
  String get description =>
      'Shortest paths by relaxing all edges V-1 times. Handles negative weights. O(VE).';

  @override
  AlgorithmCategory get category => AlgorithmCategory.graphTraversal;

  @override
  Future<List<AlgorithmState>> generate() async {
    final random = Random();
    final (nodes, edges) = GraphGenerator.generate(
      nodeCount: _nodeCount, random: random, weighted: true, directed: true);
    final states = <GraphState>[];
    final n = nodes.length;

    var currentNodes = List.of(nodes);
    var currentEdges = List.of(edges);
    final dist = List<double>.filled(n, double.infinity);

    dist[0] = 0;
    currentNodes[0] = currentNodes[0].copyWith(status: NodeStatus.source, distance: 0);
    states.add(GraphState(
      nodes: List.of(currentNodes), edges: List.of(currentEdges),
      weighted: true, directed: true, description: 'Bellman-Ford from node 0',
    ));

    for (var i = 0; i < n - 1; i++) {
      var relaxed = false;

      states.add(GraphState(
        nodes: List.of(currentNodes), edges: List.of(currentEdges),
        weighted: true, directed: true, description: 'Pass ${i + 1} of ${n - 1}',
      ));

      for (final e in edges) {
        if (dist[e.from] == double.infinity) continue;

        currentEdges = _setEdgeStatus(currentEdges, e.from, e.to, EdgeStatus.exploring);

        if (dist[e.from] + e.weight < dist[e.to]) {
          dist[e.to] = dist[e.from] + e.weight;
          relaxed = true;
          currentNodes[e.to] = currentNodes[e.to].copyWith(
            status: NodeStatus.queued, distance: dist[e.to]);
          currentEdges = _setEdgeStatus(currentEdges, e.from, e.to, EdgeStatus.inTree);
          states.add(GraphState(
            nodes: List.of(currentNodes), edges: List.of(currentEdges),
            weighted: true, directed: true,
            description: 'Relaxed ${e.from}→${e.to}: dist[${e.to}]=${dist[e.to].round()}',
          ));
        } else {
          currentEdges = _setEdgeStatus(currentEdges, e.from, e.to, EdgeStatus.none);
        }
      }

      // Mark all with known distances as visited
      for (var v = 0; v < n; v++) {
        if (dist[v] < double.infinity && currentNodes[v].status != NodeStatus.source) {
          currentNodes[v] = currentNodes[v].copyWith(status: NodeStatus.visited, distance: dist[v]);
        }
      }

      if (!relaxed) {
        states.add(GraphState(
          nodes: List.of(currentNodes), edges: List.of(currentEdges),
          weighted: true, directed: true, description: 'No relaxation in pass ${i + 1} — done early',
        ));
        break;
      }
    }

    states.add(GraphState(
      nodes: List.of(currentNodes), edges: List.of(currentEdges),
      weighted: true, directed: true, description: 'Bellman-Ford complete',
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
