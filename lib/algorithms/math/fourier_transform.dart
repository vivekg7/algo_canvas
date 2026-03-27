import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';

class FourierState extends AlgorithmState {
  const FourierState({
    required this.signal,
    required this.magnitudes,
    required this.currentK,
    required this.n,
    this.completed = false,
    required super.description,
  });

  /// Time-domain signal values.
  final List<double> signal;

  /// Frequency-domain magnitudes computed so far.
  final List<double> magnitudes;

  /// Current frequency index being computed.
  final int currentK;
  final int n;
  final bool completed;
}

class FourierTransformAlgorithm extends Algorithm {
  int _sampleCount = 128;
  // Compose signal from these frequencies
  final List<(double freq, double amp)> _components = [
    (3, 1.0),
    (7, 0.6),
    (15, 0.3),
  ];

  @override
  String get name => 'Fourier Transform';

  @override
  String get description =>
      'Decompose a signal into frequency components using DFT.';

  @override
  AlgorithmCategory get category => AlgorithmCategory.mathSignal;

  @override
  Future<List<AlgorithmState>> generate() async {
    final n = _sampleCount;
    final states = <FourierState>[];

    // Generate composite signal
    final signal = List<double>.generate(n, (i) {
      var val = 0.0;
      for (final (freq, amp) in _components) {
        val += amp * sin(2 * pi * freq * i / n);
      }
      return val;
    });

    final magnitudes = List<double>.filled(n ~/ 2, 0);

    states.add(FourierState(
      signal: signal,
      magnitudes: List.of(magnitudes),
      currentK: -1,
      n: n,
      description:
          'Signal composed of frequencies: ${_components.map((c) => '${c.$1}Hz').join(", ")}',
    ));

    // DFT: compute each frequency bin
    for (var k = 0; k < n ~/ 2; k++) {
      var re = 0.0;
      var im = 0.0;
      for (var t = 0; t < n; t++) {
        final angle = 2 * pi * k * t / n;
        re += signal[t] * cos(angle);
        im -= signal[t] * sin(angle);
      }
      magnitudes[k] = sqrt(re * re + im * im) / n;

      // Emit every few bins to keep step count reasonable
      if (k % 2 == 0 || k < 20 || magnitudes[k] > 0.1) {
        states.add(FourierState(
          signal: signal,
          magnitudes: List.of(magnitudes),
          currentK: k,
          n: n,
          description:
              'Computing frequency bin $k: magnitude = ${magnitudes[k].toStringAsFixed(4)}',
        ));
      }
    }

    states.add(FourierState(
      signal: signal,
      magnitudes: List.of(magnitudes),
      currentK: n ~/ 2,
      n: n,
      completed: true,
      description:
          'DFT complete — peaks at frequencies ${_components.map((c) => c.$1).join(", ")}',
    ));

    return states;
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) {
    return _FourierPainter(
      state: state as FourierState,
      colorScheme: Theme.of(context).colorScheme,
    );
  }

  @override
  Widget? buildControls({required VoidCallback onChanged}) {
    return _Controls(
      sampleCount: _sampleCount,
      onChanged: (v) {
        _sampleCount = v;
        onChanged();
      },
    );
  }
}

class _FourierPainter extends CustomPainter {
  _FourierPainter({required this.state, required this.colorScheme});

  final FourierState state;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final isDark = colorScheme.brightness == Brightness.dark;
    final signalColor = colorScheme.primary;
    final freqColor = isDark ? const Color(0xFF66BB6A) : const Color(0xFF388E3C);
    final peakColor = colorScheme.tertiary;
    final currentColor = isDark ? const Color(0xFFEF5350) : const Color(0xFFD32F2F);
    final axisColor = isDark ? Colors.white24 : Colors.black26;
    final textColor = isDark ? Colors.white70 : Colors.black54;

    final topH = size.height * 0.45;
    final bottomH = size.height * 0.45;
    final gap = size.height * 0.1;

    // -- Time domain (top) --
    _paintLabel(canvas, 'Time Domain', 8, 4, textColor);

    final signal = state.signal;
    final midY = topH / 2;
    final maxSignal = signal.map((v) => v.abs()).reduce(max);
    final ampScale = maxSignal > 0 ? (topH * 0.4) / maxSignal : 1.0;

    // Axis
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY),
        Paint()..color = axisColor..strokeWidth = 0.5);

    final signalPath = Path();
    for (var i = 0; i < signal.length; i++) {
      final x = i / signal.length * size.width;
      final y = midY - signal[i] * ampScale;
      if (i == 0) {
        signalPath.moveTo(x, y);
      } else {
        signalPath.lineTo(x, y);
      }
    }
    canvas.drawPath(
      signalPath,
      Paint()
        ..color = signalColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // -- Frequency domain (bottom) --
    final bottomTop = topH + gap;
    _paintLabel(canvas, 'Frequency Domain', 8, bottomTop + 4, textColor);

    final mags = state.magnitudes;
    final halfN = mags.length;
    if (halfN == 0) return;

    final maxMag = mags.reduce(max);
    final magScale = maxMag > 0 ? (bottomH * 0.8) / maxMag : 1.0;

    // Axis
    canvas.drawLine(
      Offset(0, bottomTop + bottomH),
      Offset(size.width, bottomTop + bottomH),
      Paint()..color = axisColor..strokeWidth = 0.5,
    );

    final barWidth = size.width / halfN;
    for (var k = 0; k < halfN; k++) {
      if (mags[k] < 0.001) continue;

      final barH = mags[k] * magScale;
      final rect = Rect.fromLTWH(
        k * barWidth,
        bottomTop + bottomH - barH,
        barWidth - (halfN > 200 ? 0 : 0.5),
        barH,
      );

      Color barColor;
      if (k == state.currentK) {
        barColor = currentColor;
      } else if (mags[k] > maxMag * 0.3 && state.completed) {
        barColor = peakColor;
      } else {
        barColor = freqColor;
      }

      canvas.drawRect(rect, Paint()..color = barColor);
    }

    // Current bin marker
    if (state.currentK >= 0 && state.currentK < halfN) {
      canvas.drawLine(
        Offset(state.currentK * barWidth, bottomTop),
        Offset(state.currentK * barWidth, bottomTop + bottomH),
        Paint()
          ..color = currentColor.withValues(alpha: 0.5)
          ..strokeWidth = 1,
      );
    }
  }

  void _paintLabel(
      Canvas canvas, String text, double x, double y, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x, y));
  }

  @override
  bool shouldRepaint(covariant _FourierPainter oldDelegate) {
    return oldDelegate.state != state || oldDelegate.colorScheme != colorScheme;
  }
}

class _Controls extends StatefulWidget {
  const _Controls({required this.sampleCount, required this.onChanged});
  final int sampleCount;
  final ValueChanged<int> onChanged;

  @override
  State<_Controls> createState() => _ControlsState();
}

class _ControlsState extends State<_Controls> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.sampleCount.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('Samples: ${_value.round()}',
            style: Theme.of(context).textTheme.bodySmall),
        Expanded(
          child: Slider(
            value: _value, min: 64, max: 512, divisions: 7,
            onChanged: (v) => setState(() => _value = v),
            onChangeEnd: (v) => widget.onChanged(v.round()),
          ),
        ),
      ],
    );
  }
}
