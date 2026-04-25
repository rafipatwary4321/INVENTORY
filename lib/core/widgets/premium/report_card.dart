import 'package:flutter/material.dart';

import 'premium_tokens.dart';

class ReportCard extends StatelessWidget {
  const ReportCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(PremiumTokens.radiusMd),
        color: cs.surface,
        boxShadow: PremiumTokens.cardShadow(context),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
