import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/bdt_formatter.dart';
import '../../core/utils/error_handler.dart';
import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/products_provider.dart';
import '../../routes/app_router.dart';
import '../../services/product_service.dart';

/// Product detail with actions: QR, stock in, sell, edit/delete (admin).
class ProductDetailsScreen extends StatelessWidget {
  const ProductDetailsScreen({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context) {
    final product = context.watch<ProductsProvider>().byId(productId);
    final isAdmin =
        context.watch<AuthProvider>().appUser?.role == UserRole.admin;

    if (product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product')),
        body: const Center(child: Text('Product not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => Navigator.pushNamed(
                context,
                AppRoutes.productEdit,
                arguments: product.id,
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: product.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: product.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          const Center(child: CircularProgressIndicator()),
                      errorWidget: (_, __, ___) => const ColoredBox(
                        color: Color(0xFFE0E0E0),
                        child: Icon(Icons.image_not_supported, size: 48),
                      ),
                    )
                  : const ColoredBox(
                      color: Color(0xFFE0E0E0),
                      child: Icon(Icons.inventory_2_outlined, size: 48),
                    ),
            ),
          ),
          if (product.isLowStock)
            Card(
              color: Colors.orange.shade50,
              child: ListTile(
                leading: const Icon(Icons.warning_amber_rounded),
                title: Text(
                  'Low stock (≤ ${AppConstants.lowStockThreshold} ${product.unit})',
                ),
              ),
            ),
          const SizedBox(height: 16),
          _DetailRow('Category', product.category),
          _DetailRow('Buying price', BdtFormatter.format(product.buyingPrice)),
          _DetailRow('Selling price', BdtFormatter.format(product.sellingPrice)),
          _DetailRow('Quantity', '${product.quantity} ${product.unit}'),
          _DetailRow('Stock value (cost)', BdtFormatter.format(product.stockValue)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.qrGenerate,
              arguments: product.id,
            ),
            icon: const Icon(Icons.qr_code_2),
            label: const Text('Show QR code'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.stockIn,
              arguments: product.id,
            ),
            icon: const Icon(Icons.add_box_outlined),
            label: const Text('Stock in'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.sell,
              arguments: product.id,
            ),
            icon: const Icon(Icons.sell_outlined),
            label: const Text('Sell this product'),
          ),
          if (isAdmin) ...[
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete product?'),
                    content: const Text('This cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (ok != true || !context.mounted) return;
                try {
                  await context.read<ProductService>().deleteProduct(product.id);
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) ErrorHandler.showSnack(context, e);
                }
              },
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              label: const Text('Delete product', style: TextStyle(color: Colors.red)),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}
