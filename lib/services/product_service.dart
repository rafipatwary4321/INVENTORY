import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/app_constants.dart';
import '../models/product.dart';
import '../models/stock_transaction.dart';

class ProductService {
  ProductService(this._db);

  final FirebaseFirestore _db;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(AppConstants.productsCollection);

  Stream<List<Product>> productsStream() {
    return _col.orderBy('name').snapshots().map(
          (s) => s.docs.map(Product.fromFirestore).toList(),
        );
  }

  Future<Product?> fetchProduct(String id) async {
    final d = await _col.doc(id).get();
    if (!d.exists) return null;
    return Product.fromFirestore(d);
  }

  Future<String> createProduct({
    required Map<String, dynamic> data,
    required String uid,
  }) async {
    final id = _uuid.v4();
    await _col.doc(id).set({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': uid,
    });
    return id;
  }

  Future<void> updateProduct(String id, Map<String, dynamic> data) {
    return _col.doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteProduct(String id) => _col.doc(id).delete();

  /// Adds stock and writes a stock transaction (atomic batch).
  Future<void> stockIn({
    required String productId,
    required int qty,
    required String userId,
    String? note,
  }) async {
    if (qty <= 0) throw ArgumentError('Quantity must be positive');
    final productRef = _col.doc(productId);
    final txRef =
        _db.collection(AppConstants.stockTransactionsCollection).doc(_uuid.v4());

    await _db.runTransaction((transaction) async {
      final snap = await transaction.get(productRef);
      if (!snap.exists) throw StateError('Product not found');
      final current = (snap.data()?['quantity'] as num?)?.toInt() ?? 0;
      transaction.update(productRef, {
        'quantity': current + qty,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.set(txRef, StockTransaction.createMap(
        productId: productId,
        type: StockTxType.in_,
        quantity: qty,
        userId: userId,
        note: note,
      ));
    });
  }

  /// Applies quantity delta with optional sale link (used after sale items).
  Future<void> applyStockOut({
    required String productId,
    required int qty,
    required String userId,
    String? saleId,
  }) async {
    if (qty <= 0) return;
    final productRef = _col.doc(productId);
    final txRef =
        _db.collection(AppConstants.stockTransactionsCollection).doc(_uuid.v4());

    await _db.runTransaction((transaction) async {
      final snap = await transaction.get(productRef);
      if (!snap.exists) throw StateError('Product not found');
      final current = (snap.data()?['quantity'] as num?)?.toInt() ?? 0;
      if (current < qty) {
        throw StateError('Insufficient stock');
      }
      transaction.update(productRef, {
        'quantity': current - qty,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.set(txRef, StockTransaction.createMap(
        productId: productId,
        type: StockTxType.out,
        quantity: qty,
        userId: userId,
        note: 'Sale',
        relatedSaleId: saleId,
      ));
    });
  }
}
