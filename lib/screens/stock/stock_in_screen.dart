import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/error_handler.dart';
import '../../core/utils/validators.dart';
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
    final uid = context.read<AuthProvider>().firebaseUser?.uid;
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
      appBar: AppBar(title: const Text('Stock in')),
      body: product == null
          ? const Center(child: Text('Product not found'))
          : AbsorbPointer(
              absorbing: _busy,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        product.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text('Current qty: ${product.quantity} ${product.unit}'),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _qty,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Quantity to add',
                        ),
                        validator: (v) => Validators.positiveInt(v, field: 'Quantity'),
                      ),
                      TextFormField(
                        controller: _note,
                        decoration: const InputDecoration(
                          labelText: 'Note (optional)',
                        ),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: _busy ? null : _submit,
                        child: _busy
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Confirm stock in'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
