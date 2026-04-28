import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/error_handler.dart';
import '../../core/widgets/premium/premium_ui.dart';
import '../../providers/cart_provider.dart';
import '../../providers/products_provider.dart';
import '../../routes/app_router.dart';
import '../products/product_qr_scan_actions.dart';

/// POS-style product picker + QR scan to add items to the cart.
class SellScreen extends StatefulWidget {
  const SellScreen({super.key, this.prefillProductId});

  final String? prefillProductId;

  @override
  State<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends State<SellScreen> {
  final _search = TextEditingController();
  final _manualId = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.prefillProductId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _addById(widget.prefillProductId!));
    }
  }

  @override
  void dispose() {
    _search.dispose();
    _manualId.dispose();
    super.dispose();
  }

  void _addById(String id) {
    final p = context.read<ProductsProvider>().byId(id);
    if (p == null) {
      ErrorHandler.showSnack(context, Exception('Unknown product'));
      return;
    }
    if (p.quantity < 1) {
      ErrorHandler.showSnack(context, Exception('Out of stock'));
      return;
    }
    context.read<CartProvider>().addOrUpdate(
          productId: p.id,
          name: p.name,
          unitPrice: p.sellingPrice,
          buyingPrice: p.buyingPrice,
          addQty: 1,
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added ${p.name} to cart')),
    );
  }

  Future<void> _scanForCart() =>
      ProductQrScanActions.scanThenAddToCart(context);

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductsProvider>().products;
    final cart = context.watch<CartProvider>();
    final cartItems = cart.lines.fold<int>(0, (sum, line) => sum + line.quantity);
    final q = _search.text.trim().toLowerCase();
    final filtered = q.isEmpty
        ? products
        : products
            .where((p) =>
                p.name.toLowerCase().contains(q) ||
                p.category.toLowerCase().contains(q))
            .toList();

    return Scaffold(
      appBar: PremiumAppBar(
        title: 'Sell / POS',
        subtitle: 'Tap a product to add to cart',
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            onPressed: _scanForCart,
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.cart),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: PremiumTokens.pagePadding(context).copyWith(bottom: 0),
            child: Column(
              children: [
                const FeatureHeaderCard(
                  title: 'POS Counter',
                  subtitle: 'Search products, scan labels, and build checkout quickly.',
                  icon: Icons.point_of_sale_rounded,
                  trailingIcon: Icons.shopping_bag_outlined,
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(PremiumTokens.radiusLg),
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _PosInfoChip(
                              icon: Icons.inventory_2_outlined,
                              label: '${filtered.length} visible',
                            ),
                            const SizedBox(width: 8),
                            _PosInfoChip(
                              icon: Icons.shopping_cart_outlined,
                              label: '$cartItems in cart',
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _search,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search_rounded),
                            hintText: 'Search products...',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _manualId,
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(Icons.pin_outlined),
                                  hintText: 'Enter product ID manually',
                                ),
                                onSubmitted: (v) {
                                  final id = v.trim();
                                  if (id.isEmpty) return;
                                  _addById(id);
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.tonalIcon(
                              onPressed: () {
                                final id = _manualId.text.trim();
                                if (id.isEmpty) return;
                                _addById(id);
                              },
                              icon: const Icon(Icons.add_box_rounded),
                              label: const Text('Add'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? EmptyStateWidget(
                    icon: products.isEmpty ? Icons.storefront_outlined : Icons.search_off_rounded,
                    title: products.isEmpty ? 'No products' : 'No matches',
                    subtitle: products.isEmpty
                        ? 'Add products before you can sell from this screen.'
                        : 'Try a different search or clear the filter.',
                  )
                : ListView.builder(
                    padding: PremiumTokens.pagePadding(context),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final p = filtered[i];
                      return TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 220),
                        tween: Tween(begin: 0.97, end: 1),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          return Transform.scale(scale: value, child: child);
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Opacity(
                            opacity: p.quantity < 1 ? 0.55 : 1,
                            child: ProductCard(
                              product: p,
                              onTap: p.quantity < 1 ? () {} : () => _addById(p.id),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(PremiumTokens.radiusLg),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _scanForCart,
                          icon: const Icon(Icons.qr_code_scanner),
                          label: const Text('Scan to add'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () =>
                              Navigator.pushNamed(context, AppRoutes.cart),
                          icon: const Icon(Icons.shopping_cart_checkout),
                          label: Text('Cart ($cartItems)'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PosInfoChip extends StatelessWidget {
  const _PosInfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.72),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
