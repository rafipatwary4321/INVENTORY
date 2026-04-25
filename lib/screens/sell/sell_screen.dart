import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/bdt_formatter.dart';
import '../../core/utils/error_handler.dart';
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
    final q = _search.text.trim().toLowerCase();
    final filtered = q.isEmpty
        ? products
        : products
            .where((p) =>
                p.name.toLowerCase().contains(q) ||
                p.category.toLowerCase().contains(q))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sell / POS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              children: [
                TextField(
                  controller: _search,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search products…',
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
                    FilledButton.tonal(
                      onPressed: () {
                        final id = _manualId.text.trim();
                        if (id.isEmpty) return;
                        _addById(id);
                      },
                      child: const Text('Add ID'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final p = filtered[i];
                return Card(
                  child: ListTile(
                    title: Text(p.name),
                    subtitle: Text(
                      '${BdtFormatter.format(p.sellingPrice)} · Stock ${p.quantity} ${p.unit}',
                    ),
                    trailing: FilledButton(
                      onPressed: p.quantity < 1
                          ? null
                          : () => _addById(p.id),
                      child: const Text('Add'),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
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
                      label: const Text('Cart'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
