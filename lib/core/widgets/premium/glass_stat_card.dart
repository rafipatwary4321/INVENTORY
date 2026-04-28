import 'package:flutter/material.dart';

import 'premium_glass_card.dart';

class GlassStatCard extends StatelessWidget {
  const GlassStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
    this.changeLabel,
    this.changeColor,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;
  final String? changeLabel;
  final Color? changeColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return PremiumGlassCard(
      radius: 20,
      borderColor: accentColor.withValues(alpha: 0.25),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          if (changeLabel != null) ...[
            const SizedBox(height: 4),
            Text(
              changeLabel!,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: changeColor ?? accentColor,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
