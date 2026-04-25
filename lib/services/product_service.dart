import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/app_constants.dart';
import '../core/context/business_scope.dart';
import '../models/product.dart';
import '../models/stock_transaction.dart';

class ProductService {
  ProductService({
    required FirebaseFirestore? firestore,
    required bool firebaseEnabled,
  })  : _db = firestore,
        _firebaseEnabled = firebaseEnabled {
    if (!_firebaseEnabled) {
      _emitLocal();
    }
  }

  final FirebaseFirestore? _db;
  final bool _firebaseEnabled;
  final _uuid = const Uuid();
  final _localStream = StreamController<List<Product>>.broadcast();

  static final Map<String, Product> _localProducts = {};
  static final List<Map<String, dynamic>> _localStockTransactions = [];

  String get _businessId => BusinessScope.businessId;

  CollectionReference<Map<String, dynamic>> get _businessCol => _db!
      .collection(AppConstants.businessesCollection)
      .doc(_businessId)
      .collection(AppConstants.productsCollection);

  CollectionReference<Map<String, dynamic>> get _stockTxCol => _db!
      .collection(AppConstants.businessesCollection)
      .doc(_businessId)
      .collection(AppConstants.stockTransactionsCollection);

  void _emitLocal() {
    final list = _localProducts.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    _localStream.add(list);
  }

  Stream<List<Product>> productsStream() {
    if (!_firebaseEnabled) {
      return _localStream.stream;
    }
    return Stream<List<Product>>.multi((multi) {
      StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? productsSub;
      final businessSub = BusinessScope.changes.listen((_) {
        productsSub?.cancel();
        productsSub = _businessCol.orderBy('name').snapshots().listen(
          (s) => multi.add(s.docs.map(Product.fromFirestore).toList()),
          onError: multi.addError,
        );
      });
      multi.onCancel = () async {
        await productsSub?.cancel();
        await businessSub.cancel();
      };
    });
  }

  Future<Product?> fetchProduct(String id) async {
    if (!_firebaseEnabled) {
      return _localProducts[id];
    }
    final d = await _businessCol.doc(id).get();
    if (!d.exists) return null;
    return Product.fromFirestore(d);
  }

  Future<String> createProduct({
    required Map<String, dynamic> data,
    required String uid,
  }) async {
    final id = _uuid.v4();
    if (!_firebaseEnabled) {
      _localProducts[id] = Product(
        id: id,
        name: (data['name'] as String? ?? '').trim(),
        category: (data['category'] as String? ?? '').trim(),
        buyingPrice: (data['buyingPrice'] as num?)?.toDouble() ?? 0,
        sellingPrice: (data['sellingPrice'] as num?)?.toDouble() ?? 0,
        quantity: (data['quantity'] as num?)?.toInt() ?? 0,
        unit: (data['unit'] as String? ?? 'pcs').trim(),
        imageUrl: data['imageUrl'] as String?,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: uid,
      );
      _emitLocal();
      return id;
    }
    await _businessCol.doc(id).set({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': uid,
    });
    return id;
  }

  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    if (!_firebaseEnabled) {
      final current = _localProducts[id];
      if (current == null) throw StateError('Product not found');
      _localProducts[id] = Product(
        id: id,
        name: (data['name'] as String? ?? current.name).trim(),
        category: (data['category'] as String? ?? current.category).trim(),
        buyingPrice:
            (data['buyingPrice'] as num?)?.toDouble() ?? current.buyingPrice,
        sellingPrice:
            (data['sellingPrice'] as num?)?.toDouble() ?? current.sellingPrice,
        quantity: (data['quantity'] as num?)?.toInt() ?? current.quantity,
        unit: (data['unit'] as String? ?? current.unit).trim(),
        imageUrl: data.containsKey('imageUrl')
            ? data['imageUrl'] as String?
            : current.imageUrl,
        createdAt: current.createdAt,
        updatedAt: DateTime.now(),
        createdBy: current.createdBy,
      );
      _emitLocal();
      return;
    }
    return _businessCol.doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteProduct(String id) async {
    if (!_firebaseEnabled) {
      _localProducts.remove(id);
      _emitLocal();
      return;
    }
    return _businessCol.doc(id).delete();
  }

  /// Adds stock and writes a stock transaction (atomic batch).
  Future<void> stockIn({
    required String productId,
    required int qty,
    required String userId,
    String? note,
  }) async {
    if (qty <= 0) throw ArgumentError('Quantity must be positive');
    if (!_firebaseEnabled) {
      final p = _localProducts[productId];
      if (p == null) throw StateError('Product not found');
      _localProducts[productId] = Product(
        id: p.id,
        name: p.name,
        category: p.category,
        buyingPrice: p.buyingPrice,
        sellingPrice: p.sellingPrice,
        quantity: p.quantity + qty,
        unit: p.unit,
        imageUrl: p.imageUrl,
        createdAt: p.createdAt,
        updatedAt: DateTime.now(),
        createdBy: p.createdBy,
      );
      _localStockTransactions.add(
        StockTransaction.createMap(
          productId: productId,
          type: StockTxType.in_,
          quantity: qty,
          userId: userId,
          note: note,
        ),
      );
      _emitLocal();
      return;
    }
    final productRef = _businessCol.doc(productId);
    final txRef = _stockTxCol.doc(_uuid.v4());

    await _db!.runTransaction((transaction) async {
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
    if (!_firebaseEnabled) {
      final p = _localProducts[productId];
      if (p == null) throw StateError('Product not found');
      if (p.quantity < qty) {
        throw StateError('Insufficient stock');
      }
      _localProducts[productId] = Product(
        id: p.id,
        name: p.name,
        category: p.category,
        buyingPrice: p.buyingPrice,
        sellingPrice: p.sellingPrice,
        quantity: p.quantity - qty,
        unit: p.unit,
        imageUrl: p.imageUrl,
        createdAt: p.createdAt,
        updatedAt: DateTime.now(),
        createdBy: p.createdBy,
      );
      _localStockTransactions.add(
        StockTransaction.createMap(
          productId: productId,
          type: StockTxType.out,
          quantity: qty,
          userId: userId,
          note: 'Sale',
          relatedSaleId: saleId,
        ),
      );
      _emitLocal();
      return;
    }
    final productRef = _businessCol.doc(productId);
    final txRef = _stockTxCol.doc(_uuid.v4());

    await _db!.runTransaction((transaction) async {
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
