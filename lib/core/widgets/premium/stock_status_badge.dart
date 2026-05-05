import 'package:flutter/material.dart';

class StockStatusBadge extends StatelessWidget {
  const StockStatusBadge({
    super.key,
    required this.isLowStock,
    required this.quantityLabel,
  });

  final bool isLowStock;
  final String quantityLabel;

  @override
  Widget build(BuildContext context) {
    final color = isLowStock ? const Color(0xFFF97316) : const Color(0xFF22D3EE);
    final icon =
        isLowStock ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded;
    final label = isLowStock ? 'Low stock' : 'In stock';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            '$label · $quantityLabel',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
