import 'package:cloud_firestore/cloud_firestore.dart';

/// Line item in `sale_items/{itemId}` — links to [saleId].
class SaleItem {
  SaleItem({
    required this.id,
    required this.saleId,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
    required this.buyingPriceAtSale,
    this.createdAt,
  });

  final String id;
  final String saleId;
  final String productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final double lineTotal;
  /// Snapshot of cost for P&L without re-reading product history.
  final double buyingPriceAtSale;
  final DateTime? createdAt;

  double get lineProfit => lineTotal - (buyingPriceAtSale * quantity);

  factory SaleItem.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return SaleItem(
      id: doc.id,
      saleId: d['saleId'] as String? ?? '',
      productId: d['productId'] as String? ?? '',
      productName: d['productName'] as String? ?? '',
      unitPrice: (d['unitPrice'] as num?)?.toDouble() ?? 0,
      quantity: (d['quantity'] as num?)?.toInt() ?? 0,
      lineTotal: (d['lineTotal'] as num?)?.toDouble() ?? 0,
      buyingPriceAtSale: (d['buyingPriceAtSale'] as num?)?.toDouble() ?? 0,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  static Map<String, dynamic> createMap({
    required String saleId,
    required String productId,
    required String productName,
    required double unitPrice,
    required int quantity,
    required double lineTotal,
    required double buyingPriceAtSale,
  }) =>
      {
        'saleId': saleId,
        'productId': productId,
        'productName': productName,
        'unitPrice': unitPrice,
        'quantity': quantity,
        'lineTotal': lineTotal,
        'buyingPriceAtSale': buyingPriceAtSale,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
