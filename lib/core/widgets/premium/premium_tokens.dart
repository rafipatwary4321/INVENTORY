import 'package:flutter/material.dart';

/// Shared layout tokens for premium UI.
abstract final class PremiumTokens {
  static const double radiusSm = 10;
  static const double radiusMd = 16;
  static const double radiusLg = 22;
  static const double radiusXl = 28;

  static List<BoxShadow> cardShadow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ];
  }

  static EdgeInsets pagePadding(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= 1100) return const EdgeInsets.symmetric(horizontal: 48, vertical: 20);
    if (w >= 600) return const EdgeInsets.symmetric(horizontal: 28, vertical: 16);
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
  }
}
