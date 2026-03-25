import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
import 'package:algo_canvas/core/visualizer_controller.dart';
import 'package:algo_canvas/widgets/color_legend.dart';
import 'package:algo_canvas/widgets/playback_controls.dart';

class VisualizerScreen extends StatefulWidget {
  const VisualizerScreen({super.key, required this.algorithm});

  final Algorithm algorithm;

  @override
  State<VisualizerScreen> createState() => _VisualizerScreenState();
}

class _VisualizerScreenState extends State<VisualizerScreen> {
  late VisualizerController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = VisualizerController(widget.algorithm);
    _initialize();
  }

  Future<void> _initialize() async {
    await _controller.initialize();
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _regenerate() async {
    setState(() => _loading = true);
    _controller.dispose();
    _controller = VisualizerController(widget.algorithm);
    await _controller.initialize();
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.algorithm.name),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Step description
                ListenableBuilder(
                  listenable: _controller,
                  builder: (context, _) {
                    final description =
                        _controller.currentState?.description ?? '';
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
                // Canvas
                Expanded(
                  child: ListenableBuilder(
                    listenable: _controller,
                    builder: (context, _) {
                      final state = _controller.currentState;
                      if (state == null) {
                        return const Center(child: Text('No steps generated.'));
                      }
                      final canvas = Padding(
                        padding: const EdgeInsets.all(16),
                        child: ClipRect(
                          child: CustomPaint(
                            painter: widget.algorithm.createPainter(state, context),
                            size: Size.infinite,
                          ),
                        ),
                      );
                      if (_controller.mode != AlgorithmMode.interactive) {
                        return canvas;
                      }
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onPanStart: (details) {
                              final norm = _normalizePosition(
                                  details.localPosition, constraints, 16);
                              _controller.handleInteractionStart(norm);
                            },
                            onPanUpdate: (details) {
                              final norm = _normalizePosition(
                                  details.localPosition, constraints, 16);
                              _controller.handleInteractionUpdate(norm);
                            },
                            onPanEnd: (_) {
                              _controller.handleInteractionEnd();
                            },
                            child: canvas,
                          );
                        },
                      );
                    },
                  ),
                ),
                // Color legend
                if (widget.algorithm.buildLegend(context)
                    case final legendItems?)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ColorLegend(items: legendItems),
                  ),
                // Algorithm-specific controls
                if (widget.algorithm.buildControls(onChanged: _regenerate)
                    case final controls?)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: controls,
                  ),
                // Playback controls (hidden for interactive mode)
                if (_controller.mode != AlgorithmMode.interactive)
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: PlaybackControls(controller: _controller),
                    ),
                  ),
              ],
            ),
    );
  }

  /// Convert a local pixel position to normalized 0..1 coordinates
  /// accounting for padding.
  Offset _normalizePosition(
      Offset local, BoxConstraints constraints, double padding) {
    final x = ((local.dx - padding) / (constraints.maxWidth - padding * 2))
        .clamp(0.0, 1.0);
    final y = ((local.dy - padding) / (constraints.maxHeight - padding * 2))
        .clamp(0.0, 1.0);
    return Offset(x, y);
  }
}
