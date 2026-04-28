import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/error_handler.dart';
import '../../core/widgets/premium/premium_ui.dart';
import '../../models/product.dart';
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

  void _incrementProduct(Product p) {
    final cart = context.read<CartProvider>();
    final inCart = cart.countFor(p.id);
    if (inCart >= p.quantity) {
      ErrorHandler.showSnack(context, Exception('Cannot exceed stock'));
      return;
    }
    _addById(p.id);
  }

  void _decrementProduct(Product p) {
    final cart = context.read<CartProvider>();
    final next = cart.countFor(p.id) - 1;
    cart.setQuantity(p.id, next);
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductsProvider>().products;
    final cart = context.watch<CartProvider>();
    final cartItems = cart.lines.fold<int>(0, (sum, line) => sum + line.quantity);
    final cartTotal = cart.subtotal;
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
        subtitle: 'Quick checkout workspace',
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 1000;
          return Column(
            children: [
              Padding(
                padding: PremiumTokens.pagePadding(context).copyWith(bottom: 0),
                child: Column(
                  children: [
                    FeatureHeaderCard(
                      title: 'Premium POS Counter',
                      subtitle: '$cartItems item(s) in cart • ${filtered.length} visible products',
                      icon: Icons.point_of_sale_rounded,
                      trailingIcon: Icons.shopping_bag_outlined,
                    ),
                    _ScanManualPanel(
                      search: _search,
                      manualId: _manualId,
                      onSearch: () => setState(() {}),
                      onManualSubmit: _addById,
                      onScan: _scanForCart,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: isWide
                    ? Row(
                        children: [
                          Expanded(child: _buildProductArea(filtered, products)),
                          SizedBox(
                            width: 330,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(0, 0, 16, 16),
                              child: _CartSummaryPanel(
                                cart: cart,
                                total: cartTotal,
                                cartItems: cartItems,
                              ),
                            ),
                          ),
                        ],
                      )
                    : _buildProductArea(filtered, products),
              ),
              if (!isWide)
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
                                onPressed: () => Navigator.pushNamed(context, AppRoutes.cart),
                                icon: const Icon(Icons.shopping_cart_checkout),
                                label: Text('Checkout ($cartItems)'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProductArea(List<Product> filtered, List<Product> products) {
    if (filtered.isEmpty) {
      return EmptyStateWidget(
        icon: products.isEmpty ? Icons.storefront_outlined : Icons.search_off_rounded,
        title: products.isEmpty ? 'No products' : 'No matches',
        subtitle: products.isEmpty
            ? 'Add products before you can sell from this screen.'
            : 'Try a different search or clear the filter.',
      );
    }
    return ListView.builder(
      padding: PremiumTokens.pagePadding(context),
      itemCount: filtered.length,
      itemBuilder: (context, i) {
        final p = filtered[i];
        final inCart = context.watch<CartProvider>().countFor(p.id);
        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 220),
          tween: Tween(begin: 0.97, end: 1),
          curve: Curves.easeOut,
          builder: (context, value, child) {
            return Transform.scale(scale: value, child: child);
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _PosProductCard(
              product: p,
              inCartQty: inCart,
              onTap: p.quantity < 1 ? null : () => _addById(p.id),
              onIncrement: p.quantity < 1 ? null : () => _incrementProduct(p),
              onDecrement: inCart > 0 ? () => _decrementProduct(p) : null,
            ),
          ),
        );
      },
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

class _ScanManualPanel extends StatelessWidget {
  const _ScanManualPanel({
    required this.search,
    required this.manualId,
    required this.onSearch,
    required this.onManualSubmit,
    required this.onScan,
  });

  final TextEditingController search;
  final TextEditingController manualId;
  final VoidCallback onSearch;
  final void Function(String id) onManualSubmit;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(PremiumTokens.radiusLg),
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: search,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Search products...',
              ),
              onChanged: (_) => onSearch(),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: manualId,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.pin_outlined),
                      hintText: 'Enter product ID manually',
                    ),
                    onSubmitted: (v) {
                      final id = v.trim();
                      if (id.isEmpty) return;
                      onManualSubmit(id);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  onPressed: () {
                    final id = manualId.text.trim();
                    if (id.isEmpty) return;
                    onManualSubmit(id);
                  },
                  icon: const Icon(Icons.add_box_rounded),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onScan,
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: const Text('Scan QR to add'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PosProductCard extends StatelessWidget {
  const _PosProductCard({
    required this.product,
    required this.inCartQty,
    required this.onTap,
    required this.onIncrement,
    required this.onDecrement,
  });

  final Product product;
  final int inCartQty;
  final VoidCallback? onTap;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Opacity(
      opacity: product.quantity < 1 ? 0.55 : 1,
      child: DecoratedBox(
        decoration: PremiumTokens.cardDecoration(context),
        child: ListTile(
          onTap: onTap,
          leading: CircleAvatar(
            backgroundColor: cs.primaryContainer.withValues(alpha: 0.7),
            child: Icon(Icons.inventory_2_outlined, color: cs.primary),
          ),
          title: Text(product.name),
          subtitle: Text(
            '${product.category} • Stock ${product.quantity} ${product.unit}'
            '${inCartQty > 0 ? ' • In cart $inCartQty' : ''}',
          ),
          trailing: SizedBox(
            width: 126,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton.filledTonal(
                  onPressed: onDecrement,
                  constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.remove_rounded, size: 16),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 24,
                  child: Text(
                    '$inCartQty',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                const SizedBox(width: 6),
                IconButton.filled(
                  onPressed: onIncrement,
                  constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.add_rounded, size: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CartSummaryPanel extends StatelessWidget {
  const _CartSummaryPanel({
    required this.cart,
    required this.total,
    required this.cartItems,
  });

  final CartProvider cart;
  final double total;
  final int cartItems;

  @override
  Widget build(BuildContext context) {
    return ReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Cart Summary',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          _PosInfoChip(icon: Icons.shopping_cart_outlined, label: '$cartItems item(s)'),
          const SizedBox(height: 8),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: cart.lines.isEmpty
                  ? const _MiniCartEmptyState(
                      key: ValueKey('empty'),
                    )
                  : ListView.builder(
                      key: const ValueKey('list'),
                      itemCount: cart.lines.length,
                      itemBuilder: (context, i) {
                        final line = cart.lines[i];
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.sell_outlined, size: 18),
                          title: Text(line.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text('Qty ${line.quantity}'),
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Total checkout',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          Text(
            '৳ ${total.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.cart),
            icon: const Icon(Icons.shopping_cart_checkout_rounded),
            label: const Text('Open Checkout'),
          ),
        ],
      ),
    );
  }
}

class _MiniCartEmptyState extends StatelessWidget {
  const _MiniCartEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_cart_outlined, color: cs.outline, size: 34),
            const SizedBox(height: 8),
            Text(
              'Cart is empty',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Add products using tap, controls, scan, or manual ID.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
