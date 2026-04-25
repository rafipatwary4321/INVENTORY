import 'package:flutter/material.dart';

import 'premium_button.dart';

class ErrorStateWidget extends StatelessWidget {
  const ErrorStateWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.onRetry,
    this.retryLabel = 'Try again',
    this.retryIcon = Icons.refresh_rounded,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onRetry;
  final String retryLabel;
  final IconData retryIcon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 56, color: cs.error),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              PremiumButton(
                label: retryLabel,
                icon: retryIcon,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
