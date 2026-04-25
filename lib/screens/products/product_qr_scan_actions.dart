import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/error_handler.dart';
import '../../models/qr_scan_args.dart';
import '../../providers/cart_provider.dart';
import '../../providers/products_provider.dart';
import '../../routes/app_router.dart';

/// Shared flows: open QR scanner, resolve product id, then stock-in or cart.
class ProductQrScanActions {
  ProductQrScanActions._();

  /// Scan → navigate to [StockInScreen] for the scanned product.
  static Future<void> scanThenStockIn(BuildContext context) async {
    final id = await Navigator.pushNamed<String?>(
      context,
      AppRoutes.qrScan,
      arguments: QRScanArgs(mode: QRScanMode.stockIn),
    );
    if (!context.mounted || id == null) return;
    await Navigator.pushNamed(
      context,
      AppRoutes.stockIn,
      arguments: id,
    );
  }

  /// Scan → add scanned product line to the POS cart.
  static Future<void> scanThenAddToCart(BuildContext context) async {
    final id = await Navigator.pushNamed<String?>(
      context,
      AppRoutes.qrScan,
      arguments: QRScanArgs(mode: QRScanMode.sell),
    );
    if (!context.mounted || id == null) return;

    final products = context.read<ProductsProvider>();
    final p = products.byId(id);
    if (p == null) {
      ErrorHandler.showSnack(context, Exception('Product not found for this QR'));
      return;
    }
    if (p.quantity < 1) {
      ErrorHandler.showSnack(context, Exception('${p.name} is out of stock'));
      return;
    }

    context.read<CartProvider>().addOrUpdate(
          productId: p.id,
          name: p.name,
          unitPrice: p.sellingPrice,
          buyingPrice: p.buyingPrice,
          addQty: 1,
        );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${p.name} to cart'),
        action: SnackBarAction(
          label: 'Cart',
          onPressed: () =>
              Navigator.pushNamed(context, AppRoutes.cart),
        ),
      ),
    );
  }
}
