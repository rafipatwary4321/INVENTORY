import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/bdt_formatter.dart';
import '../../core/utils/error_handler.dart';
import '../../core/widgets/premium/premium_ui.dart';
import '../../core/widgets/product_qr_card.dart';
import '../../providers/auth_provider.dart';
import '../../providers/products_provider.dart';
import '../../routes/app_router.dart';
import '../../services/product_service.dart';
import 'product_qr_scan_actions.dart';

/// Product detail with embedded QR, scan actions, stock in, sell, edit/delete (admin).
class ProductDetailsScreen extends StatelessWidget {
  const ProductDetailsScreen({super.key, required this.productId});

  final String productId;

  void _showScanOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Scan QR code',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Use the camera to read a product label, then choose what to do.',
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.add_box_outlined),
                title: const Text('Stock in'),
                subtitle: const Text('Open receive quantity for scanned product'),
                onTap: () {
                  Navigator.pop(ctx);
                  ProductQrScanActions.scanThenStockIn(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.shopping_cart_outlined),
                title: const Text('Add to cart'),
                subtitle: const Text('Add scanned product to POS cart'),
                onTap: () {
                  Navigator.pop(ctx);
                  ProductQrScanActions.scanThenAddToCart(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = context.watch<ProductsProvider>().byId(productId);
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    if (product == null) {
      return Scaffold(
        appBar: const PremiumAppBar(title: 'Product'),
        body: ErrorStateWidget(
          title: 'Product not found',
          subtitle: 'It may have been removed or you opened an invalid link.',
          retryLabel: 'Go back',
          retryIcon: Icons.arrow_back_rounded,
          onRetry: () => Navigator.pop(context),
        ),
      );
    }

    return Scaffold(
      appBar: PremiumAppBar(
        title: product.name,
        subtitle: 'Details & QR',
        actions: [
          IconButton(
            tooltip: 'Scan QR',
            icon: const Icon(Icons.qr_code_scanner_rounded),
            onPressed: () => _showScanOptions(context),
          ),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => Navigator.pushNamed(
                context,
                AppRoutes.productEdit,
                arguments: product.id,
              ),
            ),
          IconButton(
            tooltip: 'Copy product ID',
            icon: const Icon(Icons.copy_all_outlined),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: product.id));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Product ID copied')),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: PremiumTokens.pagePadding(context),
        children: [
          FeatureHeaderCard(
            title: 'Product Details',
            subtitle: 'Review stock, QR label, and quick actions for this item.',
            icon: Icons.inventory_2_rounded,
            trailingIcon: Icons.qr_code_2_rounded,
          ),
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
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                avatar: const Icon(Icons.category_outlined, size: 16),
                label: Text(product.category),
              ),
              Chip(
                avatar: Icon(
                  product.isLowStock
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_outline_rounded,
                  size: 16,
                  color: product.isLowStock ? Colors.deepOrange : Colors.green,
                ),
                label: Text(product.isLowStock ? 'Low stock' : 'In stock'),
              ),
            ],
          ),
          if (product.isLowStock)
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 12),
              child: ActionCard(
                icon: Icons.warning_amber_rounded,
                label: 'Low stock',
                subtitle:
                    'Below ${AppConstants.lowStockThreshold} ${product.unit}',
                iconColor: Colors.deepOrange,
                onTap: null,
              ),
            ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 860;
              final detailsCard = ReportCard(
                child: Column(
                  children: [
                    _DetailRow('Category', product.category),
                    _DetailRow('Buying price', BdtFormatter.format(product.buyingPrice)),
                    _DetailRow('Selling price', BdtFormatter.format(product.sellingPrice)),
                    _DetailRow('Quantity', '${product.quantity} ${product.unit}'),
                    _DetailRow('Stock value (cost)', BdtFormatter.format(product.stockValue)),
                  ],
                ),
              );
              final qrCard = ReportCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'QR preview',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 10),
                    ProductQrCard(
                      productId: product.id,
                      productName: product.name,
                      embeddedSize: 148,
                      onViewFullscreen: () => Navigator.pushNamed(
                        context,
                        AppRoutes.qrGenerate,
                        arguments: product.id,
                      ),
                    ),
                  ],
                ),
              );
              if (!isWide) {
                return Column(
                  children: [
                    detailsCard,
                    const SizedBox(height: 16),
                    qrCard,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: detailsCard),
                  const SizedBox(width: 10),
                  Expanded(flex: 2, child: qrCard),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Scan',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () =>
                      ProductQrScanActions.scanThenStockIn(context),
                  icon: const Icon(Icons.add_box_outlined),
                  label: const Text('Stock in'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () =>
                      ProductQrScanActions.scanThenAddToCart(context),
                  icon: const Icon(Icons.shopping_cart_outlined),
                  label: const Text('To cart'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Quick actions',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.stockIn,
              arguments: product.id,
            ),
            icon: const Icon(Icons.edit_note_outlined),
            label: const Text('Stock in (this product)'),
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
