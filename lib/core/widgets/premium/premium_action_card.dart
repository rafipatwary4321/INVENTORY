import 'package:flutter/material.dart';

import 'action_card.dart';

class PremiumActionCard extends StatelessWidget {
  const PremiumActionCard({
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
    return ActionCard(
      icon: icon,
      label: label,
      subtitle: subtitle,
      onTap: onTap,
      iconColor: iconColor,
    );
  }
}
