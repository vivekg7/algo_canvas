import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';

class GcdState extends AlgorithmState {
  const GcdState({
    required this.a,
    required this.b,
    required this.originalA,
    required this.originalB,
    required this.steps,
    this.completed = false,
    required super.description,
  });

  final int a;
  final int b;
  final int originalA;
  final int originalB;

  /// History of (a, b, quotient, remainder) for each step.
  final List<(int, int, int, int)> steps;
  final bool completed;
}

class EuclideanGcdAlgorithm extends Algorithm {
  int _a = 252;
  int _b = 105;

  @override
  String get name => 'Euclidean Algorithm';

  @override
  String get description =>
      'Finds the GCD by repeated division. O(log(min(a,b))).';

  @override
  AlgorithmCategory get category => AlgorithmCategory.mathSignal;

  @override
  Future<List<AlgorithmState>> generate() async {
    var a = _a;
    var b = _b;
    final states = <GcdState>[];
    final history = <(int, int, int, int)>[];

    states.add(GcdState(
      a: a,
      b: b,
      originalA: _a,
      originalB: _b,
      steps: List.of(history),
      description: 'Finding GCD($a, $b)',
    ));

    while (b != 0) {
      final q = a ~/ b;
      final r = a % b;
      history.add((a, b, q, r));

      states.add(GcdState(
        a: a,
        b: b,
        originalA: _a,
        originalB: _b,
        steps: List.of(history),
        description: '$a = $b × $q + $r',
      ));

      a = b;
      b = r;
    }

    states.add(GcdState(
      a: a,
      b: b,
      originalA: _a,
      originalB: _b,
      steps: List.of(history),
      completed: true,
      description: 'GCD($_a, $_b) = $a',
    ));

    return states;
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) {
    return _GcdPainter(
      state: state as GcdState,
      brightness: Theme.of(context).brightness,
    );
  }

  @override
  Widget? buildControls({required VoidCallback onChanged}) {
    return _Controls(
      a: _a,
      b: _b,
      onChanged: (a, b) {
        _a = a;
        _b = b;
        onChanged();
      },
    );
  }
}

class _GcdPainter extends CustomPainter {
  _GcdPainter({required this.state, required this.brightness});

  final GcdState state;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final isDark = brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final dimColor = isDark ? Colors.white54 : Colors.black54;
    final accentColor = isDark ? const Color(0xFF42A5F5) : const Color(0xFF1976D2);
    final resultColor = isDark ? const Color(0xFF4CAF50) : const Color(0xFF388E3C);
    final dividerColor = isDark ? Colors.white12 : Colors.black12;

    // Visual: show the rectangle subdivision interpretation
    // Left half: geometric visualization, Right half: step equations

    final midX = size.width * 0.45;

    // -- Geometric visualization (rectangle being divided) --
    _paintRectangleDivision(canvas, Size(midX - 16, size.height), state, isDark);

    // -- Step equations on the right --
    final steps = state.steps;
    var y = 24.0;

    // Title
    final titleTp = TextPainter(
      text: TextSpan(
        text: 'GCD(${state.originalA}, ${state.originalB})',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    titleTp.paint(canvas, Offset(midX + 16, y));
    y += titleTp.height + 16;

    for (var i = 0; i < steps.length; i++) {
      final (a, b, q, r) = steps[i];
      final isLatest = i == steps.length - 1;

      // Divider
      if (i > 0) {
        canvas.drawLine(
          Offset(midX + 16, y),
          Offset(size.width - 16, y),
          Paint()..color = dividerColor,
        );
        y += 8;
      }

      final tp = TextPainter(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$a',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isLatest ? accentColor : dimColor,
              ),
            ),
            TextSpan(
              text: ' = $b × $q + ',
              style: TextStyle(fontSize: 15, color: dimColor),
            ),
            TextSpan(
              text: '$r',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: r == 0
                    ? resultColor
                    : (isLatest ? accentColor : dimColor),
              ),
            ),
          ],
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(midX + 16, y));
      y += tp.height + 8;
    }

    if (state.completed) {
      y += 8;
      final resultTp = TextPainter(
        text: TextSpan(
          text: 'GCD = ${state.a}',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: resultColor,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      resultTp.paint(canvas, Offset(midX + 16, y));
    }
  }

  void _paintRectangleDivision(
      Canvas canvas, Size size, GcdState state, bool isDark) {
    if (state.steps.isEmpty) return;

    final colors = [
      isDark ? const Color(0xFF42A5F5) : const Color(0xFF1976D2),
      isDark ? const Color(0xFF66BB6A) : const Color(0xFF388E3C),
      isDark ? const Color(0xFFFFCA28) : const Color(0xFFF9A825),
      isDark ? const Color(0xFFEF5350) : const Color(0xFFD32F2F),
      isDark ? const Color(0xFFAB47BC) : const Color(0xFF7B1FA2),
    ];

    // Draw rectangle subdivisions for each step
    var rectX = 16.0;
    var rectY = 16.0;
    var rectW = size.width - 32;
    var rectH = size.height - 32;

    // Scale based on original values
    final maxDim = max(state.originalA, state.originalB).toDouble();
    final scaleW = rectW / maxDim;
    final scaleH = rectH / maxDim;
    final scale = min(scaleW, scaleH);

    var w = state.originalA * scale;
    var h = state.originalB * scale;
    rectX = (size.width - w) / 2;
    rectY = (size.height - h) / 2;

    // Border
    canvas.drawRect(
      Rect.fromLTWH(rectX, rectY, w, h),
      Paint()
        ..color = isDark ? Colors.white24 : Colors.black26
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    var x = rectX;
    var y = rectY;
    var horizontal = true;

    for (var i = 0; i < state.steps.length; i++) {
      final (_, b, q, _) = state.steps[i];
      final color = colors[i % colors.length].withValues(alpha: 0.4);
      final sqSize = b * scale;

      for (var j = 0; j < q; j++) {
        if (horizontal) {
          canvas.drawRect(
            Rect.fromLTWH(x, y, sqSize, sqSize),
            Paint()..color = color,
          );
          canvas.drawRect(
            Rect.fromLTWH(x, y, sqSize, sqSize),
            Paint()
              ..color = isDark ? Colors.white24 : Colors.black26
              ..style = PaintingStyle.stroke
              ..strokeWidth = 0.5,
          );
          x += sqSize;
        } else {
          canvas.drawRect(
            Rect.fromLTWH(x, y, sqSize, sqSize),
            Paint()..color = color,
          );
          canvas.drawRect(
            Rect.fromLTWH(x, y, sqSize, sqSize),
            Paint()
              ..color = isDark ? Colors.white24 : Colors.black26
              ..style = PaintingStyle.stroke
              ..strokeWidth = 0.5,
          );
          y += sqSize;
        }
      }

      // Remaining strip becomes the new rectangle
      if (horizontal) {
        w = w - q * sqSize;
      } else {
        h = h - q * sqSize;
      }
      horizontal = !horizontal;
    }
  }

  @override
  bool shouldRepaint(covariant _GcdPainter oldDelegate) {
    return oldDelegate.state != state;
  }
}

class _Controls extends StatefulWidget {
  const _Controls({required this.a, required this.b, required this.onChanged});
  final int a;
  final int b;
  final void Function(int a, int b) onChanged;

  @override
  State<_Controls> createState() => _ControlsState();
}

class _ControlsState extends State<_Controls> {
  late final TextEditingController _aCtrl;
  late final TextEditingController _bCtrl;

  @override
  void initState() {
    super.initState();
    _aCtrl = TextEditingController(text: '${widget.a}');
    _bCtrl = TextEditingController(text: '${widget.b}');
  }

  @override
  void dispose() {
    _aCtrl.dispose();
    _bCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final a = int.tryParse(_aCtrl.text) ?? widget.a;
    final b = int.tryParse(_bCtrl.text) ?? widget.b;
    if (a > 0 && b > 0) widget.onChanged(a, b);
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodySmall;
    return Row(
      children: [
        Text('a:', style: textStyle),
        const SizedBox(width: 4),
        SizedBox(
          width: 70,
          child: TextField(
            controller: _aCtrl,
            keyboardType: TextInputType.number,
            style: textStyle,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(width: 12),
        Text('b:', style: textStyle),
        const SizedBox(width: 4),
        SizedBox(
          width: 70,
          child: TextField(
            controller: _bCtrl,
            keyboardType: TextInputType.number,
            style: textStyle,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: _submit,
          child: const Text('Run'),
        ),
        const SizedBox(width: 4),
        TextButton(
          onPressed: () {
            final random = Random();
            final a = random.nextInt(990) + 10;
            final b = random.nextInt(990) + 10;
            _aCtrl.text = '$a';
            _bCtrl.text = '$b';
            widget.onChanged(a, b);
          },
          child: const Text('Random'),
        ),
      ],
    );
  }
}
