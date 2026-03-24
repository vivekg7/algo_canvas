import 'package:flutter/material.dart';
import 'package:algo_canvas/core/algorithm.dart';

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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              const SizedBox(height: 12),
              Text(
                algorithm.name,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                algorithm.description,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
