import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/utils/bdt_formatter.dart';
import '../../../models/product.dart';
import 'premium_glass_card.dart';

class ProductVisualCard extends StatelessWidget {
  const ProductVisualCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onView,
    this.onEdit,
    this.onQr,
  });

  final Product product;
  final VoidCallback onTap;
  final VoidCallback onView;
  final VoidCallback? onEdit;
  final VoidCallback? onQr;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final lowStock = product.isLowStock;
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 180),
      tween: Tween(begin: 0.985, end: 1),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: (lowStock ? Colors.orangeAccent : cs.primary).withValues(alpha: 0.28),
                  blurRadius: 18,
                  spreadRadius: 0.3,
                ),
              ],
            ),
            child: PremiumGlassCard(
              radius: 28,
              borderColor: lowStock
                  ? Colors.orangeAccent.withValues(alpha: 0.65)
                  : const Color(0xFF19C7FF).withValues(alpha: 0.38),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          width: 62,
                          height: 62,
                          child: product.imageUrl == null
                              ? _placeholder(cs)
                              : CachedNetworkImage(
                                  imageUrl: product.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => _placeholder(cs),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                _chip(
                                  label: product.category,
                                  icon: Icons.category_outlined,
                                  color: const Color(0xFF6D45FF),
                                ),
                                const SizedBox(width: 6),
                                _chip(
                                  label: '${product.quantity} ${product.unit}',
                                  icon: Icons.inventory_2_outlined,
                                  color: lowStock ? Colors.orange : const Color(0xFF18CFA4),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (lowStock)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Low stock warning',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Colors.orangeAccent,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: _priceTile(
                          context,
                          label: 'Buy',
                          value: BdtFormatter.format(product.buyingPrice),
                          color: const Color(0xFF18CFA4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _priceTile(
                          context,
                          label: 'Sell',
                          value: BdtFormatter.format(product.sellingPrice),
                          color: const Color(0xFF19B8FF),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _quickAction(context, icon: Icons.visibility_outlined, label: 'View', onTap: onView),
                      _quickAction(
                        context,
                        icon: Icons.edit_outlined,
                        label: 'Edit',
                        onTap: onEdit,
                      ),
                      _quickAction(
                        context,
                        icon: Icons.qr_code_2_rounded,
                        label: 'QR',
                        onTap: onQr,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primary.withValues(alpha: 0.45),
            cs.secondary.withValues(alpha: 0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 30),
    );
  }

  Widget _chip({
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _priceTile(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }

  Widget _quickAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white.withValues(alpha: onTap == null ? 0.06 : 0.12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: onTap == null ? Colors.white38 : Colors.white),
            const SizedBox(width: 5),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: onTap == null ? Colors.white38 : Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
