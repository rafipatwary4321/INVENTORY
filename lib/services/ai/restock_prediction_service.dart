import '../../models/product.dart';
import '../../models/sale_item.dart';

class RestockSuggestion {
  RestockSuggestion({
    required this.productId,
    required this.productName,
    required this.currentQty,
    required this.suggestedQty,
    required this.reasons,
  });

  final String productId;
  final String productName;
  final int currentQty;
  final int suggestedQty;
  final List<String> reasons;
}

/// Rule-based restock prediction (replaceable by ML/API model later).
class RestockPredictionService {
  const RestockPredictionService();

  List<RestockSuggestion> suggest({
    required List<Product> products,
    required List<SaleItem> saleItems,
  }) {
    final soldByProductId = <String, int>{};
    for (final item in saleItems) {
      soldByProductId[item.productId] = (soldByProductId[item.productId] ?? 0) + item.quantity;
    }

    final suggestions = <RestockSuggestion>[];
    for (final p in products) {
      final sold = soldByProductId[p.id] ?? 0;
      final reasons = <String>[];
      if (p.quantity <= 5) reasons.add('Low stock');
      if (sold >= 5) reasons.add('High sales');
      if (p.quantity <= 2) reasons.add('Low availability');
      if (reasons.isEmpty) continue;

      final target = (sold > 0 ? sold * 2 : 12).clamp(8, 100);
      final need = target - p.quantity;
      if (need <= 0) continue;
      suggestions.add(
        RestockSuggestion(
          productId: p.id,
          productName: p.name,
          currentQty: p.quantity,
          suggestedQty: need,
          reasons: reasons,
        ),
      );
    }

    suggestions.sort((a, b) => b.suggestedQty.compareTo(a.suggestedQty));
    return suggestions;
  }
}
