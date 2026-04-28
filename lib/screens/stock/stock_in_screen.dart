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
      body: product == null
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
                      ReportCard(
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
                            Text(
                              'Current qty: ${product.quantity} ${product.unit}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
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
    );
  }
}
