import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/bdt_formatter.dart';
import '../../core/utils/error_handler.dart';
import '../../core/widgets/premium/premium_ui.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_router.dart';
import '../../providers/cart_provider.dart';
import '../../providers/products_provider.dart';
import '../../services/sale_service.dart';

/// Review cart lines, adjust quantities, complete sale (writes Firestore).
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _busy = false;

  Future<void> _checkout() async {
    final uid = context.read<AuthProvider>().activeUid;
    if (uid == null) return;
    final cart = context.read<CartProvider>();
    final products = context.read<ProductsProvider>();
    if (cart.isEmpty) return;

    for (final line in cart.lines) {
      final p = products.byId(line.productId);
      if (p == null || p.quantity < line.quantity) {
        ErrorHandler.showSnack(
          context,
          Exception('Not enough stock for ${line.name}'),
        );
        return;
      }
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm checkout'),
        content: Text(
          'Total ${BdtFormatter.format(cart.subtotal)}\n'
          'Complete this sale?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!mounted) return;
    final saleService = context.read<SaleService>();

    setState(() => _busy = true);
    try {
      await saleService.completeSale(
            lines: cart.lines,
            userId: uid,
          );
      cart.clear();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.dashboard,
        (route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sale completed')),
      );
    } catch (e) {
      if (mounted) ErrorHandler.showSnack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: const PremiumAppBar(
        title: 'Cart',
        subtitle: 'Review & checkout',
      ),
      body: cart.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.shopping_cart_outlined,
              title: 'Cart is empty',
              subtitle: 'Add products from Sell / POS to build a sale.',
            )
          : Column(
              children: [
                Padding(
                  padding: PremiumTokens.pagePadding(context).copyWith(bottom: 0),
                  child: FeatureHeaderCard(
                    title: 'Checkout Cart',
                    subtitle: '${cart.lines.length} line(s) ready for billing review.',
                    icon: Icons.shopping_cart_checkout_rounded,
                    trailingIcon: Icons.receipt_long_rounded,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: PremiumTokens.pagePadding(context),
                    itemCount: cart.lines.length,
                    itemBuilder: (context, i) {
                      final line = cart.lines[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ReportCard(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                              Text(
                                line.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                '${BdtFormatter.format(line.unitPrice)} × ${line.quantity}',
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      context.read<CartProvider>().setQuantity(
                                            line.productId,
                                            line.quantity - 1,
                                          );
                                    },
                                    icon: const Icon(Icons.remove_circle_outline),
                                  ),
                                  Text('${line.quantity}'),
                                  IconButton(
                                    onPressed: () {
                                      final stock = context
                                          .read<ProductsProvider>()
                                          .byId(line.productId)
                                          ?.quantity;
                                      if (stock != null &&
                                          line.quantity + 1 > stock) {
                                        ErrorHandler.showSnack(
                                          context,
                                          Exception('Cannot exceed stock'),
                                        );
                                        return;
                                      }
                                      context.read<CartProvider>().setQuantity(
                                            line.productId,
                                            line.quantity + 1,
                                          );
                                    },
                                    icon: const Icon(Icons.add_circle_outline),
                                  ),
                                  IconButton(
                                    tooltip: 'Remove',
                                    onPressed: () => context
                                        .read<CartProvider>()
                                        .removeLine(line.productId),
                                    icon: const Icon(Icons.delete_outline),
                                  ),
                                  const Spacer(),
                                  Text(
                                    BdtFormatter.format(line.lineTotal),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        ),
                      );
                    },
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: PremiumTokens.pagePadding(context),
                    child: ReportCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Total: ${BdtFormatter.format(cart.subtotal)}',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          PremiumButton(
                            label: _busy ? 'Processing…' : 'Complete sale',
                            expand: true,
                            icon: _busy ? null : Icons.check_rounded,
                            onPressed: _busy ? null : _checkout,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
