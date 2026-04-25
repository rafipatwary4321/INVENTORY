import '../../models/product.dart';
import '../../models/sale_item.dart';

class InsightItem {
  const InsightItem({
    required this.title,
    required this.detail,
  });

  final String title;
  final String detail;
}

/// Rule-based business pattern detector.
class InsightsEngine {
  const InsightsEngine();

  List<InsightItem> generate({
    required List<Product> products,
    required List<SaleItem> saleItems,
  }) {
    final items = <InsightItem>[];
    final byProduct = <String, int>{};
    for (final s in saleItems) {
      byProduct[s.productName] = (byProduct[s.productName] ?? 0) + s.quantity;
    }
    if (byProduct.isNotEmpty) {
      final ranking = byProduct.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final top = ranking.first;
      items.add(
        InsightItem(
          title: '${top.key} sells consistently higher',
          detail: 'Pattern: strongest demand trend among current products.',
        ),
      );
      final low = ranking.last;
      if (ranking.length > 1) {
        items.add(
          InsightItem(
            title: '${low.key} has low turnover',
            detail: 'Consider promotions, bundling, or lower purchase volume.',
          ),
        );
      }
    }

    final lowStock = products.where((p) => p.quantity < 5).toList();
    if (lowStock.isNotEmpty) {
      items.add(
        InsightItem(
          title: 'Low stock risk detected',
          detail: '${lowStock.first.name} and ${lowStock.length - 1} others need attention.',
        ),
      );
    }

    if (items.isEmpty) {
      items.add(
        const InsightItem(
          title: 'Not enough data yet',
          detail: 'Add products and complete sales to unlock business insights.',
        ),
      );
    }
    return items;
  }
}
