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
  final _searchFocus = FocusNode();

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
    _searchFocus.dispose();
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
      SnackBar(
        content: Text('Added ${p.name} to cart'),
        behavior: SnackBarBehavior.floating,
      ),
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF050C18),
              Color(0xFF0A1C35),
              Color(0xFF0F2F57),
            ],
          ),
        ),
        child: LayoutBuilder(
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
                        subtitle:
                            '$cartItems item(s) in cart • ${filtered.length} visible products',
                        icon: Icons.point_of_sale_rounded,
                        trailingIcon: Icons.shopping_bag_outlined,
                      ),
                      _PosHeroCard(
                        cartItems: cartItems,
                        cartTotal: cartTotal,
                      ),
                      const SizedBox(height: 8),
                      const AnimatedFeatureHero(
                        title: 'Checkout Operations',
                        subtitle: 'Cashier lane, cart flow, and billing readiness.',
                        icon: Icons.point_of_sale_rounded,
                        gradientColors: [Color(0xFF7A37FF), Color(0xFF13A7FF), Color(0xFF1DE2B0)],
                        animationType: FeatureHeroAnimationType.pos,
                      ),
                      _ScanManualPanel(
                        search: _search,
                        searchFocus: _searchFocus,
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
                      child: PremiumGlassCard(
                        borderColor: const Color(0xFF13A7FF).withValues(alpha: 0.45),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF7A37FF), Color(0xFF13A7FF)],
                                ),
                              ),
                              child: const Icon(Icons.price_check_rounded, color: Colors.white),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total ৳ ${cartTotal.toStringAsFixed(2)}',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  Text(
                                    '$cartItems item(s) in checkout',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.white70,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _scanForCart,
                                icon: const Icon(Icons.qr_code_scanner),
                                label: const Text('Scan to add'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GlowButton(
                                onPressed: () => Navigator.pushNamed(context, AppRoutes.cart),
                                icon: Icons.shopping_cart_checkout,
                                label: 'Checkout ($cartItems)',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
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
    required this.searchFocus,
    required this.manualId,
    required this.onSearch,
    required this.onManualSubmit,
    required this.onScan,
  });

  final TextEditingController search;
  final FocusNode searchFocus;
  final TextEditingController manualId;
  final VoidCallback onSearch;
  final void Function(String id) onManualSubmit;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return PremiumGlassCard(
      borderColor: const Color(0xFF13A7FF).withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: searchFocus.hasFocus
                    ? [
                        BoxShadow(
                          color: Colors.cyanAccent.withValues(alpha: 0.24),
                          blurRadius: 20,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: TextField(
                focusNode: searchFocus,
                controller: search,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Search products...',
                ),
                onChanged: (_) => onSearch(),
              ),
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
            InkWell(
              onTap: onScan,
              borderRadius: BorderRadius.circular(14),
              child: Ink(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF633BFF), Color(0xFF13A7FF)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF13A7FF).withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Scan QR Banner · Tap to add item instantly',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Colors.white),
                  ],
                ),
              ),
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
    final lowStock = product.quantity <= 2;
    return Opacity(
      opacity: product.quantity < 1 ? 0.55 : 1,
      child: PremiumGlassCard(
        borderColor: inCartQty > product.quantity - 1
            ? Colors.amber.withValues(alpha: 0.45)
            : null,
        child: Column(
          children: [
            if (lowStock)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.orange.withValues(alpha: 0.14),
                  border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Low stock: ${product.quantity} ${product.unit}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.orangeAccent,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
            ListTile(
              onTap: onTap,
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7A37FF), Color(0xFF13A7FF)],
                  ),
                ),
                child: const Icon(Icons.inventory_2_outlined, color: Colors.white),
              ),
              title: Text(
                product.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              subtitle: Text(
                '${product.category} • Stock ${product.quantity} ${product.unit}'
                '${inCartQty > 0 ? ' • In cart $inCartQty' : ''}',
              ),
              isThreeLine: inCartQty >= product.quantity && product.quantity > 0,
              subtitleTextStyle: Theme.of(context).textTheme.bodySmall,
              minVerticalPadding: 10,
              trailing: SizedBox(
                width: 156,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _QtyButton(
                      icon: Icons.remove_rounded,
                      onTap: onDecrement,
                      filled: false,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 28,
                      alignment: Alignment.center,
                      child: Text(
                        '$inCartQty',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _QtyButton(
                      icon: Icons.add_rounded,
                      onTap: onIncrement,
                      filled: true,
                    ),
                  ],
                ),
              ),
            ),
            if (inCartQty > 0)
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'In cart total: ৳ ${(inCartQty * product.sellingPrice).toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cs.secondary.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _QtyButton extends StatefulWidget {
  const _QtyButton({
    required this.icon,
    required this.onTap,
    required this.filled,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;

  @override
  State<_QtyButton> createState() => _QtyButtonState();
}

class _QtyButtonState extends State<_QtyButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        scale: _pressed ? 0.94 : 1,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: widget.filled
                ? const LinearGradient(colors: [Color(0xFF7A37FF), Color(0xFF13A7FF)])
                : null,
            color: widget.filled ? null : Colors.white.withValues(alpha: 0.1),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            boxShadow: widget.filled
                ? [
                    BoxShadow(
                      color: const Color(0xFF13A7FF).withValues(alpha: 0.35),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            widget.icon,
            size: 20,
            color: widget.onTap == null ? Colors.white38 : Colors.white,
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
    return POSCartCard(
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
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white.withValues(alpha: 0.08),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.sell_outlined, size: 18, color: Colors.white70),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      line.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                            color: Colors.white,
                                          ),
                                    ),
                                    Text(
                                      'Qty ${line.quantity}',
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                            color: Colors.white70,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '৳ ${line.lineTotal.toStringAsFixed(0)}',
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
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
          GlowButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.cart),
            icon: Icons.shopping_cart_checkout_rounded,
            label: 'Open Checkout',
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
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF7A37FF), Color(0xFF13A7FF)],
                ),
              ),
              child: const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 32),
            ),
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

class _PosHeroCard extends StatelessWidget {
  const _PosHeroCard({
    required this.cartItems,
    required this.cartTotal,
  });

  final int cartItems;
  final double cartTotal;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6E37FF), Color(0xFF148CFF), Color(0xFF1AD3A9)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6E37FF).withValues(alpha: 0.34),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          const AnimatedFeatureHero(
            title: 'POS Checkout',
            subtitle: 'Fast billing lane',
            icon: Icons.point_of_sale_rounded,
            compact: true,
            gradientColors: [Color(0x007A37FF), Color(0x0013A7FF)],
            animationType: FeatureHeroAnimationType.pos,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '৳ ${cartTotal.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                Text(
                  '$cartItems items in cart',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
