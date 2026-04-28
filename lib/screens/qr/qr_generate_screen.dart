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
      appBar: const PremiumAppBar(
        title: 'Product QR',
        subtitle: 'Print-ready label',
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
        child: SingleChildScrollView(
          padding: PremiumTokens.pagePadding(context),
          child: Column(
            children: [
              const FeatureHeaderCard(
                title: 'QR Label',
                subtitle: 'Generate a premium print-ready code for scan workflows.',
                icon: Icons.qr_code_2_rounded,
                trailingIcon: Icons.print_outlined,
              ),
              PremiumGlassCard(
                child: ProductQrCard(
                  productId: productId,
                  productName: product?.name,
                  embeddedSize: 240,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Print or share this screen so staff can scan the code for stock in or sales.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.45,
                    ),
              ),
              const SizedBox(height: 20),
              PremiumGlassCard(
                child: Row(
                  children: [
                    Expanded(
                      child: PremiumButton(
                        label: 'Download',
                        outlined: true,
                        icon: Icons.download_outlined,
                        expand: true,
                        onPressed: () {
                          ErrorHandler.showSnack(
                            context,
                            Exception('Download QR will be added soon.'),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PremiumButton(
                        label: 'Print',
                        icon: Icons.print_outlined,
                        expand: true,
                        onPressed: () {
                          ErrorHandler.showSnack(
                            context,
                            Exception('Print QR will be added soon.'),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
