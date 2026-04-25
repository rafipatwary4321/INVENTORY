import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/app_constants.dart';
import '../core/context/business_scope.dart';
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
  SaleService({
    required FirebaseFirestore? firestore,
    required ProductService products,
    required bool firebaseEnabled,
  })  : _db = firestore,
        _products = products,
        _firebaseEnabled = firebaseEnabled {
    if (!_firebaseEnabled) {
      _emitLocalSales();
      _emitLocalItems();
    }
  }

  final FirebaseFirestore? _db;
  final ProductService _products;
  final bool _firebaseEnabled;
  final _uuid = const Uuid();
  final _localSalesStream = StreamController<List<Sale>>.broadcast();
  final _localItemsStream = StreamController<List<SaleItem>>.broadcast();

  static final List<Sale> _localSales = [];
  static final List<SaleItem> _localSaleItems = [];

  String get _businessId => BusinessScope.businessId;

  CollectionReference<Map<String, dynamic>> get _sales => _db!
      .collection(AppConstants.businessesCollection)
      .doc(_businessId)
      .collection(AppConstants.salesCollection);

  CollectionReference<Map<String, dynamic>> get _items => _db!
      .collection(AppConstants.businessesCollection)
      .doc(_businessId)
      .collection(AppConstants.saleItemsCollection);

  void _emitLocalSales() {
    final list = List<Sale>.from(_localSales)
      ..sort((a, b) {
        final ad = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });
    _localSalesStream.add(list);
  }

  void _emitLocalItems() {
    final list = List<SaleItem>.from(_localSaleItems)
      ..sort((a, b) {
        final ad = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });
    _localItemsStream.add(list);
  }

  /// Streams recent sales (newest first) for reports.
  Stream<List<Sale>> salesStream({int limit = 200}) {
    if (!_firebaseEnabled) {
      return _localSalesStream.stream;
    }
    return Stream<List<Sale>>.multi((multi) {
      StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? salesSub;
      final businessSub = BusinessScope.changes.listen((_) {
        salesSub?.cancel();
        salesSub = _sales
            .orderBy('createdAt', descending: true)
            .limit(limit)
            .snapshots()
            .listen(
          (s) => multi.add(s.docs.map(Sale.fromFirestore).toList()),
          onError: multi.addError,
        );
      });
      multi.onCancel = () async {
        await salesSub?.cancel();
        await businessSub.cancel();
      };
    });
  }

  Stream<List<SaleItem>> saleItemsForSale(String saleId) {
    if (!_firebaseEnabled) {
      return _localItemsStream.stream.map(
        (items) => items.where((i) => i.saleId == saleId).toList(),
      );
    }
    return _items
        .where('saleId', isEqualTo: saleId)
        .snapshots()
        .map((s) => s.docs.map(SaleItem.fromFirestore).toList());
  }

  /// All sale items for aggregation (reports) — client-side filter by date.
  /// Line items for P&L / sales reports (sorted newest first in Dart).
  Stream<List<SaleItem>> allSaleItemsStream({int limit = 500}) {
    if (!_firebaseEnabled) {
      return _localItemsStream.stream;
    }
    return Stream<List<SaleItem>>.multi((multi) {
      StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? itemsSub;
      final businessSub = BusinessScope.changes.listen((_) {
        itemsSub?.cancel();
        itemsSub = _items.limit(limit).snapshots().listen((s) {
          final list = s.docs.map(SaleItem.fromFirestore).toList();
          list.sort((a, b) {
            final ad = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bd = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bd.compareTo(ad);
          });
          multi.add(list);
        }, onError: multi.addError);
      });
      multi.onCancel = () async {
        await itemsSub?.cancel();
        await businessSub.cancel();
      };
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

    // Validate stock first so local and Firebase behavior stay consistent.
    for (final l in lines) {
      final product = await _products.fetchProduct(l.productId);
      if (product == null || product.quantity < l.quantity) {
        throw StateError('Insufficient stock for ${l.name}');
      }
    }

    if (_firebaseEnabled) {
      final batch = _db!.batch();
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
    } else {
      final now = DateTime.now();
      _localSales.add(
        Sale(
          id: saleId,
          totalAmount: total,
          itemCount: count,
          userId: userId,
          customerNote: customerNote,
          createdAt: now,
        ),
      );

      for (final l in lines) {
        _localSaleItems.add(
          SaleItem(
            id: _uuid.v4(),
            saleId: saleId,
            productId: l.productId,
            productName: l.name,
            unitPrice: l.unitPrice,
            quantity: l.quantity,
            lineTotal: l.lineTotal,
            buyingPriceAtSale: l.buyingPrice,
            createdAt: now,
          ),
        );
      }
      _emitLocalSales();
      _emitLocalItems();
    }

    // Reduce stock only after sale persistence succeeds.
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
