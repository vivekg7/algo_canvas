import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';

String _modeLabel(AlgorithmMode mode) {
  switch (mode) {
    case AlgorithmMode.batch: return 'Step-by-step';
    case AlgorithmMode.streaming: return 'Streaming';
    case AlgorithmMode.live: return 'Live';
    case AlgorithmMode.interactive: return 'Interactive';
  }
}

Color _modeColor(AlgorithmMode mode, ColorScheme cs) {
  switch (mode) {
    case AlgorithmMode.batch: return cs.tertiaryContainer;
    case AlgorithmMode.streaming: return cs.primaryContainer;
    case AlgorithmMode.live: return cs.errorContainer;
    case AlgorithmMode.interactive: return cs.inversePrimary;
  }
}

Color _modeTextColor(AlgorithmMode mode, ColorScheme cs) {
  switch (mode) {
    case AlgorithmMode.batch: return cs.onTertiaryContainer;
    case AlgorithmMode.streaming: return cs.onPrimaryContainer;
    case AlgorithmMode.live: return cs.onErrorContainer;
    case AlgorithmMode.interactive: return cs.inverseSurface;
  }
}

class AlgorithmCard extends StatelessWidget {
  const AlgorithmCard({
    super.key,
    required this.algorithm,
    required this.onTap,
  });

  final Algorithm algorithm;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      algorithm.category.label,
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _modeColor(algorithm.mode, colorScheme),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _modeLabel(algorithm.mode),
                      style: textTheme.labelSmall?.copyWith(
                        color: _modeTextColor(algorithm.mode, colorScheme),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                algorithm.name,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Flexible(
                child: Text(
                  algorithm.description,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
