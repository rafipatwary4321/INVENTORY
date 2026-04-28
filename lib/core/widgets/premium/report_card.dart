import 'package:flutter/material.dart';

import 'premium_glass_card.dart';

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
    return SizedBox(
      width: double.infinity,
      child: PremiumGlassCard(
        radius: 20,
        padding: padding,
        child: child,
      ),
    );
  }
}
