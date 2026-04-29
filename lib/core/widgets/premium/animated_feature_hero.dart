import 'dart:math' as math;

import 'package:flutter/material.dart';

class AnimatedFeatureHero extends StatefulWidget {
  const AnimatedFeatureHero({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.animationType,
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final FeatureHeroAnimationType animationType;
  final bool compact;

  @override
  State<AnimatedFeatureHero> createState() => _AnimatedFeatureHeroState();
}

enum FeatureHeroAnimationType {
  warehouse,
  products,
  scanner,
  pos,
  reports,
  ai,
  settings,
}

class _AnimatedFeatureHeroState extends State<AnimatedFeatureHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 7200),
  )..repeat();
  bool _entered = false;
  bool _hovered = false;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _entered = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.gradientColors.length >= 2
        ? widget.gradientColors
        : const [Color(0xFF7A37FF), Color(0xFF13A7FF)];
    final borderRadius = BorderRadius.circular(widget.compact ? 20 : 24);
    final card = Container(
      margin: const EdgeInsets.only(bottom: 12),
      constraints: BoxConstraints(minHeight: widget.compact ? 84 : 106),
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.16),
                      Colors.black.withValues(alpha: 0.28),
                      Colors.black.withValues(alpha: 0.52),
                    ],
                    stops: const [0, 0.45, 1],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return _AnimatedScene(
                    t: _controller.value,
                    animationType: widget.animationType,
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                widget.compact ? 12 : 16,
                widget.compact ? 12 : 16,
                widget.compact ? 12 : 16,
                widget.compact ? 12 : 16,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: colors.last.withValues(alpha: 0.3),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Icon(widget.icon, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.subtitle,
                          maxLines: widget.compact ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.92),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    final scale = _pressed
        ? 0.97
        : _hovered
            ? 0.99
            : 1.0;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: Listener(
        onPointerDown: (_) => setState(() => _pressed = true),
        onPointerUp: (_) => setState(() => _pressed = false),
        onPointerCancel: (_) => setState(() => _pressed = false),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
          opacity: _entered ? 1 : 0,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            offset: _entered ? Offset.zero : const Offset(0, 0.035),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOut,
              scale: scale,
              child: card,
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedScene extends StatelessWidget {
  const _AnimatedScene({
    required this.t,
    required this.animationType,
  });

  final double t;
  final FeatureHeroAnimationType animationType;

  @override
  Widget build(BuildContext context) {
    final pulse = (math.sin(t * math.pi * 2) + 1) / 2;
    final bob = math.sin(t * math.pi * 2) * 1.8;
    final gentle = math.cos(t * math.pi * 2) * 1.4;
    return Stack(
      children: [
        Positioned(
          right: 12 + gentle,
          top: 24 + bob,
          child: _GlowOrb(size: 54, opacity: 0.25 + pulse * 0.2),
        ),
        Positioned(
          right: 96 - gentle,
          bottom: 14 + bob,
          child: _GlowOrb(size: 34, opacity: 0.16 + pulse * 0.15),
        ),
        ..._itemsFor(animationType, pulse, bob, gentle),
      ],
    );
  }
}

List<Widget> _itemsFor(
  FeatureHeroAnimationType type,
  double pulse,
  double bob,
  double gentle,
) {
  switch (type) {
    case FeatureHeroAnimationType.warehouse:
      return [
        _sceneIcon(Icons.warehouse_rounded, left: 12, bottom: 16, size: 64),
        _sceneIcon(Icons.inventory_2_rounded, left: 84 + gentle, bottom: 18 + bob, size: 28),
        _sceneIcon(Icons.local_shipping_rounded, left: 130, bottom: 20 - bob, size: 30),
      ];
    case FeatureHeroAnimationType.products:
      return [
        _sceneIcon(Icons.storefront_rounded, left: 12, bottom: 14, size: 58),
        _sceneIcon(Icons.inventory_2_rounded, left: 72, bottom: 18 + bob, size: 30),
        _sceneIcon(Icons.widgets_rounded, left: 118 + gentle, bottom: 22, size: 24),
      ];
    case FeatureHeroAnimationType.scanner:
      return [
        _sceneIcon(Icons.qr_code_scanner_rounded, left: 12, bottom: 14, size: 62),
        _sceneIcon(Icons.qr_code_2_rounded, left: 86 + gentle, bottom: 20 + bob, size: 26),
        _sceneIcon(Icons.view_in_ar_outlined, left: 130, bottom: 20 - bob, size: 24),
      ];
    case FeatureHeroAnimationType.pos:
      return [
        _sceneIcon(Icons.point_of_sale_rounded, left: 12, bottom: 14, size: 62),
        _sceneIcon(Icons.shopping_cart_rounded, left: 88 + gentle, bottom: 16 + bob, size: 30),
        _sceneIcon(Icons.receipt_long_rounded, left: 132, bottom: 24 - bob, size: 24),
      ];
    case FeatureHeroAnimationType.reports:
      return [
        _sceneIcon(Icons.bar_chart_rounded, left: 14, bottom: 16, size: 58),
        _sceneIcon(Icons.show_chart_rounded, left: 78 + gentle, bottom: 18 + bob, size: 30),
        _sceneIcon(Icons.pie_chart_rounded, left: 122, bottom: 22 - bob, size: 24),
      ];
    case FeatureHeroAnimationType.ai:
      return [
        _sceneIcon(Icons.smart_toy_rounded, left: 12, bottom: 14, size: 62),
        _sceneIcon(Icons.auto_awesome_rounded, left: 90 + gentle, bottom: 24 + bob, size: 26),
        _sceneIcon(Icons.inventory_2_outlined, left: 132, bottom: 18 - bob, size: 24),
      ];
    case FeatureHeroAnimationType.settings:
      return [
        _sceneIcon(Icons.manage_accounts_rounded, left: 12, bottom: 14, size: 62),
        _sceneIcon(Icons.business_center_rounded, left: 88 + gentle, bottom: 22 + bob, size: 27),
        _sceneIcon(Icons.tune_rounded, left: 132, bottom: 20 - bob, size: 24),
      ];
  }
}

Widget _sceneIcon(
  IconData icon, {
  required double left,
  required double bottom,
  required double size,
}) {
  return Positioned(
    left: left,
    bottom: bottom,
    child: Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.18),
            blurRadius: 8,
          ),
        ],
      ),
      child: Opacity(
        opacity: 0.84,
        child: Icon(icon, size: size * 0.88, color: Colors.white),
      ),
    ),
  );
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}
