import 'package:flutter/material.dart';

class LegendItem {
  const LegendItem(this.color, this.label);
  final Color color;
  final String label;
}

class ColorLegend extends StatelessWidget {
  const ColorLegend({super.key, required this.items});

  final List<LegendItem> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: items.map((item) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: item.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              item.label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
