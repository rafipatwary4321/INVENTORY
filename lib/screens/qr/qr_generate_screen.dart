import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      appBar: const NeonAppBar(
        title: 'Product QR',
        subtitle: 'Print-ready label',
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
        child: SingleChildScrollView(
          padding: PremiumTokens.pagePadding(context),
          child: Column(
            children: [
              NeonGlassCard(
                radius: 26,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'QR Label',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Use for stock in, POS sell, and scanner workflows.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 12),
                    ProductQrCard(
                      productId: productId,
                      productName: product?.name,
                      embeddedSize: 240,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              NeonGlassCard(
                radius: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product?.name ?? 'Product',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Product ID: $productId',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        SizedBox(
                          width: 160,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              ErrorHandler.showSnack(
                                context,
                                Exception('Download/Print QR will be added soon.'),
                              );
                            },
                            icon: const Icon(Icons.print_outlined),
                            label: const Text('Download / Print'),
                          ),
                        ),
                        SizedBox(
                          width: 160,
                          child: NeonButton(
                            label: 'Copy Product ID',
                            icon: Icons.copy_all_outlined,
                            onPressed: () async {
                              await Clipboard.setData(ClipboardData(text: productId));
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Product ID copied')),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              NeonGlassCard(
                radius: 22,
                child: Text(
                  'Print or share this screen so staff can scan the code for stock-in or sales quickly.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                        height: 1.45,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
