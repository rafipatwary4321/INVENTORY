import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/premium/premium_ui.dart';
import '../../providers/auth_provider.dart';
import '../../providers/products_provider.dart';
import '../../routes/app_router.dart';

/// Browse products; admin can add/edit; everyone can open details / QR.
class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductsProvider>().products;
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    return Scaffold(
      appBar: const PremiumAppBar(
        title: 'Products',
        subtitle: 'Inventory',
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.productAdd),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add product'),
            )
          : null,
      body: products.isEmpty
          ? Center(
              child: Padding(
                padding: PremiumTokens.pagePadding(context),
                child: EmptyStateWidget(
                  icon: Icons.inventory_2_rounded,
                  title: 'No products yet',
                  subtitle:
                      'Add your first product to start tracking stock and generating QR labels.',
                  actionLabel: isAdmin ? 'Add product' : null,
                  onAction: isAdmin
                      ? () => Navigator.pushNamed(context, AppRoutes.productAdd)
                      : null,
                ),
              ),
            )
          : ListView(
              padding: PremiumTokens.pagePadding(context),
              children: [
                _ProductsHeroCard(totalProducts: products.length),
                const SizedBox(height: 12),
                ...List.generate(products.length, (i) {
                  final p = products[i];
                  return TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 240 + (i * 18).clamp(0, 220)),
                    tween: Tween(begin: 0, end: 1),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, (1 - value) * 10),
                        child: Opacity(opacity: value, child: child),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ProductCard(
                        product: p,
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.productDetails,
                          arguments: p.id,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}

class _ProductsHeroCard extends StatelessWidget {
  const _ProductsHeroCard({required this.totalProducts});

  final int totalProducts;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(PremiumTokens.radiusLg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primaryContainer.withValues(alpha: 0.82),
            cs.secondaryContainer.withValues(alpha: 0.68),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surface.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.inventory_2_rounded, color: cs.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Product catalog',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onPrimaryContainer,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$totalProducts item(s) ready for stock and POS flow',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onPrimaryContainer.withValues(alpha: 0.84),
                        ),
                  ),
                ],
              ),
            ),
            Icon(Icons.widgets_rounded, color: cs.onPrimaryContainer.withValues(alpha: 0.7)),
          ],
        ),
      ),
    );
  }
}
