import 'dart:ui';

import 'package:flutter/material.dart';

Widget premiumCard({
  required Widget child,
  EdgeInsets padding = const EdgeInsets.all(16),
  double radius = 20,
  Color? borderColor,
}) {
  return PremiumGlassCard(
    padding: padding,
    radius: radius,
    borderColor: borderColor,
    child: child,
  );
}

class PremiumGlassCard extends StatelessWidget {
  const PremiumGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              colors: [
                const Color(0xFF7C3BFF).withValues(alpha: 0.11),
                const Color(0xFF1A8CFF).withValues(alpha: 0.08),
                const Color(0xFF0EDFA9).withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: borderColor ?? cs.primary.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withValues(alpha: 0.24),
                blurRadius: 30,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: const Color(0xFF7C3BFF).withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 0.8,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
