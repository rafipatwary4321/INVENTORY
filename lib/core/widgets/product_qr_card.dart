import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../utils/qr_payload.dart';

/// Embeddable product QR (encodes [productId] via [QrPayload]) for lists and detail.
class ProductQrCard extends StatelessWidget {
  const ProductQrCard({
    super.key,
    required this.productId,
    this.productName,
    this.embeddedSize = 132,
    this.onViewFullscreen,
  });

  final String productId;
  final String? productName;
  final double embeddedSize;
  final VoidCallback? onViewFullscreen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final payload = QrPayload.encodeProductId(productId);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.qr_code_2_rounded, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Product QR',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            if (productName != null && productName!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                productName!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: QrImageView(
                  data: payload,
                  version: QrVersions.auto,
                  size: embeddedSize,
                  gapless: true,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF1A1A1A),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF1A1A1A),
                  ),
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SelectableText(
              payload,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            if (onViewFullscreen != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onViewFullscreen,
                  icon: const Icon(Icons.open_in_full, size: 18),
                  label: const Text('Fullscreen'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
