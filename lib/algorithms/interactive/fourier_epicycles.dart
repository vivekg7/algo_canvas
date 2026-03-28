import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';
import 'package:algo_canvas/widgets/color_legend.dart';

// --- Data types ---

class FourierTerm {
  const FourierTerm({
    required this.frequency,
    required this.amplitude,
    required this.phase,
  });
  final int frequency;
  final double amplitude;
  final double phase;
}

// --- State ---

class FourierEpicyclesState extends AlgorithmState {
  const FourierEpicyclesState({
    required this.drawnPoints,
    required this.terms,
    required this.numTerms,
    required this.time,
    required this.tracedPath,
    required this.isDrawing,
    this.pauseRemaining = 0,
    required super.description,
  });

  final List<Offset> drawnPoints;
  final List<FourierTerm> terms;
  final int numTerms;
  final double time;
  final List<Offset> tracedPath;
  final bool isDrawing;
  /// Ticks remaining in the pause between loops (~60fps, so 300 = 5 seconds).
  final int pauseRemaining;
}

// --- Algorithm ---

class FourierEpicyclesAlgorithm extends Algorithm {
  int _numTerms = 0;
  final ValueNotifier<int> _maxTermsNotifier = ValueNotifier(0);

  @override
  String get name => 'Fourier Epicycles';

  @override
  String get description =>
      'Draw a shape, watch rotating circles reconstruct it via Fourier series';

  @override
  AlgorithmCategory get category => AlgorithmCategory.mathSignal;

  @override
  AlgorithmMode get mode => AlgorithmMode.interactive;

  @override
  AlgorithmState createInitialState() {
    _numTerms = 0;
    _maxTermsNotifier.value = 0;
    return const FourierEpicyclesState(
      drawnPoints: [],
      terms: [],
      numTerms: 0,
      time: 0,
      tracedPath: [],
      isDrawing: false,
      description: 'Draw a shape with your finger',
    );
  }

  @override
  AlgorithmState? onInteractionStart(
      AlgorithmState current, Offset localPosition) {
    _numTerms = 0;
    _maxTermsNotifier.value = 0;
    return FourierEpicyclesState(
      drawnPoints: [localPosition],
      terms: const [],
      numTerms: 0,
      time: 0,
      tracedPath: const [],
      isDrawing: true,
      description: 'Drawing...',
    );
  }

  @override
  AlgorithmState? onInteractionUpdate(
      AlgorithmState current, Offset localPosition) {
    final s = current as FourierEpicyclesState;
    if (!s.isDrawing) return null;
    return FourierEpicyclesState(
      drawnPoints: [...s.drawnPoints, localPosition],
      terms: const [],
      numTerms: 0,
      time: 0,
      tracedPath: const [],
      isDrawing: true,
      description: 'Drawing... (${s.drawnPoints.length + 1} points)',
    );
  }

  @override
  AlgorithmState? onInteractionEnd(AlgorithmState current) {
    final s = current as FourierEpicyclesState;
    if (!s.isDrawing || s.drawnPoints.length < 10) {
      return FourierEpicyclesState(
        drawnPoints: const [],
        terms: const [],
        numTerms: 0,
        time: 0,
        tracedPath: const [],
        isDrawing: false,
        description: 'Too few points — draw a longer shape',
      );
    }

    // Close the loop by connecting end to start
    final closed = [...s.drawnPoints, s.drawnPoints.first];
    final sampled = _resample(closed, min(closed.length, 256));
    final allTerms = _computeDFT(sampled);
    // Keep only the top 50 terms by amplitude
    final terms = allTerms.sublist(0, min(allTerms.length, 50));
    final numTerms = terms.length;

    _numTerms = numTerms;
    _maxTermsNotifier.value = numTerms;

    return FourierEpicyclesState(
      drawnPoints: sampled,
      terms: terms,
      numTerms: numTerms,
      time: 0,
      tracedPath: const [],
      isDrawing: false,
      description: 'Reconstructing with $numTerms terms',
    );
  }

  @override
  AlgorithmState? tick(AlgorithmState current) {
    final s = current as FourierEpicyclesState;
    if (s.isDrawing || s.terms.isEmpty) return null;

    final numTerms = _numTerms.clamp(1, s.terms.length);
    final termsChanged = numTerms != s.numTerms;

    // Pausing between loops
    if (s.pauseRemaining > 0) {
      // If terms changed during pause, restart immediately
      if (termsChanged) {
        return FourierEpicyclesState(
          drawnPoints: s.drawnPoints,
          terms: s.terms,
          numTerms: numTerms,
          time: 0,
          tracedPath: const [],
          isDrawing: false,
          description: 'Reconstructing with $numTerms / ${s.terms.length} terms',
        );
      }
      final remaining = s.pauseRemaining - 1;
      if (remaining > 0) {
        return FourierEpicyclesState(
          drawnPoints: s.drawnPoints,
          terms: s.terms,
          numTerms: s.numTerms,
          time: s.time,
          tracedPath: s.tracedPath,
          isDrawing: false,
          pauseRemaining: remaining,
          description: 'Restarting in ${(remaining / 60).ceil()}s...',
        );
      }
      // Pause finished — restart the loop
      return FourierEpicyclesState(
        drawnPoints: s.drawnPoints,
        terms: s.terms,
        numTerms: s.numTerms,
        time: 0,
        tracedPath: const [],
        isDrawing: false,
        description: 'Reconstructing with ${s.numTerms} / ${s.terms.length} terms',
      );
    }

    const dt = 1 / 360;
    var newTime = s.time + dt;
    List<Offset> newTrace;
    var pause = 0;

    if (newTime >= 1.0) {
      // Loop complete — pause for ~5 seconds (300 ticks at 60fps)
      newTime = 1.0;
      newTrace = List<Offset>.of(s.tracedPath);
      pause = 300;
    } else if (termsChanged) {
      newTime = 0;
      newTrace = [];
    } else {
      newTrace = List<Offset>.of(s.tracedPath);
    }

    if (pause == 0) {
      final tip = _computeTip(s.terms, numTerms, newTime);
      newTrace.add(tip);
    }

    return FourierEpicyclesState(
      drawnPoints: s.drawnPoints,
      terms: s.terms,
      numTerms: numTerms,
      time: newTime,
      tracedPath: newTrace,
      isDrawing: false,
      pauseRemaining: pause,
      description: pause > 0
          ? 'Restarting in ${(pause / 60).ceil()}s...'
          : 'Reconstructing with $numTerms / ${s.terms.length} terms',
    );
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) =>
      _FourierEpicyclesPainter(
        state: state as FourierEpicyclesState,
        brightness: Theme.of(context).brightness,
      );

  @override
  Widget? buildControls({required VoidCallback onChanged}) {
    return _Controls(algorithm: this);
  }

  @override
  List<LegendItem>? buildLegend(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      LegendItem(
        isDark ? const Color(0xFF42A5F5) : const Color(0xFF1976D2),
        'Traced path',
      ),
      LegendItem(
        isDark ? const Color(0xFFFFCA28) : const Color(0xFFF9A825),
        'Epicycles',
      ),
      LegendItem(
        isDark ? Colors.white24 : Colors.black12,
        'Original drawing',
      ),
    ];
  }

  // --- DFT computation ---

  static List<FourierTerm> _computeDFT(List<Offset> points) {
    final n = points.length;
    final terms = <FourierTerm>[];

    for (var k = 0; k < n; k++) {
      var re = 0.0;
      var im = 0.0;
      for (var j = 0; j < n; j++) {
        final angle = -2 * pi * k * j / n;
        re += points[j].dx * cos(angle) - points[j].dy * sin(angle);
        im += points[j].dx * sin(angle) + points[j].dy * cos(angle);
      }
      re /= n;
      im /= n;

      final freq = k <= n ~/ 2 ? k : k - n;
      terms.add(FourierTerm(
        frequency: freq,
        amplitude: sqrt(re * re + im * im),
        phase: atan2(im, re),
      ));
    }

    // Sort by amplitude descending so the largest epicycles come first
    terms.sort((a, b) => b.amplitude.compareTo(a.amplitude));
    return terms;
  }

  static Offset _computeTip(List<FourierTerm> terms, int numTerms, double t) {
    var x = 0.0;
    var y = 0.0;
    final count = min(numTerms, terms.length);
    for (var i = 0; i < count; i++) {
      final term = terms[i];
      final angle = 2 * pi * term.frequency * t + term.phase;
      x += term.amplitude * cos(angle);
      y += term.amplitude * sin(angle);
    }
    return Offset(x, y);
  }

  // --- Resampling ---

  static List<Offset> _resample(List<Offset> points, int n) {
    if (points.length <= 1 || n <= 1) return List.of(points);

    // Compute cumulative arc lengths
    final lengths = <double>[0.0];
    for (var i = 1; i < points.length; i++) {
      final dx = points[i].dx - points[i - 1].dx;
      final dy = points[i].dy - points[i - 1].dy;
      lengths.add(lengths.last + sqrt(dx * dx + dy * dy));
    }
    final totalLength = lengths.last;
    if (totalLength == 0) return [points.first];

    final result = <Offset>[];
    var segIndex = 0;
    for (var i = 0; i < n; i++) {
      final target = totalLength * i / n;
      while (segIndex < lengths.length - 2 &&
          lengths[segIndex + 1] < target) {
        segIndex++;
      }
      final segLen = lengths[segIndex + 1] - lengths[segIndex];
      final t = segLen == 0 ? 0.0 : (target - lengths[segIndex]) / segLen;
      result.add(Offset(
        points[segIndex].dx + t * (points[segIndex + 1].dx - points[segIndex].dx),
        points[segIndex].dy + t * (points[segIndex + 1].dy - points[segIndex].dy),
      ));
    }
    return result;
  }
}

// --- Controls widget ---

class _Controls extends StatefulWidget {
  const _Controls({required this.algorithm});
  final FourierEpicyclesAlgorithm algorithm;

  @override
  State<_Controls> createState() => _ControlsState();
}

class _ControlsState extends State<_Controls> {
  @override
  void initState() {
    super.initState();
    widget.algorithm._maxTermsNotifier.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.algorithm._maxTermsNotifier.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final maxTerms = widget.algorithm._maxTermsNotifier.value;
    if (maxTerms < 2) return const SizedBox.shrink();

    final numTerms = widget.algorithm._numTerms.clamp(1, maxTerms);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            'Terms',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          Expanded(
            child: Slider(
              value: numTerms.toDouble(),
              min: 1,
              max: maxTerms.toDouble(),
              divisions: maxTerms - 1,
              label: '$numTerms',
              onChanged: (v) {
                setState(() => widget.algorithm._numTerms = v.round());
              },
            ),
          ),
          SizedBox(
            width: 56,
            child: Text(
              '$numTerms / $maxTerms',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

// --- Painter ---

class _FourierEpicyclesPainter extends CustomPainter {
  _FourierEpicyclesPainter({required this.state, required this.brightness});
  final FourierEpicyclesState state;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final isDark = brightness == Brightness.dark;

    if (state.isDrawing) {
      _paintDrawing(canvas, size, isDark);
      return;
    }

    if (state.terms.isEmpty) {
      _paintHint(canvas, size, isDark);
      return;
    }

    _paintOriginal(canvas, size, isDark);
    _paintEpicycles(canvas, size, isDark);
    _paintTracedPath(canvas, size, isDark);
  }

  void _paintHint(Canvas canvas, Size size, bool isDark) {
    final tp = TextPainter(
      text: TextSpan(
        text: 'Draw a shape with your finger',
        style: TextStyle(
          color: isDark ? Colors.white38 : Colors.black26,
          fontSize: 16,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(
        (size.width - tp.width) / 2,
        (size.height - tp.height) / 2,
      ),
    );
  }

  void _paintDrawing(Canvas canvas, Size size, bool isDark) {
    final pts = state.drawnPoints;
    if (pts.length < 2) return;

    final paint = Paint()
      ..color = isDark ? const Color(0xFF42A5F5) : const Color(0xFF1976D2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(pts[0].dx * size.width, pts[0].dy * size.height);
    for (var i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx * size.width, pts[i].dy * size.height);
    }
    canvas.drawPath(path, paint);
  }

  void _paintOriginal(Canvas canvas, Size size, bool isDark) {
    final pts = state.drawnPoints;
    if (pts.length < 2) return;

    final paint = Paint()
      ..color = isDark ? Colors.white12 : Colors.black12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(pts[0].dx * size.width, pts[0].dy * size.height);
    for (var i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx * size.width, pts[i].dy * size.height);
    }
    canvas.drawPath(path, paint);
  }

  void _paintEpicycles(Canvas canvas, Size size, bool isDark) {
    final terms = state.terms;
    final numTerms = state.numTerms.clamp(1, terms.length);
    final t = state.time;

    final circleColor = isDark
        ? const Color(0xFFFFCA28).withValues(alpha: 0.3)
        : const Color(0xFFF9A825).withValues(alpha: 0.25);
    final radiusPaint = Paint()
      ..color = circleColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    final armPaint = Paint()
      ..color = isDark
          ? const Color(0xFFFFCA28).withValues(alpha: 0.7)
          : const Color(0xFFF9A825).withValues(alpha: 0.6)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    var cx = 0.0;
    var cy = 0.0;

    for (var i = 0; i < numTerms; i++) {
      final term = terms[i];
      final angle = 2 * pi * term.frequency * t + term.phase;
      final radius = term.amplitude;

      final nx = cx + radius * cos(angle);
      final ny = cy + radius * sin(angle);

      // Skip the DC term (frequency 0) — it's just a constant offset
      if (term.frequency != 0) {
        final screenCx = cx * size.width;
        final screenCy = cy * size.height;
        final screenR = radius * min(size.width, size.height);

        // Draw circle
        if (screenR > 1) {
          canvas.drawCircle(Offset(screenCx, screenCy), screenR, radiusPaint);
        }

        // Draw arm
        canvas.drawLine(
          Offset(screenCx, screenCy),
          Offset(nx * size.width, ny * size.height),
          armPaint,
        );
      }

      cx = nx;
      cy = ny;
    }

    // Draw tip dot
    canvas.drawCircle(
      Offset(cx * size.width, cy * size.height),
      3.5,
      Paint()
        ..color = isDark ? const Color(0xFFEF5350) : const Color(0xFFD32F2F),
    );
  }

  void _paintTracedPath(Canvas canvas, Size size, bool isDark) {
    final pts = state.tracedPath;
    if (pts.length < 2) return;

    final paint = Paint()
      ..color = isDark ? const Color(0xFF42A5F5) : const Color(0xFF1976D2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(pts[0].dx * size.width, pts[0].dy * size.height);
    for (var i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx * size.width, pts[i].dy * size.height);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _FourierEpicyclesPainter old) =>
      !identical(old.state, state);
}
