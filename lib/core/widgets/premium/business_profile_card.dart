import 'package:flutter/material.dart';

import 'premium_tokens.dart';

/// Compact business / tenant summary for settings.
class BusinessProfileCard extends StatelessWidget {
  const BusinessProfileCard({
    super.key,
    required this.businessName,
    required this.businessId,
    this.planLabel = 'SaaS',
  });

  final String businessName;
  final String businessId;
  final String planLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(PremiumTokens.radiusLg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primaryContainer.withValues(alpha: 0.65),
            cs.secondaryContainer.withValues(alpha: 0.45),
          ],
        ),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
        boxShadow: PremiumTokens.cardShadow(context),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.storefront_rounded, color: cs.primary, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    businessName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    businessId,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontFamily: 'monospace',
                        ),
                  ),
                ],
              ),
            ),
            Chip(
              label: Text(planLabel),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}
