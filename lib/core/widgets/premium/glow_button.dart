import 'package:flutter/material.dart';

class GlowButton extends StatelessWidget {
  const GlowButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: onPressed == null
            ? null
            : [
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.35),
                  blurRadius: 18,
                  spreadRadius: 0.5,
                ),
              ],
      ),
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: icon == null ? const SizedBox.shrink() : Icon(icon),
        label: Text(label),
      ),
    );
  }
}
