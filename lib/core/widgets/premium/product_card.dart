import 'package:flutter/material.dart';

import '../../../models/product.dart';
import '../../../core/utils/bdt_formatter.dart';
import 'premium_tokens.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final categoryIcon = _categoryIcon(product.category);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PremiumTokens.radiusMd),
        child: Ink(
          decoration: PremiumTokens.cardDecoration(context),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: cs.primaryContainer.withValues(alpha: 0.6),
                  child: Icon(categoryIcon, color: cs.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${product.category} · ${product.quantity} ${product.unit}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sell ${BdtFormatter.format(product.sellingPrice)}',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: cs.primary,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

IconData _categoryIcon(String category) {
  final value = category.toLowerCase();
  if (value.contains('drink') || value.contains('beverage')) {
    return Icons.local_drink_outlined;
  }
  if (value.contains('food') || value.contains('grocery')) {
    return Icons.fastfood_outlined;
  }
  if (value.contains('electronic') || value.contains('device')) {
    return Icons.devices_other_outlined;
  }
  if (value.contains('cloth') || value.contains('fashion')) {
    return Icons.checkroom_outlined;
  }
  if (value.contains('medicine') || value.contains('health')) {
    return Icons.medical_services_outlined;
  }
  return Icons.inventory_2_outlined;
}
