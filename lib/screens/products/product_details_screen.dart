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
        appBar: const NeonAppBar(title: 'Product'),
        body: ErrorStateWidget(
          title: 'Product not found',
          subtitle: 'It may have been removed or you opened an invalid link.',
          retryLabel: 'Go back',
          retryIcon: Icons.arrow_back_rounded,
          onRetry: () => Navigator.pop(context),
        ),
      );
    }

    final outOfStock = product.quantity <= 0;
    final lowStock = product.quantity > 0 && product.quantity < AppConstants.lowStockThreshold;
    final statusLabel = outOfStock ? 'Out of Stock' : (lowStock ? 'Low Stock' : 'In Stock');
    final statusColor = outOfStock
        ? const Color(0xFFF97316)
        : (lowStock ? Colors.orangeAccent : const Color(0xFF22D3EE));

    return Scaffold(
      appBar: NeonAppBar(
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0B0F1A),
              Color(0xFF101B32),
              Color(0xFF162643),
            ],
          ),
        ),
        child: ListView(
          padding: PremiumTokens.pagePadding(context),
          children: [
            NeonGlassCard(
              padding: EdgeInsets.zero,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: AspectRatio(
                  aspectRatio: 16 / 8.8,
                  child: product.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: product.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              const Center(child: CircularProgressIndicator()),
                          errorWidget: (_, __, ___) => _ImagePlaceholder(),
                        )
                      : const _ImagePlaceholder(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            NeonGlassCard(
              radius: 24,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            NeonBadge(label: product.category, icon: Icons.category_outlined),
                            _StatusPill(label: statusLabel, color: statusColor),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (lowStock)
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: NeonGlassCard(
                  borderColor: const Color(0x66F97316),
                  radius: 22,
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Color(0xFFF97316)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Low stock warning: below ${AppConstants.lowStockThreshold} ${product.unit}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 860;
                final pricingStock = Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            title: 'Buy Price',
                            value: BdtFormatter.format(product.buyingPrice),
                            color: const Color(0xFF22D3EE),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricCard(
                            title: 'Sell Price',
                            value: BdtFormatter.format(product.sellingPrice),
                            color: const Color(0xFFA855F7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _MetricCard(
                      title: 'Current Stock',
                      value: '${product.quantity} ${product.unit}',
                      color: const Color(0xFF3B82F6),
                    ),
                  ],
                );
                final qrCard = NeonGlassCard(
                  radius: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'QR Code',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
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
                      pricingStock,
                      const SizedBox(height: 12),
                      qrCard,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: pricingStock),
                    const SizedBox(width: 12),
                    Expanded(flex: 2, child: qrCard),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            NeonGlassCard(
              radius: 24,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                    SizedBox(
                      width: 148,
                      child: NeonButton(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.productEdit,
                          arguments: product.id,
                        ),
                        icon: Icons.edit_outlined,
                        label: 'Edit',
                      ),
                    ),
                    SizedBox(
                      width: 148,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.stockIn,
                          arguments: product.id,
                        ),
                        icon: const Icon(Icons.add_box_outlined),
                        label: const Text('Stock In'),
                      ),
                    ),
                    SizedBox(
                      width: 128,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.sell,
                          arguments: product.id,
                        ),
                        icon: const Icon(Icons.sell_outlined),
                        label: const Text('Sell'),
                      ),
                    ),
                    SizedBox(
                      width: 128,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.qrGenerate,
                          arguments: product.id,
                        ),
                        icon: const Icon(Icons.qr_code_2_rounded),
                        label: const Text('QR / View'),
                      ),
                    ),
                    if (isAdmin)
                      SizedBox(
                        width: 128,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFF97316),
                            side: BorderSide(
                              color: const Color(0xFFF97316).withValues(alpha: 0.55),
                            ),
                          ),
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
                          icon: const Icon(Icons.delete_forever),
                          label: const Text('Delete'),
                        ),
                      ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            NeonGlassCard(
              radius: 24,
              child: Column(
                children: [
                  _DetailRow('Category', product.category),
                  _DetailRow('Buying price', BdtFormatter.format(product.buyingPrice)),
                  _DetailRow('Selling price', BdtFormatter.format(product.sellingPrice)),
                  _DetailRow('Quantity', '${product.quantity} ${product.unit}'),
                  _DetailRow('Stock value (cost)', BdtFormatter.format(product.stockValue)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.2),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return NeonGlassCard(
      radius: 22,
      borderColor: color.withValues(alpha: 0.48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white.withValues(alpha: 0.08),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 54,
              color: Colors.white.withValues(alpha: 0.85),
            ),
            const SizedBox(height: 8),
            Text(
              'No product image',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
            ),
          ],
        ),
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
