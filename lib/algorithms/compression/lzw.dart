import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';

class LzwState extends AlgorithmState {
  const LzwState({
    required this.input,
    required this.dictionary,
    required this.output,
    this.currentStr,
    this.currentIdx = 0,
    required super.description,
  });

  final String input;
  final Map<String, int> dictionary;
  final List<int> output;
  final String? currentStr;
  final int currentIdx;
}

class LzwAlgorithm extends Algorithm {
  @override
  String get name => 'LZW Compression';

  @override
  String get description => 'Dictionary-based: build codes for repeated patterns. Used in GIF.';

  @override
  AlgorithmCategory get category => AlgorithmCategory.compression;

  @override
  Future<List<AlgorithmState>> generate() async {
    const input = 'TOBEORNOTTOBEORTOBEORNOT';
    final states = <LzwState>[];

    // Initialize dictionary with single characters
    final dict = <String, int>{};
    final chars = input.split('').toSet();
    var nextCode = 0;
    for (final ch in chars.toList()..sort()) {
      dict[ch] = nextCode++;
    }

    states.add(LzwState(
      input: input, dictionary: Map.of(dict), output: [],
      description: 'LZW: initial dictionary with ${dict.length} single chars',
    ));

    final output = <int>[];
    var w = '';

    for (var i = 0; i < input.length; i++) {
      final c = input[i];
      final wc = w + c;

      if (dict.containsKey(wc)) {
        w = wc;
        states.add(LzwState(
          input: input, dictionary: Map.of(dict),
          output: List.of(output), currentStr: w, currentIdx: i,
          description: '"$wc" in dictionary — extend',
        ));
      } else {
        output.add(dict[w]!);
        states.add(LzwState(
          input: input, dictionary: Map.of(dict),
          output: List.of(output), currentStr: w, currentIdx: i,
          description: 'Output code ${dict[w]} for "$w". Add "$wc"=$nextCode to dictionary',
        ));

        dict[wc] = nextCode++;
        w = c;
      }
    }

    if (w.isNotEmpty) {
      output.add(dict[w]!);
      states.add(LzwState(
        input: input, dictionary: Map.of(dict),
        output: List.of(output), currentStr: w, currentIdx: input.length - 1,
        description: 'Output final code ${dict[w]} for "$w"',
      ));
    }

    states.add(LzwState(
      input: input, dictionary: dict, output: output,
      description: 'LZW complete: ${input.length} chars → ${output.length} codes. Dictionary: ${dict.length} entries',
    ));

    return states;
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) =>
      _LzwPainter(state: state as LzwState, brightness: Theme.of(context).brightness);
}

class _LzwPainter extends CustomPainter {
  _LzwPainter({required this.state, required this.brightness});

  final LzwState state;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final isDark = brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final dimColor = isDark ? Colors.white54 : Colors.black54;
    final accentColor = isDark ? const Color(0xFF42A5F5) : const Color(0xFF1976D2);
    final highlightColor = isDark ? const Color(0xFFFFCA28) : const Color(0xFFF9A825);
    final successColor = isDark ? const Color(0xFF4CAF50) : const Color(0xFF388E3C);

    var y = 16.0;

    // Input string with highlight
    _drawLabel(canvas, 'Input:', 16, y, dimColor);
    y += 16;
    final input = state.input;
    final cellSize = ((size.width - 32) / input.length).clamp(12.0, 24.0);
    final offsetX = (size.width - cellSize * input.length) / 2;

    for (var i = 0; i < input.length; i++) {
      final rect = Rect.fromLTWH(offsetX + i * cellSize, y, cellSize - 0.5, cellSize);
      var color = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5);

      if (state.currentStr != null && i >= state.currentIdx - state.currentStr!.length + 1 && i <= state.currentIdx) {
        color = highlightColor.withValues(alpha: 0.4);
      }

      canvas.drawRect(rect, Paint()..color = color);
      canvas.drawRect(rect, Paint()..color = isDark ? Colors.white12 : Colors.black12..style = PaintingStyle.stroke..strokeWidth = 0.5);

      if (cellSize >= 14) {
        final tp = TextPainter(
          text: TextSpan(text: input[i], style: TextStyle(fontSize: 11, color: textColor)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(offsetX + i * cellSize + (cellSize - tp.width) / 2, y + (cellSize - tp.height) / 2));
      }
    }
    y += cellSize + 16;

    // Output codes
    _drawLabel(canvas, 'Output: [${state.output.join(", ")}]', 16, y, accentColor);
    y += 20;

    // Dictionary (show last entries)
    _drawLabel(canvas, 'Dictionary (${state.dictionary.length} entries):', 16, y, dimColor);
    y += 16;

    final entries = state.dictionary.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    var x = 16.0;
    for (final entry in entries) {
      final isNew = entry.key.length > 1;
      final tp = TextPainter(
        text: TextSpan(
          text: '${entry.key}=${entry.value} ',
          style: TextStyle(
            fontSize: 10,
            color: isNew ? successColor : dimColor,
            fontWeight: isNew ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      if (x + tp.width > size.width - 16) { x = 16; y += tp.height + 2; }
      if (y + tp.height > size.height) { break; }
      tp.paint(canvas, Offset(x, y));
      x += tp.width;
    }
  }

  void _drawLabel(Canvas canvas, String text, double x, double y, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x, y));
  }

  @override
  bool shouldRepaint(covariant _LzwPainter oldDelegate) => oldDelegate.state != state;
}
