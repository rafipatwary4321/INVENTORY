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
        const SnackBar(
          content: Text('Sale completed'),
          behavior: SnackBarBehavior.floating,
        ),
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
      appBar: const NeonAppBar(
        title: 'Cart',
        subtitle: 'Review & checkout',
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
        child: cart.isEmpty
            ? const EmptyStatePremium(
                icon: Icons.shopping_cart_outlined,
                title: 'Cart is empty',
                subtitle: 'Add products from Sell / POS to build a sale.',
              )
            : Column(
                children: [
                  Padding(
                    padding: PremiumTokens.pagePadding(context).copyWith(bottom: 0),
                    child: Column(
                      children: [
                        NeonGlassCard(
                          radius: 24,
                          borderColor: const Color(0xFF13A7FF).withValues(alpha: 0.4),
                          child: Row(
                            children: [
                              const Icon(Icons.bolt_rounded, color: Color(0xFF13A7FF)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Express Checkout • ${cart.lines.fold<int>(0, (s, l) => s + l.quantity)} item(s)',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: PremiumTokens.pagePadding(context),
                      itemCount: cart.lines.length,
                      itemBuilder: (context, i) {
                        final line = cart.lines[i];
                        final stock = context.read<ProductsProvider>().byId(line.productId)?.quantity;
                        final atStockLimit = stock != null && line.quantity >= stock;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: PremiumGlassCard(
                            radius: 22,
                            borderColor: atStockLimit
                                ? Colors.amber.withValues(alpha: 0.45)
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    line.name,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  Text(
                                    '${BdtFormatter.format(line.unitPrice)} × ${line.quantity}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.white70,
                                        ),
                                  ),
                                  if (atStockLimit)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        'Stock limit reached',
                                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                              color: Colors.amber.shade700,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      IconButton.filledTonal(
                                        onPressed: () {
                                          context.read<CartProvider>().setQuantity(
                                                line.productId,
                                                line.quantity - 1,
                                              );
                                        },
                                        icon: const Icon(Icons.remove_rounded),
                                      ),
                                      Text(
                                        '${line.quantity}',
                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      IconButton.filled(
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
                                        icon: const Icon(Icons.add_rounded),
                                      ),
                                      IconButton(
                                        tooltip: 'Remove',
                                        onPressed: () =>
                                            context.read<CartProvider>().removeLine(line.productId),
                                        icon: const Icon(Icons.delete_outline, color: Color(0xFFF97316)),
                                      ),
                                      const Spacer(),
                                      Text(
                                        BdtFormatter.format(line.lineTotal),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
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
                      child: NeonGlassCard(
                        radius: 26,
                        borderColor: const Color(0x6642D4F7),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Total: ${BdtFormatter.format(cart.subtotal)}',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            NeonButton(
                              label: _busy ? 'Processing…' : 'Complete sale',
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
      ),
    );
  }
}
