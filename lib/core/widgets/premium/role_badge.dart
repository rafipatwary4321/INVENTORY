import 'package:flutter/material.dart';

import '../../../models/app_user.dart';
import 'premium_tokens.dart';

extension AppUserRoleVisual on AppUser {
  UserRoleVisual get roleVisual => role.toVisual();
}

enum UserRoleVisual { owner, admin, staff }

extension UserRoleVisualX on UserRole {
  UserRoleVisual toVisual() {
    switch (this) {
      case UserRole.owner:
        return UserRoleVisual.owner;
      case UserRole.admin:
        return UserRoleVisual.admin;
      case UserRole.staff:
        return UserRoleVisual.staff;
    }
  }
}

class RoleBadge extends StatelessWidget {
  const RoleBadge({super.key, required this.role});

  final UserRoleVisual role;

  @override
  Widget build(BuildContext context) {
    final (icon, label, accent) = switch (role) {
      UserRoleVisual.owner => (
          Icons.workspace_premium_rounded,
          'Owner',
          const Color(0xFFA855F7),
        ),
      UserRoleVisual.admin => (
          Icons.admin_panel_settings_rounded,
          'Admin',
          const Color(0xFF22D3EE),
        ),
      UserRoleVisual.staff => (
          Icons.badge_rounded,
          'Staff',
          const Color(0xFF3B82F6),
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(PremiumTokens.radiusSm),
        border: Border.all(color: accent.withValues(alpha: 0.48)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.3),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
