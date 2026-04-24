import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/sale.dart';
import '../models/sale_item.dart';
import '../services/sale_service.dart';

/// Recent sales + sale line items for dashboards and reports.
class SalesProvider extends ChangeNotifier {
  SalesProvider(this._service) {
    _salesSub = _service.salesStream().listen((s) {
      _sales = s;
      notifyListeners();
    });
    _itemsSub = _service.allSaleItemsStream().listen((i) {
      _items = i;
      notifyListeners();
    });
  }

  final SaleService _service;
  StreamSubscription<List<Sale>>? _salesSub;
  StreamSubscription<List<SaleItem>>? _itemsSub;

  List<Sale> _sales = [];
  List<SaleItem> _items = [];

  List<Sale> get sales => List.unmodifiable(_sales);
  List<SaleItem> get saleItems => List.unmodifiable(_items);

  @override
  void dispose() {
    _salesSub?.cancel();
    _itemsSub?.cancel();
    super.dispose();
  }
}
