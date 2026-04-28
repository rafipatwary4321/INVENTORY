import 'package:flutter/material.dart';

import 'premium_tokens.dart';

/// Premium empty state with soft container and icon halo.
class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_rounded,
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
    final cs = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight > 0 && constraints.maxHeight < 260;
        final ringSize = compact ? 56.0 : 96.0;
        final iconPad = compact ? 10.0 : 18.0;
        final iconSize = compact ? 30.0 : 48.0;
        final outerPad = compact ? 12.0 : 28.0;
        final innerH = compact ? 14.0 : 28.0;
        final innerV = compact ? 18.0 : 36.0;
        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 350),
          tween: Tween(begin: 0.96, end: 1),
          curve: Curves.easeOutCubic,
          builder: (context, scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: Center(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.all(outerPad),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(PremiumTokens.radiusLg),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        cs.surfaceContainerHighest.withValues(alpha: 0.78),
                        cs.surface.withValues(alpha: 0.92),
                      ],
                    ),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.35),
                    ),
                    boxShadow: PremiumTokens.cardShadow(context),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: innerH, vertical: innerV),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: ringSize,
                              height: ringSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    cs.primary.withValues(alpha: 0.2),
                                    cs.primaryContainer.withValues(alpha: 0.04),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.all(iconPad),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: cs.primaryContainer.withValues(alpha: 0.55),
                              ),
                              child: Icon(icon, size: iconSize, color: cs.primary),
                            ),
                          ],
                        ),
                        SizedBox(height: compact ? 10 : 20),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                              ),
                        ),
                        if (subtitle != null) ...[
                          SizedBox(height: compact ? 6 : 10),
                          Text(
                            subtitle!,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  height: 1.45,
                                ),
                          ),
                        ],
                        if (actionLabel != null && onAction != null) ...[
                          SizedBox(height: compact ? 12 : 22),
                          FilledButton.tonalIcon(
                            onPressed: onAction,
                            icon: const Icon(Icons.add_rounded),
                            label: Text(actionLabel!),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
