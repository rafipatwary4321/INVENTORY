import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/empty_state.dart';
import '../../core/utils/bdt_formatter.dart';
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
      appBar: AppBar(title: const Text('Products')),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.productAdd),
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            )
          : null,
      body: products.isEmpty
          ? const EmptyState(
              title: 'No products yet',
              subtitle: 'Add your first product to start tracking stock.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final p = products[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(p.name.isNotEmpty ? p.name[0].toUpperCase() : '?'),
                    ),
                    title: Text(p.name),
                    subtitle: Text(
                      '${p.category} · Qty ${p.quantity} ${p.unit}\n'
                      'Buy ${BdtFormatter.format(p.buyingPrice)} · '
                      'Sell ${BdtFormatter.format(p.sellingPrice)}',
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
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
