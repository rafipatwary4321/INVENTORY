import 'package:flutter/material.dart';

import 'premium_glass_card.dart';

class AIInsightCard extends StatelessWidget {
  const AIInsightCard({
    super.key,
    required this.title,
    required this.body,
    this.icon = Icons.auto_awesome_rounded,
  });

  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PremiumGlassCard(
        radius: 20,
        borderColor: cs.tertiary.withValues(alpha: 0.25),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: cs.tertiary, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    body,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.4,
                          color: cs.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
