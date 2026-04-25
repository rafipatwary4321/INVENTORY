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
                  icon: Icons.inventory_2_outlined,
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
          : ListView.builder(
              padding: PremiumTokens.pagePadding(context),
              itemCount: products.length,
              itemBuilder: (context, i) {
                final p = products[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ProductCard(
                    product: p,
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.productDetails,
                      arguments: p.id,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
