import '../../models/product.dart';
import '../../models/sale_item.dart';

/// Local, rule-based assistant service (API-ready abstraction).
class AIAssistantService {
  const AIAssistantService();

  String reply({
    required String question,
    required List<Product> products,
    required List<SaleItem> saleItems,
  }) {
    final q = question.toLowerCase();
    if (q.contains('low stock')) {
      final low = products.where((p) => p.isLowStock).toList()
        ..sort((a, b) => a.quantity.compareTo(b.quantity));
      if (low.isEmpty) return 'Great news: no product is currently in low stock.';
      final names = low.take(4).map((p) => '${p.name} (${p.quantity})').join(', ');
      return 'Low-stock products: $names. Consider restocking these first.';
    }

    if (q.contains('sold') || q.contains('top')) {
      if (saleItems.isEmpty) return 'No sales data yet. Complete some sales first.';
      final byProduct = <String, int>{};
      for (final item in saleItems) {
        byProduct[item.productName] = (byProduct[item.productName] ?? 0) + item.quantity;
      }
      final top = byProduct.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final best = top.first;
      return '${best.key} sold the most with ${best.value} units.';
    }

    if (q.contains('profit')) {
      final profit = saleItems.fold<double>(0, (sum, i) => sum + i.lineProfit);
      return 'Current estimated profit is ৳${profit.toStringAsFixed(2)}.';
    }

    if (q.contains('restock')) {
      final candidates = products
          .where((p) => p.quantity <= 5)
          .toList()
        ..sort((a, b) => a.quantity.compareTo(b.quantity));
      if (candidates.isEmpty) {
        return 'No urgent restock candidates right now.';
      }
      final c = candidates.first;
      return 'Restock ${c.name} first. It has only ${c.quantity} ${c.unit} left.';
    }

    return 'I can help with low stock, top sold products, profit, and restock suggestions.';
  }
}
