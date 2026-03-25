import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';

class PythagorasState extends AlgorithmState {
  const PythagorasState({
    required this.squares,
    required this.branches,
    required this.depth,
    required this.thickness,
    required super.description,
  });
  final List<List<(double, double)>> squares;
  /// Connected branch lines: (fromX, fromY, toX, toY) normalized.
  final List<(double, double, double, double)> branches;
  final int depth;
  final double thickness;
}

class PythagorasTreeAlgorithm extends Algorithm {
  int _maxDepth = 10;
  double _thickness = 1.0; // 0 = skeleton lines, 1 = full squares

  @override String get name => 'Pythagoras Tree';
  @override String get description => 'Recursive squares forming a fractal tree. Each square spawns two child squares.';
  @override AlgorithmCategory get category => AlgorithmCategory.fractals;

  @override
  Future<List<AlgorithmState>> generate() async {
    final states = <PythagorasState>[];

    for (var depth = 0; depth <= _maxDepth; depth++) {
      final rawSquares = <List<(double, double)>>[];
      final rawBranches = <(double, double, double, double)>[];
      _generate(rawSquares, rawBranches, (-0.1, 0.0), (0.1, 0.0), depth);

      // Collect all points for normalization
      final allPoints = <(double, double)>[];
      for (final sq in rawSquares) { allPoints.addAll(sq); }
      for (final (x1, y1, x2, y2) in rawBranches) {
        allPoints.add((x1, y1));
        allPoints.add((x2, y2));
      }

      var minX = allPoints[0].$1, maxX = allPoints[0].$1;
      var minY = allPoints[0].$2, maxY = allPoints[0].$2;
      for (final (px, py) in allPoints) {
        if (px < minX) { minX = px; }
        if (px > maxX) { maxX = px; }
        if (py < minY) { minY = py; }
        if (py > maxY) { maxY = py; }
      }
      final range = max(maxX - minX, maxY - minY);
      final r = range > 0 ? range : 1.0;

      (double, double) norm((double, double) p) =>
          (0.05 + 0.9 * (p.$1 - minX) / r, 0.95 - 0.9 * (p.$2 - minY) / r);

      final squares = rawSquares.map((sq) => sq.map(norm).toList()).toList();
      final branches = rawBranches.map((b) {
        final from = norm((b.$1, b.$2));
        final to = norm((b.$3, b.$4));
        return (from.$1, from.$2, to.$1, to.$2);
      }).toList();

      states.add(PythagorasState(
        squares: squares, branches: branches,
        depth: depth, thickness: _thickness,
        description: 'Depth $depth: ${squares.length} squares',
      ));
    }

    return states;
  }

  void _generate(
    List<List<(double, double)>> squares,
    List<(double, double, double, double)> branches,
    (double, double) bl, (double, double) br, int depth, {
    (double, double)? parentJoint,
  }) {
    final dx = br.$1 - bl.$1;
    final dy = br.$2 - bl.$2;
    final tl = (bl.$1 - dy, bl.$2 + dx);
    final tr = (br.$1 - dy, br.$2 + dx);

    squares.add([bl, br, tr, tl]);

    // This square's midpoints
    final botMid = ((bl.$1 + br.$1) / 2, (bl.$2 + br.$2) / 2);
    final topMid = ((tl.$1 + tr.$1) / 2, (tl.$2 + tr.$2) / 2);

    // Branch from parent joint (or bottom) to this square's top
    final from = parentJoint ?? botMid;
    branches.add((from.$1, from.$2, topMid.$1, topMid.$2));

    if (depth == 0) { return; }

    // Peak
    final edgeDx = tr.$1 - tl.$1;
    final edgeDy = tr.$2 - tl.$2;
    final peak = (topMid.$1 - edgeDy / 2, topMid.$2 + edgeDx / 2);

    // Branch from top midpoint to peak
    branches.add((topMid.$1, topMid.$2, peak.$1, peak.$2));

    _generate(squares, branches, tl, peak, depth - 1, parentJoint: peak);
    _generate(squares, branches, peak, tr, depth - 1, parentJoint: peak);
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) =>
      _PythagorasPainter(state: state as PythagorasState, brightness: Theme.of(context).brightness);

  @override
  Widget? buildControls({required VoidCallback onChanged}) =>
      _Ctrl(depth: _maxDepth, thickness: _thickness, onChanged: (d, t) {
        _maxDepth = d; _thickness = t; onChanged();
      });
}

class _PythagorasPainter extends CustomPainter {
  _PythagorasPainter({required this.state, required this.brightness});
  final PythagorasState state;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final isDark = brightness == Brightness.dark;
    final thickness = state.thickness;

    if (thickness <= 0.01) {
      // Pure skeleton: draw connected branch lines
      final total = state.branches.length;
      for (var i = 0; i < total; i++) {
        final (x1, y1, x2, y2) = state.branches[i];
        final t = total > 1 ? i / (total - 1) : 0.0;
        final hue = 120 + t * 240;
        final color = HSVColor.fromAHSV(0.9, hue % 360, 0.8, isDark ? 0.85 : 0.75).toColor();

        canvas.drawLine(
          Offset(x1 * size.width, y1 * size.height),
          Offset(x2 * size.width, y2 * size.height),
          Paint()
            ..color = color
            ..strokeWidth = 1.0
            ..strokeCap = StrokeCap.round,
        );
      }
    } else {
      // Interpolate squares from skeleton to full
      final total = state.squares.length;
      for (var i = 0; i < total; i++) {
        final sq = state.squares[i];
        final t = total > 1 ? i / (total - 1) : 0.0;
        final hue = 120 + t * 240;
        final color = HSVColor.fromAHSV(0.8, hue % 360, 0.7, isDark ? 0.85 : 0.75).toColor();

        // bl=sq[0], br=sq[1], tr=sq[2], tl=sq[3]
        final botMidX = (sq[0].$1 + sq[1].$1) / 2;
        final botMidY = (sq[0].$2 + sq[1].$2) / 2;
        final topMidX = (sq[2].$1 + sq[3].$1) / 2;
        final topMidY = (sq[2].$2 + sq[3].$2) / 2;

        final bl = _lerp(botMidX, botMidY, sq[0].$1, sq[0].$2, thickness);
        final br = _lerp(botMidX, botMidY, sq[1].$1, sq[1].$2, thickness);
        final tr = _lerp(topMidX, topMidY, sq[2].$1, sq[2].$2, thickness);
        final tl = _lerp(topMidX, topMidY, sq[3].$1, sq[3].$2, thickness);

        final path = Path()
          ..moveTo(bl.$1 * size.width, bl.$2 * size.height)
          ..lineTo(br.$1 * size.width, br.$2 * size.height)
          ..lineTo(tr.$1 * size.width, tr.$2 * size.height)
          ..lineTo(tl.$1 * size.width, tl.$2 * size.height)
          ..close();

        canvas.drawPath(path, Paint()..color = color);
        if (thickness > 0.3) {
          canvas.drawPath(path, Paint()
            ..color = isDark ? Colors.white12 : Colors.black12
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.5);
        }
      }
    }
  }

  (double, double) _lerp(double ax, double ay, double bx, double by, double t) =>
      (ax + (bx - ax) * t, ay + (by - ay) * t);

  @override bool shouldRepaint(covariant _PythagorasPainter old) => old.state != state;
}

class _Ctrl extends StatefulWidget {
  const _Ctrl({required this.depth, required this.thickness, required this.onChanged});
  final int depth;
  final double thickness;
  final void Function(int depth, double thickness) onChanged;
  @override State<_Ctrl> createState() => _CtrlState();
}
class _CtrlState extends State<_Ctrl> {
  late double _depth;
  late double _thickness;

  @override
  void initState() {
    super.initState();
    _depth = widget.depth.toDouble();
    _thickness = widget.thickness;
  }

  @override
  Widget build(BuildContext context) {
    final ts = Theme.of(context).textTheme.bodySmall;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Row(children: [
        Text('Depth: ${_depth.round()}', style: ts),
        Expanded(child: Slider(value: _depth, min: 0, max: 16, divisions: 16,
          onChanged: (v) => setState(() => _depth = v),
          onChangeEnd: (v) => widget.onChanged(v.round(), _thickness))),
      ]),
      Row(children: [
        Text('Thickness: ${(_thickness * 100).round()}%', style: ts),
        Expanded(child: Slider(value: _thickness, min: 0, max: 1, divisions: 20,
          onChanged: (v) => setState(() => _thickness = v),
          onChangeEnd: (v) => widget.onChanged(_depth.round(), v))),
      ]),
    ]);
  }
}
