import 'package:flutter/material.dart';

import 'premium_tokens.dart';

/// App bar with optional gradient background and soft elevation.
class PremiumAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PremiumAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
    this.useGradient = false,
    this.bottom,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;
  final bool useGradient;
  final PreferredSizeWidget? bottom;

  /// Two-line title + subtitle need more than [kToolbarHeight] to avoid overflow.
  double get _toolbarBodyHeight =>
      subtitle != null && subtitle!.trim().isNotEmpty ? 72.0 : kToolbarHeight;

  @override
  Size get preferredSize => Size.fromHeight(
        _toolbarBodyHeight + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        cs.primary,
        cs.primary.withValues(alpha: 0.82),
        Color.lerp(cs.tertiary, cs.primary, 0.35)!,
      ],
    );

    return Material(
      elevation: 0,
      color: useGradient ? Colors.transparent : cs.surface,
      child: Container(
        decoration: useGradient
            ? BoxDecoration(gradient: gradient)
            : BoxDecoration(
                color: cs.surface,
                boxShadow: PremiumTokens.cardShadow(context),
              ),
        child: SafeArea(
          bottom: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: _toolbarBodyHeight,
                child: NavigationToolbar(
                  leading: leading ??
                      (Navigator.canPop(context)
                          ? IconButton(
                              icon: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: useGradient ? Colors.white : null,
                                size: 20,
                              ),
                              onPressed: () => Navigator.maybePop(context),
                            )
                          : null),
                  middle: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: useGradient ? Colors.white : cs.onSurface,
                            ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: useGradient
                                    ? Colors.white.withValues(alpha: 0.88)
                                    : cs.onSurfaceVariant,
                              ),
                        ),
                    ],
                  ),
                  trailing: actions != null && actions!.isNotEmpty
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: actions!
                              .map(
                                (w) => Theme(
                                  data: Theme.of(context).copyWith(
                                    iconTheme: IconThemeData(
                                      color: useGradient ? Colors.white : cs.onSurface,
                                    ),
                                  ),
                                  child: w,
                                ),
                              )
                              .toList(),
                        )
                      : null,
                  centerMiddle: false,
                ),
              ),
              if (bottom != null) bottom!,
            ],
          ),
        ),
      ),
    );
  }
}
