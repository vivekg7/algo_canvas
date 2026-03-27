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

class AStarAlgorithm extends Algorithm {
  int _nodeCount = 12;

  @override
  String get name => 'A* Search';

  @override
  String get description =>
      'Shortest path using heuristic (Euclidean distance) to guide search. O(E log V).';

  @override
  AlgorithmCategory get category => AlgorithmCategory.graphTraversal;

  @override
  Future<List<AlgorithmState>> generate() async {
    final random = Random();
    final (nodes, edges) = GraphGenerator.generate(
      nodeCount: _nodeCount, random: random, weighted: true);
    final states = <GraphState>[];
    final n = nodes.length;
    final target = n - 1;
    final adj = <int, List<(int, double)>>{};
    for (var i = 0; i < n; i++) {
      adj[i] = [];
    }
    for (final e in edges) {
      adj[e.from]!.add((e.to, e.weight));
    }

    var currentNodes = List.of(nodes);
    var currentEdges = List.of(edges);

    double heuristic(int a, int b) {
      final dx = nodes[a].x - nodes[b].x;
      final dy = nodes[a].y - nodes[b].y;
      return sqrt(dx * dx + dy * dy) * 10; // Scale to match edge weights
    }

    final gScore = List<double>.filled(n, double.infinity);
    final fScore = List<double>.filled(n, double.infinity);
    final openSet = <int>{0};
    final closedSet = <int>{};

    gScore[0] = 0;
    fScore[0] = heuristic(0, target);

    currentNodes[0] = currentNodes[0].copyWith(status: NodeStatus.source, distance: 0);
    currentNodes[target] = currentNodes[target].copyWith(status: NodeStatus.target);
    states.add(GraphState(
      nodes: List.of(currentNodes), edges: List.of(currentEdges),
      weighted: true, description: 'A* from node 0 to node $target',
    ));

    while (openSet.isNotEmpty) {
      // Find node in openSet with lowest fScore
      var current = openSet.first;
      for (final node in openSet) {
        if (fScore[node] < fScore[current]) current = node;
      }

      if (current == target) {
        currentNodes[current] = currentNodes[current].copyWith(status: NodeStatus.target);
        states.add(GraphState(
          nodes: List.of(currentNodes), edges: List.of(currentEdges),
          weighted: true,
          description: 'Target reached! Shortest distance: ${gScore[target].round()}',
        ));
        return states;
      }

      openSet.remove(current);
      closedSet.add(current);

      currentNodes[current] = currentNodes[current].copyWith(
        status: current == 0 ? NodeStatus.source : NodeStatus.visiting,
        distance: gScore[current],
      );
      states.add(GraphState(
        nodes: List.of(currentNodes), edges: List.of(currentEdges),
        weighted: true,
        description: 'Visiting node $current (f=${fScore[current].round()}, g=${gScore[current].round()})',
      ));

      for (final (neighbor, weight) in adj[current]!) {
        if (closedSet.contains(neighbor)) continue;

        currentEdges = _setEdgeStatus(currentEdges, current, neighbor, EdgeStatus.exploring);

        final tentativeG = gScore[current] + weight;
        if (tentativeG < gScore[neighbor]) {
          gScore[neighbor] = tentativeG;
          fScore[neighbor] = tentativeG + heuristic(neighbor, target);
          openSet.add(neighbor);

          currentNodes[neighbor] = currentNodes[neighbor].copyWith(
            status: neighbor == target ? NodeStatus.target : NodeStatus.queued,
            distance: tentativeG,
          );
          currentEdges = _setEdgeStatus(currentEdges, current, neighbor, EdgeStatus.inTree);
          states.add(GraphState(
            nodes: List.of(currentNodes), edges: List.of(currentEdges),
            weighted: true,
            description: 'Updated $neighbor: g=${tentativeG.round()}, f=${fScore[neighbor].round()}',
          ));
        } else {
          currentEdges = _setEdgeStatus(currentEdges, current, neighbor, EdgeStatus.rejected);
        }
      }

      if (current != 0) {
        currentNodes[current] = currentNodes[current].copyWith(status: NodeStatus.visited);
      }
    }

    states.add(GraphState(
      nodes: List.of(currentNodes), edges: List.of(currentEdges),
      weighted: true, description: 'No path found to target!',
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
