import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';

class _HNode {
  final String? ch;
  final int freq;
  _HNode? left, right;
  _HNode(this.ch, this.freq, {this.left, this.right});
}

class HuffmanState extends AlgorithmState {
  const HuffmanState({
    required this.input,
    required this.freqTable,
    required this.codes,
    this.encoded,
    this.treeNodes = const [],
    this.treeEdges = const [],
    this.highlightChar,
    required super.description,
  });

  final String input;
  final Map<String, int> freqTable;
  final Map<String, String> codes;
  final String? encoded;

  /// Tree layout: (x, y, label, isLeaf)
  final List<(double, double, String, bool)> treeNodes;
  /// Tree edges: (fromIdx, toIdx)
  final List<(int, int)> treeEdges;
  final String? highlightChar;
}

class HuffmanAlgorithm extends Algorithm {
  @override
  String get name => 'Huffman Coding';

  @override
  String get description => 'Optimal prefix-free encoding based on character frequencies.';

  @override
  AlgorithmCategory get category => AlgorithmCategory.compression; // Reusing category

  @override
  Future<List<AlgorithmState>> generate() async {
    const input = 'ABRACADABRA';
    final states = <HuffmanState>[];

    // Frequency table
    final freq = <String, int>{};
    for (final ch in input.split('')) { freq[ch] = (freq[ch] ?? 0) + 1; }

    states.add(HuffmanState(
      input: input, freqTable: Map.of(freq), codes: {},
      description: 'Input: "$input" — counting frequencies',
    ));

    states.add(HuffmanState(
      input: input, freqTable: Map.of(freq), codes: {},
      description: 'Frequencies: ${freq.entries.map((e) => "${e.key}:${e.value}").join(", ")}',
    ));

    // Build Huffman tree
    final pq = SplayTreeMap<int, List<_HNode>>();
    for (final entry in freq.entries) {
      pq.putIfAbsent(entry.value, () => []).add(_HNode(entry.key, entry.value));
    }

    _HNode removeMin() {
      final key = pq.firstKey()!;
      final list = pq[key]!;
      final node = list.removeAt(0);
      if (list.isEmpty) { pq.remove(key); }
      return node;
    }

    void addNode(_HNode node) {
      pq.putIfAbsent(node.freq, () => []).add(node);
    }

    while (pq.values.fold<int>(0, (s, l) => s + l.length) > 1) {
      final left = removeMin();
      final right = removeMin();
      final parent = _HNode(null, left.freq + right.freq, left: left, right: right);
      addNode(parent);

      states.add(HuffmanState(
        input: input, freqTable: freq, codes: {},
        description: 'Merge: ${_nodeLabel(left)} + ${_nodeLabel(right)} = ${parent.freq}',
      ));
    }

    final root = removeMin();

    // Generate codes
    final codes = <String, String>{};
    void buildCodes(_HNode? node, String code) {
      if (node == null) { return; }
      if (node.ch != null) { codes[node.ch!] = code.isEmpty ? '0' : code; return; }
      buildCodes(node.left, '${code}0');
      buildCodes(node.right, '${code}1');
    }
    buildCodes(root, '');

    // Layout tree
    final treeNodes = <(double, double, String, bool)>[];
    final treeEdges = <(int, int)>[];

    void layoutTree(_HNode? node, double x, double y, double spread, int? parentIdx) {
      if (node == null) { return; }
      final idx = treeNodes.length;
      final label = node.ch != null ? '${node.ch}:${node.freq}' : '${node.freq}';
      treeNodes.add((x, y, label, node.ch != null));
      if (parentIdx != null) { treeEdges.add((parentIdx, idx)); }
      layoutTree(node.left, x - spread, y + 0.15, spread * 0.55, idx);
      layoutTree(node.right, x + spread, y + 0.15, spread * 0.55, idx);
    }
    layoutTree(root, 0.5, 0.05, 0.22, null);

    states.add(HuffmanState(
      input: input, freqTable: freq, codes: Map.of(codes),
      treeNodes: treeNodes, treeEdges: treeEdges,
      description: 'Huffman tree built',
    ));

    // Show codes one by one
    for (final entry in codes.entries) {
      states.add(HuffmanState(
        input: input, freqTable: freq, codes: Map.of(codes),
        treeNodes: treeNodes, treeEdges: treeEdges,
        highlightChar: entry.key,
        description: '"${entry.key}" → ${entry.value}',
      ));
    }

    // Encode
    final encoded = input.split('').map((ch) => codes[ch]!).join('');
    states.add(HuffmanState(
      input: input, freqTable: freq, codes: codes,
      encoded: encoded, treeNodes: treeNodes, treeEdges: treeEdges,
      description: 'Encoded: $encoded (${encoded.length} bits vs ${input.length * 8} bits ASCII)',
    ));

    return states;
  }

  String _nodeLabel(_HNode n) => n.ch != null ? '"${n.ch}"(${n.freq})' : '(${n.freq})';

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) =>
      _HuffmanPainter(state: state as HuffmanState, brightness: Theme.of(context).brightness);
}

class _HuffmanPainter extends CustomPainter {
  _HuffmanPainter({required this.state, required this.brightness});

  final HuffmanState state;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final isDark = brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final dimColor = isDark ? Colors.white54 : Colors.black54;
    final nodeColor = isDark ? const Color(0xFF424242) : const Color(0xFFE0E0E0);
    final leafColor = isDark ? const Color(0xFF42A5F5) : const Color(0xFF1976D2);
    final highlightColor = isDark ? const Color(0xFFFFCA28) : const Color(0xFFF9A825);
    final edgeColor = isDark ? Colors.white24 : Colors.black26;

    // Tree (top 60%)
    final treeH = size.height * 0.6;
    for (final (from, to) in state.treeEdges) {
      final (fx, fy, _, _) = state.treeNodes[from];
      final (tx, ty, _, _) = state.treeNodes[to];
      canvas.drawLine(
        Offset(fx * size.width, fy * treeH),
        Offset(tx * size.width, ty * treeH),
        Paint()..color = edgeColor..strokeWidth = 1.5,
      );
    }

    for (final (x, y, label, isLeaf) in state.treeNodes) {
      final pos = Offset(x * size.width, y * treeH);
      final isHighlighted = state.highlightChar != null && label.startsWith(state.highlightChar!);
      final color = isHighlighted ? highlightColor : (isLeaf ? leafColor : nodeColor);

      canvas.drawCircle(pos, 14, Paint()..color = color);
      final tp = TextPainter(
        text: TextSpan(text: label, style: TextStyle(fontSize: 9, color: isLeaf ? Colors.white : textColor, fontWeight: FontWeight.w600)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }

    // Code table (bottom 40%)
    if (state.codes.isNotEmpty) {
      var y = treeH + 12;
      final entries = state.codes.entries.toList()..sort((a, b) => a.value.length.compareTo(b.value.length));

      final tp = TextPainter(
        text: TextSpan(text: 'Codes: ', style: TextStyle(fontSize: 12, color: dimColor, fontWeight: FontWeight.w600)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(16, y));
      y += tp.height + 4;

      var x = 16.0;
      for (final entry in entries) {
        final isHL = state.highlightChar == entry.key;
        final codeTp = TextPainter(
          text: TextSpan(
            text: '${entry.key}=${entry.value}  ',
            style: TextStyle(fontSize: 12, color: isHL ? highlightColor : textColor, fontWeight: isHL ? FontWeight.w700 : FontWeight.w400),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        if (x + codeTp.width > size.width - 16) { x = 16; y += codeTp.height + 2; }
        codeTp.paint(canvas, Offset(x, y));
        x += codeTp.width;
      }

      if (state.encoded != null) {
        y += 24;
        final encTp = TextPainter(
          text: TextSpan(
            children: [
              TextSpan(text: 'Encoded: ', style: TextStyle(fontSize: 11, color: dimColor)),
              TextSpan(text: state.encoded!.length > 60 ? '${state.encoded!.substring(0, 60)}...' : state.encoded!,
                style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF4CAF50) : const Color(0xFF388E3C))),
            ],
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        encTp.paint(canvas, Offset(16, y));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HuffmanPainter oldDelegate) => oldDelegate.state != state;
}
