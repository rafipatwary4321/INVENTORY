import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../models/product.dart';
import '../../../core/utils/bdt_formatter.dart';
import 'stock_status_badge.dart';
import 'premium_glass_card.dart';

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
        borderRadius: BorderRadius.circular(20),
        child: PremiumGlassCard(
          radius: 20,
          borderColor: cs.primary.withValues(alpha: 0.2),
          padding: const EdgeInsets.all(14),
          child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: product.imageUrl == null
                        ? Container(
                            color: cs.primaryContainer.withValues(alpha: 0.55),
                            child: Icon(categoryIcon, color: cs.primary, size: 24),
                          )
                        : CachedNetworkImage(
                            imageUrl: product.imageUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              color: cs.primaryContainer.withValues(alpha: 0.55),
                              child: Icon(categoryIcon, color: cs.primary, size: 24),
                            ),
                          ),
                  ),
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
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _SmallChip(
                            icon: categoryIcon,
                            label: product.category,
                          ),
                          StockStatusBadge(
                            isLowStock: product.isLowStock,
                            quantityLabel: '${product.quantity} ${product.unit}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${product.quantity} ${product.unit} • Sell ${BdtFormatter.format(product.sellingPrice)}',
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
    );
  }
}

class _SmallChip extends StatelessWidget {
  const _SmallChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = cs.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: c),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: c,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
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
