import 'package:flutter/material.dart';

import 'premium_tokens.dart';
import 'role_badge.dart';

class VisualHeroHeader extends StatelessWidget {
  const VisualHeroHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.role,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final UserRoleVisual? role;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(PremiumTokens.radiusLg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary.withValues(alpha: 0.92),
            cs.secondary.withValues(alpha: 0.85),
            cs.tertiary.withValues(alpha: 0.75),
          ],
        ),
        boxShadow: PremiumTokens.cardShadow(context),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.92),
                        ),
                  ),
                  if (role != null) ...[
                    const SizedBox(height: 10),
                    RoleBadge(role: role!),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
