import 'dart:math';
import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/algorithm_category.dart';
import 'package:algo_canvas/core/algorithm_state.dart';

/// Simplified Stable Fluids (Jos Stam) on a 2D grid.
/// Density field advected by a velocity field with diffusion and projection.

class FluidState extends AlgorithmState {
  const FluidState({
    required this.density,
    required this.n,
    required this.step,
    required super.description,
  });

  /// Flattened (n+2)x(n+2) density grid (includes boundary cells).
  final List<double> density;
  final int n;
  final int step;
}

class FluidSimulationAlgorithm extends Algorithm {
  int _gridSize = 64;
  double _diffusion = 0.0001;
  double _viscosity = 0.0;

  @override
  String get name => 'Fluid Simulation';

  @override
  String get description =>
      'Stable Fluids method: density advected by a velocity field with diffusion.';

  @override
  AlgorithmCategory get category => AlgorithmCategory.physicsSimulation;

  @override
  AlgorithmMode get mode => AlgorithmMode.live;

  @override
  AlgorithmState createInitialState() {
    final n = _gridSize;
    final size = (n + 2) * (n + 2);
    final density = List<double>.filled(size, 0);
    final vx = List<double>.filled(size, 0);
    final vy = List<double>.filled(size, 0);

    // Initial density blobs and velocity vortices
    final random = Random(42);
    for (var k = 0; k < 4; k++) {
      final cx = (n * 0.2 + random.nextDouble() * n * 0.6).round();
      final cy = (n * 0.2 + random.nextDouble() * n * 0.6).round();
      final radius = n * 0.08;

      for (var i = 1; i <= n; i++) {
        for (var j = 1; j <= n; j++) {
          final dx = i - cx;
          final dy = j - cy;
          final dist = sqrt(dx * dx + dy * dy);
          if (dist < radius) {
            final falloff = 1.0 - dist / radius;
            density[_ix(i, j, n)] += falloff * 2.0;
            // Rotational velocity around blob center
            vx[_ix(i, j, n)] += -dy / radius * 0.15;
            vy[_ix(i, j, n)] += dx / radius * 0.15;
          }
        }
      }
    }

    return _FluidInternalState(
      density: density,
      vx: vx,
      vy: vy,
      n: n,
      step: 0,
      diffusion: _diffusion,
      viscosity: _viscosity,
      description: 'Step 0: fluid initialized',
    );
  }

  @override
  AlgorithmState? tick(AlgorithmState current) {
    final s = current as _FluidInternalState;
    final n = s.n;
    final dt = 0.1;
    final size = (n + 2) * (n + 2);

    var d = List<double>.of(s.density);
    var vx = List<double>.of(s.vx);
    var vy = List<double>.of(s.vy);

    // Add continuous sources to keep things interesting
    final step = s.step + 1;
    _addSources(d, vx, vy, n, step, dt);

    // Velocity step
    if (s.viscosity > 0) {
      vx = _diffuse(1, vx, s.viscosity, dt, n);
      vy = _diffuse(2, vy, s.viscosity, dt, n);
    }
    final (pvx, pvy) = _project(vx, vy, n);
    vx = pvx;
    vy = pvy;
    vx = _advect(1, vx, pvx, pvy, dt, n);
    vy = _advect(2, vy, pvx, pvy, dt, n);
    final (pvx2, pvy2) = _project(vx, vy, n);
    vx = pvx2;
    vy = pvy2;

    // Density step
    if (s.diffusion > 0) {
      d = _diffuse(0, d, s.diffusion, dt, n);
    }
    d = _advect(0, d, vx, vy, dt, n);

    // Slight decay to prevent unbounded growth
    for (var i = 0; i < size; i++) {
      d[i] *= 0.995;
    }

    return _FluidInternalState(
      density: d,
      vx: vx,
      vy: vy,
      n: n,
      step: step,
      diffusion: s.diffusion,
      viscosity: s.viscosity,
      description: 'Step $step',
    );
  }

  void _addSources(
      List<double> d, List<double> vx, List<double> vy, int n, int step, double dt) {
    // Rotating source points
    final t = step * 0.02;
    final sources = [
      (0.3 + 0.1 * cos(t), 0.5 + 0.1 * sin(t), cos(t * 2), sin(t * 2)),
      (0.7 + 0.1 * cos(t + pi), 0.5 + 0.1 * sin(t + pi), -cos(t * 2), -sin(t * 2)),
    ];

    for (final (sx, sy, svx, svy) in sources) {
      final ci = (sx * n).round().clamp(1, n);
      final cj = (sy * n).round().clamp(1, n);
      for (var di = -2; di <= 2; di++) {
        for (var dj = -2; dj <= 2; dj++) {
          final i = (ci + di).clamp(1, n);
          final j = (cj + dj).clamp(1, n);
          d[_ix(i, j, n)] += dt * 5.0;
          vx[_ix(i, j, n)] += dt * svx * 2.0;
          vy[_ix(i, j, n)] += dt * svy * 2.0;
        }
      }
    }
  }

  static int _ix(int i, int j, int n) => i + (n + 2) * j;

  List<double> _diffuse(
      int b, List<double> x, double diff, double dt, int n) {
    final a = dt * diff * n * n;
    final x0 = List<double>.of(x);
    final result = List<double>.of(x);

    for (var iter = 0; iter < 4; iter++) {
      for (var i = 1; i <= n; i++) {
        for (var j = 1; j <= n; j++) {
          result[_ix(i, j, n)] = (x0[_ix(i, j, n)] +
                  a *
                      (result[_ix(i - 1, j, n)] +
                          result[_ix(i + 1, j, n)] +
                          result[_ix(i, j - 1, n)] +
                          result[_ix(i, j + 1, n)])) /
              (1 + 4 * a);
        }
      }
      _setBoundary(b, result, n);
    }
    return result;
  }

  List<double> _advect(
      int b, List<double> d, List<double> vx, List<double> vy, double dt, int n) {
    final d0 = List<double>.of(d);
    final result = List<double>.filled(d.length, 0);
    final dt0 = dt * n;

    for (var i = 1; i <= n; i++) {
      for (var j = 1; j <= n; j++) {
        var x = i - dt0 * vx[_ix(i, j, n)];
        var y = j - dt0 * vy[_ix(i, j, n)];

        x = x.clamp(0.5, n + 0.5);
        y = y.clamp(0.5, n + 0.5);

        final i0 = x.floor();
        final i1 = i0 + 1;
        final j0 = y.floor();
        final j1 = j0 + 1;
        final s1 = x - i0;
        final s0 = 1 - s1;
        final t1 = y - j0;
        final t0 = 1 - t1;

        result[_ix(i, j, n)] = s0 * (t0 * d0[_ix(i0, j0, n)] + t1 * d0[_ix(i0, j1, n)]) +
            s1 * (t0 * d0[_ix(i1, j0, n)] + t1 * d0[_ix(i1, j1, n)]);
      }
    }
    _setBoundary(b, result, n);
    return result;
  }

  (List<double>, List<double>) _project(
      List<double> vx, List<double> vy, int n) {
    final rvx = List<double>.of(vx);
    final rvy = List<double>.of(vy);
    final div = List<double>.filled(vx.length, 0);
    final p = List<double>.filled(vx.length, 0);
    final h = 1.0 / n;

    for (var i = 1; i <= n; i++) {
      for (var j = 1; j <= n; j++) {
        div[_ix(i, j, n)] = -0.5 *
            h *
            (rvx[_ix(i + 1, j, n)] -
                rvx[_ix(i - 1, j, n)] +
                rvy[_ix(i, j + 1, n)] -
                rvy[_ix(i, j - 1, n)]);
        p[_ix(i, j, n)] = 0;
      }
    }
    _setBoundary(0, div, n);
    _setBoundary(0, p, n);

    for (var iter = 0; iter < 4; iter++) {
      for (var i = 1; i <= n; i++) {
        for (var j = 1; j <= n; j++) {
          p[_ix(i, j, n)] = (div[_ix(i, j, n)] +
                  p[_ix(i - 1, j, n)] +
                  p[_ix(i + 1, j, n)] +
                  p[_ix(i, j - 1, n)] +
                  p[_ix(i, j + 1, n)]) /
              4;
        }
      }
      _setBoundary(0, p, n);
    }

    for (var i = 1; i <= n; i++) {
      for (var j = 1; j <= n; j++) {
        rvx[_ix(i, j, n)] -= 0.5 * n * (p[_ix(i + 1, j, n)] - p[_ix(i - 1, j, n)]);
        rvy[_ix(i, j, n)] -= 0.5 * n * (p[_ix(i, j + 1, n)] - p[_ix(i, j - 1, n)]);
      }
    }
    _setBoundary(1, rvx, n);
    _setBoundary(2, rvy, n);

    return (rvx, rvy);
  }

  void _setBoundary(int b, List<double> x, int n) {
    for (var i = 1; i <= n; i++) {
      x[_ix(0, i, n)] = b == 1 ? -x[_ix(1, i, n)] : x[_ix(1, i, n)];
      x[_ix(n + 1, i, n)] = b == 1 ? -x[_ix(n, i, n)] : x[_ix(n, i, n)];
      x[_ix(i, 0, n)] = b == 2 ? -x[_ix(i, 1, n)] : x[_ix(i, 1, n)];
      x[_ix(i, n + 1, n)] = b == 2 ? -x[_ix(i, n, n)] : x[_ix(i, n, n)];
    }
    x[_ix(0, 0, n)] = 0.5 * (x[_ix(1, 0, n)] + x[_ix(0, 1, n)]);
    x[_ix(0, n + 1, n)] = 0.5 * (x[_ix(1, n + 1, n)] + x[_ix(0, n, n)]);
    x[_ix(n + 1, 0, n)] = 0.5 * (x[_ix(n, 0, n)] + x[_ix(n + 1, 1, n)]);
    x[_ix(n + 1, n + 1, n)] = 0.5 * (x[_ix(n, n + 1, n)] + x[_ix(n + 1, n, n)]);
  }

  @override
  CustomPainter createPainter(AlgorithmState state, BuildContext context) {
    return _FluidPainter(
      state: state as FluidState,
      brightness: Theme.of(context).brightness,
    );
  }

  @override
  Widget? buildControls({required VoidCallback onChanged}) {
    return _Controls(
      gridSize: _gridSize,
      diffusion: _diffusion,
      viscosity: _viscosity,
      onChanged: (size, diff, visc) {
        _gridSize = size;
        _diffusion = diff;
        _viscosity = visc;
        onChanged();
      },
    );
  }
}

class _FluidInternalState extends FluidState {
  const _FluidInternalState({
    required super.density,
    required this.vx,
    required this.vy,
    required super.n,
    required super.step,
    required this.diffusion,
    required this.viscosity,
    required super.description,
  });

  final List<double> vx;
  final List<double> vy;
  final double diffusion;
  final double viscosity;
}

class _FluidPainter extends CustomPainter {
  _FluidPainter({required this.state, required this.brightness});

  final FluidState state;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final n = state.n;
    final cellW = size.width / n;
    final cellH = size.height / n;
    final isDark = brightness == Brightness.dark;

    // Background
    final bgColor = isDark ? const Color(0xFF0A0A1A) : const Color(0xFF0A0A2A);
    canvas.drawRect(Offset.zero & size, Paint()..color = bgColor);

    for (var i = 1; i <= n; i++) {
      for (var j = 1; j <= n; j++) {
        final d = state.density[FluidSimulationAlgorithm._ix(i, j, n)]
            .clamp(0.0, 3.0);
        if (d < 0.01) continue;

        final t = (d / 3.0).clamp(0.0, 1.0);

        // Heatmap: black → blue → cyan → white
        Color color;
        if (t < 0.33) {
          final u = t / 0.33;
          color = Color.lerp(
            const Color(0xFF000020),
            const Color(0xFF0066FF),
            u,
          )!;
        } else if (t < 0.66) {
          final u = (t - 0.33) / 0.33;
          color = Color.lerp(
            const Color(0xFF0066FF),
            const Color(0xFF00DDFF),
            u,
          )!;
        } else {
          final u = (t - 0.66) / 0.34;
          color = Color.lerp(
            const Color(0xFF00DDFF),
            const Color(0xFFFFFFFF),
            u,
          )!;
        }

        canvas.drawRect(
          Rect.fromLTWH(
            (i - 1) * cellW,
            (j - 1) * cellH,
            cellW + 0.5,
            cellH + 0.5,
          ),
          Paint()..color = color,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FluidPainter oldDelegate) {
    return oldDelegate.state != state;
  }
}

class _Controls extends StatefulWidget {
  const _Controls({
    required this.gridSize,
    required this.diffusion,
    required this.viscosity,
    required this.onChanged,
  });

  final int gridSize;
  final double diffusion;
  final double viscosity;
  final void Function(int size, double diff, double visc) onChanged;

  @override
  State<_Controls> createState() => _ControlsState();
}

class _ControlsState extends State<_Controls> {
  late double _size;
  late double _diff;
  late double _visc;

  @override
  void initState() {
    super.initState();
    _size = widget.gridSize.toDouble();
    _diff = widget.diffusion;
    _visc = widget.viscosity;
  }

  void _emit() => widget.onChanged(_size.round(), _diff, _visc);

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodySmall;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text('Grid: ${_size.round()}', style: textStyle),
            Expanded(
              child: Slider(
                value: _size, min: 32, max: 128, divisions: 12,
                onChanged: (v) => setState(() => _size = v),
                onChangeEnd: (_) => _emit(),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Text('Diffusion', style: textStyle),
            Expanded(
              child: Slider(
                value: _diff, min: 0, max: 0.001, divisions: 20,
                onChanged: (v) => setState(() => _diff = v),
                onChangeEnd: (_) => _emit(),
              ),
            ),
            Text('Viscosity', style: textStyle),
            Expanded(
              child: Slider(
                value: _visc, min: 0, max: 0.001, divisions: 20,
                onChanged: (v) => setState(() => _visc = v),
                onChangeEnd: (_) => _emit(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
