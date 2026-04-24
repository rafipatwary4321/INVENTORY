import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/product.dart';
import '../services/product_service.dart';

/// Live product list from Firestore (kept in memory for screens).
class ProductsProvider extends ChangeNotifier {
  ProductsProvider(this._service) {
    _sub = _service.productsStream().listen((list) {
      _products = list;
      notifyListeners();
    });
  }

  final ProductService _service;
  StreamSubscription<List<Product>>? _sub;

  List<Product> _products = [];
  List<Product> get products => List.unmodifiable(_products);

  Product? byId(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
