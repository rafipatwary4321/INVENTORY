import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/error_handler.dart';
import '../../core/widgets/premium/premium_ui.dart';
import '../../core/widgets/product_qr_card.dart';
import '../../providers/products_provider.dart';

/// Fullscreen view of the product QR (same payload as detail screen).
class QRGenerateScreen extends StatelessWidget {
  const QRGenerateScreen({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context) {
    final product = context.watch<ProductsProvider>().byId(productId);

    return Scaffold(
      appBar: AppBar(title: const Text('Product QR')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            ProductQrCard(
              productId: productId,
              productName: product?.name,
              embeddedSize: 240,
            ),
            const SizedBox(height: 20),
            Text(
              'Print or share this screen so staff can scan the code for stock in or sales.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ErrorHandler.showSnack(
                        context,
                        Exception('Download QR will be added soon.'),
                      );
                    },
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('Download QR'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () {
                      ErrorHandler.showSnack(
                        context,
                        Exception('Print QR will be added soon.'),
                      );
                    },
                    icon: const Icon(Icons.print_outlined),
                    label: const Text('Print QR'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
