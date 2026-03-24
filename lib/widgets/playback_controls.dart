import 'package:flutter/material.dart';
import 'package:algo_canvas/core/visualizer_controller.dart';

class PlaybackControls extends StatelessWidget {
  const PlaybackControls({
    super.key,
    required this.controller,
  });

  final VisualizerController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildProgressBar(context),
            const SizedBox(height: 4),
            _buildButtons(context),
          ],
        );
      },
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final totalSteps = controller.totalSteps;
    final currentIndex = controller.currentIndex;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            '${currentIndex + 1}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          Expanded(
            child: Slider(
              value: totalSteps <= 1 ? 0 : currentIndex.toDouble(),
              min: 0,
              max: totalSteps <= 1 ? 1 : (totalSteps - 1).toDouble(),
              onChanged: totalSteps <= 1
                  ? null
                  : (value) => controller.seekTo(value.round()),
            ),
          ),
          Text(
            '$totalSteps',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons(BuildContext context) {
    final isPlaying = controller.isPlaying;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SpeedButton(controller: controller),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.skip_previous_rounded),
          onPressed: controller.currentIndex > 0
              ? controller.stepBackward
              : null,
          tooltip: 'Previous step',
        ),
        const SizedBox(width: 4),
        IconButton.filled(
          icon: Icon(
            isPlaying
                ? Icons.pause_rounded
                : Icons.play_arrow_rounded,
          ),
          onPressed: isPlaying ? controller.pause : controller.play,
          tooltip: isPlaying ? 'Pause' : 'Play',
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.skip_next_rounded),
          onPressed: controller.currentIndex < controller.totalSteps - 1
              ? controller.stepForward
              : null,
          tooltip: 'Next step',
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.replay_rounded),
          onPressed: controller.reset,
          tooltip: 'Reset',
        ),
      ],
    );
  }
}

class _SpeedButton extends StatelessWidget {
  const _SpeedButton({required this.controller});

  final VisualizerController controller;

  static const _speeds = [0.25, 0.5, 1.0, 2.0, 4.0, 8.0, 16.0];

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<double>(
      initialValue: controller.speed,
      onSelected: controller.setSpeed,
      tooltip: 'Playback speed',
      itemBuilder: (context) => _speeds.map((s) {
        return PopupMenuItem(
          value: s,
          child: Text('${s}x'),
        );
      }).toList(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          '${controller.speed}x',
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
    );
  }
}
