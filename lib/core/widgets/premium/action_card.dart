import 'package:flutter/material.dart';

import 'premium_glass_card.dart';

class ActionCard extends StatelessWidget {
  const ActionCard({
    super.key,
    required this.icon,
    required this.label,
    this.subtitle,
    this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final disabled = onTap == null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: PremiumGlassCard(
            radius: 20,
            borderColor: cs.primary.withValues(alpha: 0.18),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (iconColor ?? cs.primary).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: disabled ? cs.onSurfaceVariant : (iconColor ?? cs.primary),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: disabled ? cs.onSurfaceVariant : null,
                            ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: disabled ? cs.outline.withValues(alpha: 0.5) : cs.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
