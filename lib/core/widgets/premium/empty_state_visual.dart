import 'package:flutter/material.dart';

import 'empty_state_widget.dart';

class EmptyStateVisual extends StatelessWidget {
  const EmptyStateVisual({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: title,
      subtitle: subtitle,
      icon: icon,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}
