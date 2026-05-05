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
      appBar: const NeonAppBar(
        title: 'Stock in',
        subtitle: 'Receive inventory',
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
                        NeonGlassCard(
                          radius: 26,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Product Preview',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 8),
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
                        const SizedBox(height: 12),
                        NeonGlassCard(
                          radius: 24,
                          borderColor: const Color(0x663B82F6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current Stock',
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${product.quantity} ${product.unit}',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        NeonGlassCard(
                          radius: 24,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Quantity Input',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 10),
                              NeonTextField(
                                controller: _qty,
                                keyboardType: TextInputType.number,
                                label: 'Quantity to add',
                                validator: (v) =>
                                    Validators.positiveInt(v, field: 'Quantity'),
                              ),
                              const SizedBox(height: 12),
                              NeonTextField(
                                controller: _note,
                                label: 'Note (optional)',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (product.isLowStock)
                          NeonGlassCard(
                            radius: 22,
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
                        const SizedBox(height: 20),
                        NeonButton(
                          label: _busy ? 'Saving…' : 'Confirm stock in',
                          icon: _busy ? null : Icons.inventory_2_rounded,
                          onPressed: _busy ? null : _submit,
                        ),
                        const SizedBox(height: 10),
                        NeonGlassCard(
                          radius: 20,
                          child: Row(
                            children: [
                              const Icon(Icons.task_alt_rounded, color: Color(0xFF22D3EE)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'On success, stock quantity updates instantly in inventory.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Colors.white70),
                                ),
                              ),
                            ],
                          ),
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
