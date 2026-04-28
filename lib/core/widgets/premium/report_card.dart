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
    return Container(
      width: double.infinity,
      decoration: PremiumTokens.cardDecoration(context),
      child: Padding(padding: padding, child: child),
    );
  }
}
