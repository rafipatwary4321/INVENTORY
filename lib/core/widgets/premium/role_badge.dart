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
    final (icon, label) = switch (role) {
      UserRoleVisual.owner => (Icons.workspace_premium_rounded, 'Owner'),
      UserRoleVisual.admin => (Icons.admin_panel_settings_rounded, 'Admin'),
      UserRoleVisual.staff => (Icons.badge_rounded, 'Staff'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(PremiumTokens.radiusSm),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
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
