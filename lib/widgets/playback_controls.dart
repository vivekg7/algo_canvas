import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';
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
        final isLive = controller.mode == AlgorithmMode.live;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLive)
              _buildLiveInfo(context)
            else
              _buildProgressBar(context),
            const SizedBox(height: 4),
            _buildButtons(context),
          ],
        );
      },
    );
  }

  Widget _buildLiveInfo(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final generation = controller.currentIndex;
    final viewingHistory = controller.isViewingLiveHistory;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Generation: $generation',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          if (viewingHistory) ...[
            const SizedBox(width: 8),
            Text(
              '(reviewing)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
        ],
      ),
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
    final isLive = controller.mode == AlgorithmMode.live;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SpeedButton(controller: controller),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.skip_previous_rounded),
          onPressed: isLive
              ? (controller.isViewingLiveHistory || !isPlaying
                  ? controller.stepBackward
                  : null)
              : (controller.currentIndex > 0
                  ? controller.stepBackward
                  : null),
          tooltip: 'Previous step',
        ),
        const SizedBox(width: 4),
        _AnimatedPlayPauseButton(
          isPlaying: isPlaying,
          onPressed: isPlaying ? controller.pause : controller.play,
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.skip_next_rounded),
          onPressed: isLive
              ? (!isPlaying ? controller.stepForward : null)
              : (controller.currentIndex < controller.totalSteps - 1
                  ? controller.stepForward
                  : null),
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

class _AnimatedPlayPauseButton extends StatefulWidget {
  const _AnimatedPlayPauseButton({
    required this.isPlaying,
    required this.onPressed,
  });

  final bool isPlaying;
  final VoidCallback onPressed;

  @override
  State<_AnimatedPlayPauseButton> createState() =>
      _AnimatedPlayPauseButtonState();
}

class _AnimatedPlayPauseButtonState extends State<_AnimatedPlayPauseButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: widget.isPlaying ? 1.0 : 0.0,
    );
  }

  @override
  void didUpdateWidget(_AnimatedPlayPauseButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      widget.isPlaying ? _controller.forward() : _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      icon: AnimatedIcon(
        icon: AnimatedIcons.play_pause,
        progress: _controller,
      ),
      onPressed: widget.onPressed,
      tooltip: widget.isPlaying ? 'Pause' : 'Play',
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
