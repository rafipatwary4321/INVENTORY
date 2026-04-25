import '../../models/product.dart';
import '../../models/sale_item.dart';

class SmartInsights {
  SmartInsights({
    required this.bestSelling,
    required this.slowMoving,
    required this.lowStockRisk,
    required this.profit,
    required this.tips,
  });

  final List<String> bestSelling;
  final List<String> slowMoving;
  final List<String> lowStockRisk;
  final double profit;
  final List<String> tips;
}

/// Computes lightweight business insights from local/Firebase-fed providers.
class SmartInsightsService {
  const SmartInsightsService();

  SmartInsights analyze({
    required List<Product> products,
    required List<SaleItem> saleItems,
  }) {
    final qtyByProduct = <String, int>{};
    for (final item in saleItems) {
      qtyByProduct[item.productName] = (qtyByProduct[item.productName] ?? 0) + item.quantity;
    }

    final soldList = qtyByProduct.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final best = soldList.take(3).map((e) => '${e.key} (${e.value} sold)').toList();
    final slow = soldList.reversed.take(3).map((e) => '${e.key} (${e.value} sold)').toList();

    final lowRisk = products
        .where((p) => p.isLowStock)
        .map((p) => '${p.name} (${p.quantity} ${p.unit})')
        .take(4)
        .toList();

    final profit = saleItems.fold<double>(0, (sum, i) => sum + i.lineProfit);
    final tips = _tips(products: products, saleItems: saleItems);

    return SmartInsights(
      bestSelling: best,
      slowMoving: slow,
      lowStockRisk: lowRisk,
      profit: profit,
      tips: tips,
    );
  }

  List<String> _tips({
    required List<Product> products,
    required List<SaleItem> saleItems,
  }) {
    final tips = <String>[];
    final low = products.where((p) => p.isLowStock).toList();
    if (low.isNotEmpty) {
      tips.add('${low.first.name} stock is low. Restock soon to avoid stockout.');
    }
    if (saleItems.isNotEmpty) {
      final top = <String, int>{};
      for (final s in saleItems) {
        top[s.productName] = (top[s.productName] ?? 0) + s.quantity;
      }
      final winner = top.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      if (winner.isNotEmpty) {
        tips.add('${winner.first.key} has strong demand. Keep extra buffer stock.');
      }
    }
    final highMargin = products.toList()
      ..sort((a, b) => (b.sellingPrice - b.buyingPrice).compareTo(a.sellingPrice - a.buyingPrice));
    if (highMargin.isNotEmpty) {
      tips.add('${highMargin.first.name} has a high margin. Promote it in POS.');
    }
    if (tips.isEmpty) tips.add('Add products and sales to unlock AI business tips.');
    return tips;
  }
}
