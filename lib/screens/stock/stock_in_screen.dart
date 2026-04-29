import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/error_handler.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/premium/premium_ui.dart';
import '../../providers/auth_provider.dart';
import '../../providers/products_provider.dart';
import '../../services/product_service.dart';

/// Receive stock for one product (quantity + optional note).
class StockInScreen extends StatefulWidget {
  const StockInScreen({super.key, required this.productId});

  final String productId;

  @override
  State<StockInScreen> createState() => _StockInScreenState();
}

class _StockInScreenState extends State<StockInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _qty = TextEditingController(text: '1');
  final _note = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _qty.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = context.read<AuthProvider>().activeUid;
    if (uid == null) return;
    setState(() => _busy = true);
    try {
      await context.read<ProductService>().stockIn(
            productId: widget.productId,
            qty: int.parse(_qty.text.trim()),
            userId: uid,
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stock updated successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) ErrorHandler.showSnack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = context.watch<ProductsProvider>().byId(widget.productId);

    return Scaffold(
      appBar: const PremiumAppBar(
        title: 'Stock in',
        subtitle: 'Receive inventory',
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
        child: product == null
            ? ErrorStateWidget(
                title: 'Product not found',
                retryLabel: 'Go back',
                retryIcon: Icons.arrow_back_rounded,
                onRetry: () => Navigator.pop(context),
              )
            : AbsorbPointer(
                absorbing: _busy,
                child: SingleChildScrollView(
                  padding: PremiumTokens.pagePadding(context),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const FeatureHeaderCard(
                          title: 'Receive Inventory',
                          subtitle: 'Add newly arrived units and keep stock accurate.',
                          icon: Icons.add_box_outlined,
                          trailingIcon: Icons.local_shipping_outlined,
                        ),
                        const AnimatedFeatureHero(
                          title: 'Scan & Receive Flow',
                          subtitle: 'Barcode intake to shelf-ready inventory.',
                          icon: Icons.qr_code_scanner_rounded,
                          gradientColors: [Color(0xFF6F39FF), Color(0xFF1A8DFF), Color(0xFF1DE2B0)],
                          animationType: FeatureHeroAnimationType.scanner,
                        ),
                        PremiumGlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 6),
                              StockStatusBadge(
                                isLowStock: product.isLowStock,
                                quantityLabel: '${product.quantity} ${product.unit}',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        PremiumGlassCard(
                          child: Column(
                            children: [
                              PremiumTextField(
                                controller: _qty,
                                keyboardType: TextInputType.number,
                                label: 'Quantity to add',
                                validator: (v) =>
                                    Validators.positiveInt(v, field: 'Quantity'),
                              ),
                              const SizedBox(height: 12),
                              PremiumTextField(
                                controller: _note,
                                label: 'Note (optional)',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        if (product.isLowStock)
                          PremiumGlassCard(
                            borderColor: Colors.deepOrange.withValues(alpha: 0.4),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: Colors.deepOrange),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'This item is low on stock. Receiving now will normalize availability.',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 28),
                        PremiumButton(
                          label: _busy ? 'Saving…' : 'Confirm stock in',
                          expand: true,
                          icon: _busy ? null : Icons.inventory_2_rounded,
                          onPressed: _busy ? null : _submit,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
