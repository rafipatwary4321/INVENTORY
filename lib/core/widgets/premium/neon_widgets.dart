import 'dart:ui';

import 'package:flutter/material.dart';

import 'action_card.dart';
import 'empty_state_widget.dart';
import 'glass_stat_card.dart';
import 'glow_button.dart';
import 'premium_app_bar.dart';
import 'premium_glass_card.dart';
import 'premium_text_field.dart';
import 'report_card.dart';

class NeonGlassCard extends PremiumGlassCard {
  const NeonGlassCard({
    super.key,
    required super.child,
    super.padding = const EdgeInsets.all(16),
    super.radius = 24,
    super.borderColor,
  });
}

class NeonStatCard extends GlassStatCard {
  const NeonStatCard({
    super.key,
    required super.title,
    required super.value,
    required super.icon,
    required super.accentColor,
    super.changeLabel,
    super.changeColor,
  });
}

class NeonActionCard extends ActionCard {
  const NeonActionCard({
    super.key,
    required super.icon,
    required super.label,
    super.subtitle,
    super.onTap,
    super.iconColor,
  });
}

class NeonChartCard extends StatelessWidget {
  const NeonChartCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class NeonButton extends GlowButton {
  const NeonButton({
    super.key,
    required super.label,
    super.icon,
    super.onPressed,
  });
}

class NeonTextField extends PremiumTextField {
  const NeonTextField({
    super.key,
    super.controller,
    super.label,
    super.hint,
    super.prefixIcon,
    super.suffixIcon,
    super.obscureText,
    super.keyboardType,
    super.validator,
    super.onChanged,
    super.onSubmitted,
    super.enabled,
    super.maxLines,
  });
}

class NeonBadge extends StatelessWidget {
  const NeonBadge({
    super.key,
    required this.label,
    this.icon,
    this.gradient = const [Color(0xFF22D3EE), Color(0xFF3B82F6)],
  });

  final String label;
  final IconData? icon;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(colors: gradient),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.35),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: Colors.white),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class AnimatedGradientBackground extends StatefulWidget {
  const AnimatedGradientBackground({
    super.key,
    this.child,
  });

  final Widget? child;

  @override
  State<AnimatedGradientBackground> createState() => _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 10),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1 + t, -1),
              end: Alignment(1, 1 - t),
              colors: const [
                Color(0xFF0B0F1A),
                Color(0xFF111827),
                Color(0xFF151B2E),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -70,
                left: -50,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 36, sigmaY: 36),
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0x33A855F7),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -60,
                bottom: -70,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 36, sigmaY: 36),
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0x3322D3EE),
                    ),
                  ),
                ),
              ),
              if (widget.child != null) Positioned.fill(child: widget.child!),
            ],
          ),
        );
      },
    );
  }
}

class NeonBottomNavigation extends StatelessWidget {
  const NeonBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF111827).withValues(alpha: 0.82),
              border: Border.all(color: const Color(0x5522D3EE)),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x4013A7FF),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: NavigationBar(
              backgroundColor: Colors.transparent,
              indicatorColor: const Color(0x44A855F7),
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              destinations: destinations,
            ),
          ),
        ),
      ),
    );
  }
}

class NeonAppBar extends PremiumAppBar {
  const NeonAppBar({
    super.key,
    required super.title,
    super.subtitle,
    super.actions,
    super.leading,
    super.useGradient = false,
    super.bottom,
  });
}

class EmptyStatePremium extends EmptyStateWidget {
  const EmptyStatePremium({
    super.key,
    required super.title,
    super.subtitle,
    super.icon,
    super.actionLabel,
    super.onAction,
  });
}
