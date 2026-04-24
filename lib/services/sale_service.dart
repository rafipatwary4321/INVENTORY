import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/app_constants.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';
import 'product_service.dart';

/// Cart line used when completing a sale.
class CartLine {
  CartLine({
    required this.productId,
    required this.name,
    required this.unitPrice,
    required this.buyingPrice,
    required this.quantity,
  });

  final String productId;
  final String name;
  final double unitPrice;
  final double buyingPrice;
  final int quantity;

  double get lineTotal => unitPrice * quantity;
}

/// Creates sales, sale_items, and decrements inventory in one batch.
class SaleService {
  SaleService(this._db, this._products);

  final FirebaseFirestore _db;
  final ProductService _products;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _sales =>
      _db.collection(AppConstants.salesCollection);

  CollectionReference<Map<String, dynamic>> get _items =>
      _db.collection(AppConstants.saleItemsCollection);

  /// Streams recent sales (newest first) for reports.
  Stream<List<Sale>> salesStream({int limit = 200}) {
    return _sales
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(Sale.fromFirestore).toList());
  }

  Stream<List<SaleItem>> saleItemsForSale(String saleId) {
    return _items
        .where('saleId', isEqualTo: saleId)
        .snapshots()
        .map((s) => s.docs.map(SaleItem.fromFirestore).toList());
  }

  /// All sale items for aggregation (reports) — client-side filter by date.
  /// Line items for P&L / sales reports (sorted newest first in Dart).
  Stream<List<SaleItem>> allSaleItemsStream({int limit = 500}) {
    return _items.limit(limit).snapshots().map((s) {
      final list = s.docs.map(SaleItem.fromFirestore).toList();
      list.sort((a, b) {
        final ad = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });
      return list;
    });
  }

  Future<String> completeSale({
    required List<CartLine> lines,
    required String userId,
    String? customerNote,
  }) async {
    if (lines.isEmpty) throw ArgumentError('Cart is empty');

    final saleId = _uuid.v4();
    double total = 0;
    var count = 0;
    for (final l in lines) {
      total += l.lineTotal;
      count += l.quantity;
    }

    final batch = _db.batch();
    final saleRef = _sales.doc(saleId);
    batch.set(saleRef, Sale.createMap(
      totalAmount: total,
      itemCount: count,
      userId: userId,
      customerNote: customerNote,
    ));

    for (final l in lines) {
      final itemRef = _items.doc(_uuid.v4());
      batch.set(itemRef, SaleItem.createMap(
        saleId: saleId,
        productId: l.productId,
        productName: l.name,
        unitPrice: l.unitPrice,
        quantity: l.quantity,
        lineTotal: l.lineTotal,
        buyingPriceAtSale: l.buyingPrice,
      ));
    }

    await batch.commit();

    // Stock runs after the sale doc exists; for full atomicity use CF or one transaction.
    // One transaction per product line keeps conflicts localized.
    for (final l in lines) {
      await _products.applyStockOut(
        productId: l.productId,
        qty: l.quantity,
        userId: userId,
        saleId: saleId,
      );
    }

    return saleId;
  }
}
