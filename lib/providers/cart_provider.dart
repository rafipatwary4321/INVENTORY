import 'package:flutter/foundation.dart';

import '../services/sale_service.dart';

/// In-memory POS cart (not persisted).
class CartProvider extends ChangeNotifier {
  final Map<String, CartLine> _lines = {};

  List<CartLine> get lines => _lines.values.toList();

  bool get isEmpty => _lines.isEmpty;

  double get subtotal =>
      _lines.values.fold(0.0, (sum, l) => sum + l.lineTotal);

  int countFor(String productId) => _lines[productId]?.quantity ?? 0;

  void addOrUpdate({
    required String productId,
    required String name,
    required double unitPrice,
    required double buyingPrice,
    int addQty = 1,
  }) {
    final existing = _lines[productId];
    if (existing == null) {
      _lines[productId] = CartLine(
        productId: productId,
        name: name,
        unitPrice: unitPrice,
        buyingPrice: buyingPrice,
        quantity: addQty,
      );
    } else {
      _lines[productId] = CartLine(
        productId: productId,
        name: name,
        unitPrice: unitPrice,
        buyingPrice: buyingPrice,
        quantity: existing.quantity + addQty,
      );
    }
    notifyListeners();
  }

  void setQuantity(String productId, int qty) {
    if (!_lines.containsKey(productId)) return;
    if (qty < 1) {
      _lines.remove(productId);
    } else {
      final l = _lines[productId]!;
      _lines[productId] = CartLine(
        productId: l.productId,
        name: l.name,
        unitPrice: l.unitPrice,
        buyingPrice: l.buyingPrice,
        quantity: qty,
      );
    }
    notifyListeners();
  }

  void removeLine(String productId) {
    _lines.remove(productId);
    notifyListeners();
  }

  void clear() {
    _lines.clear();
    notifyListeners();
  }
}
