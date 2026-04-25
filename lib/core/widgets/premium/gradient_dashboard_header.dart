import 'package:flutter/material.dart';

import 'premium_tokens.dart';
import 'role_badge.dart';

/// Hero-style gradient header for dashboard / home.
class GradientDashboardHeader extends StatelessWidget {
  const GradientDashboardHeader({
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
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(PremiumTokens.radiusLg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary,
            cs.primary.withValues(alpha: 0.88),
            Color.lerp(cs.secondary, cs.primary, 0.25)!,
          ],
        ),
        boxShadow: PremiumTokens.cardShadow(context),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
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
                          letterSpacing: -0.5,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.92),
                          height: 1.35,
                        ),
                  ),
                  if (role != null) ...[
                    const SizedBox(height: 12),
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
