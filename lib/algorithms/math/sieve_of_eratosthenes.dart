import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';

class SieveState extends AlgorithmState {
  const SieveState({
    required this.limit,
    required this.isPrime,
    this.currentFactor,
    this.currentMultiple,
    this.primeCount = 0,
    this.completed = false,
    required super.description,
  });

  final int limit;
  /// Index 0..limit. true = still candidate/prime, false = composite.
  final List<bool> isPrime;
  final int? currentFactor;
  final int? currentMultiple;
  final int primeCount;
  final bool completed;
}

class SieveOfEratosthenesAlgorithm extends Algorithm {
  int _limit = 200;

  @override
  String get name => 'Sieve of Eratosthenes';

  @override
  String get description =>
      'Finds all primes up to N by eliminating multiples of each prime.';

  @override
  AlgorithmCategory get category => AlgorithmCategory.mathSignal;

  @override
  Future<List<AlgorithmState>> generate() async {
    final n = _limit;
    final isPrime = List<bool>.filled(n + 1, true);
    isPrime[0] = false;
    isPrime[1] = false;
    final states = <SieveState>[];

    states.add(SieveState(
      limit: n,
      isPrime: List.of(isPrime),
      description: 'Finding all primes up to $n',
    ));

    for (var i = 2; i <= sqrt(n).floor(); i++) {
      if (!isPrime[i]) continue;

      states.add(SieveState(
        limit: n,
        isPrime: List.of(isPrime),
        currentFactor: i,
        description: '$i is prime — eliminating its multiples',
      ));

      for (var j = i * i; j <= n; j += i) {
        isPrime[j] = false;
        states.add(SieveState(
          limit: n,
          isPrime: List.of(isPrime),
          currentFactor: i,
          currentMultiple: j,
          description: 'Marking $j as composite ($i × ${j ~/ i})',
        ));
      }
    }

    final primeCount = isPrime.where((p) => p).length;
    states.add(SieveState(
      limit: n,
      isPrime: List.of(isPrime),
      primeCount: primeCount,
      completed: true,
      description: 'Found $primeCount primes up to $n',
    ));

    return states;
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) {
    return _SievePainter(
      state: state as SieveState,
      brightness: Theme.of(context).brightness,
    );
  }

  @override
  Widget? buildControls({required VoidCallback onChanged}) {
    return _SizeControl(
      limit: _limit,
      onChanged: (v) {
        _limit = v;
        onChanged();
      },
    );
  }
}

class _SievePainter extends CustomPainter {
  _SievePainter({required this.state, required this.brightness});

  final SieveState state;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final n = state.limit;
    final cols = sqrt(n).ceil();
    final rows = (n / cols).ceil();
    final cellW = size.width / cols;
    final cellH = size.height / rows;
    final cellSize = min(cellW, cellH);
    final offsetX = (size.width - cellSize * cols) / 2;
    final offsetY = (size.height - cellSize * rows) / 2;

    final isDark = brightness == Brightness.dark;
    final primeColor = isDark ? const Color(0xFF4CAF50) : const Color(0xFF388E3C);
    final compositeColor = isDark ? const Color(0xFF424242) : const Color(0xFFBDBDBD);
    final factorColor = isDark ? const Color(0xFFFFCA28) : const Color(0xFFF9A825);
    final multipleColor = isDark ? const Color(0xFFEF5350) : const Color(0xFFD32F2F);
    final textColor = isDark ? Colors.white : Colors.black;
    final dimText = isDark ? Colors.white38 : Colors.black26;

    for (var num = 2; num <= n; num++) {
      final idx = num - 2;
      final col = idx % cols;
      final row = idx ~/ cols;
      final rect = Rect.fromLTWH(
        offsetX + col * cellSize,
        offsetY + row * cellSize,
        cellSize - 0.5,
        cellSize - 0.5,
      );

      Color bg;
      if (num == state.currentMultiple) {
        bg = multipleColor;
      } else if (num == state.currentFactor) {
        bg = factorColor;
      } else if (state.isPrime[num]) {
        bg = state.completed ? primeColor : primeColor.withValues(alpha: 0.3);
      } else {
        bg = compositeColor.withValues(alpha: 0.3);
      }

      canvas.drawRect(rect, Paint()..color = bg);

      // Number text (only if cells are large enough)
      if (cellSize >= 16) {
        final tp = TextPainter(
          text: TextSpan(
            text: '$num',
            style: TextStyle(
              fontSize: (cellSize * 0.35).clamp(6, 14),
              color: state.isPrime[num] ? textColor : dimText,
              fontWeight: state.isPrime[num] ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final center = Offset(
          offsetX + col * cellSize + cellSize / 2,
          offsetY + row * cellSize + cellSize / 2,
        );
        tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SievePainter oldDelegate) {
    return oldDelegate.state != state;
  }
}

class _SizeControl extends StatefulWidget {
  const _SizeControl({required this.limit, required this.onChanged});
  final int limit;
  final ValueChanged<int> onChanged;

  @override
  State<_SizeControl> createState() => _SizeControlState();
}

class _SizeControlState extends State<_SizeControl> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.limit.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('Limit: ${_value.round()}',
            style: Theme.of(context).textTheme.bodySmall),
        Expanded(
          child: Slider(
            value: _value, min: 50, max: 500, divisions: 45,
            onChanged: (v) => setState(() => _value = v),
            onChangeEnd: (v) => widget.onChanged(v.round()),
          ),
        ),
      ],
    );
  }
}
