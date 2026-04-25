import '../../models/product.dart';
import '../../models/sale_item.dart';

class RestockForecast {
  RestockForecast({
    required this.productId,
    required this.productName,
    required this.currentQty,
    required this.avgDailySales,
    required this.daysToStockout,
    required this.suggestedRestockQty,
    required this.reason,
  });

  final String productId;
  final String productName;
  final int currentQty;
  final double avgDailySales;
  final int daysToStockout;
  final int suggestedRestockQty;
  final String reason;
}

/// Predictive rule engine for restock and stockout windows.
class PredictionEngine {
  const PredictionEngine();

  List<RestockForecast> forecastRestock({
    required List<Product> products,
    required List<SaleItem> saleItems,
  }) {
    final soldByProduct = <String, int>{};
    for (final item in saleItems) {
      soldByProduct[item.productId] = (soldByProduct[item.productId] ?? 0) + item.quantity;
    }

    final result = <RestockForecast>[];
    for (final p in products) {
      final sold = soldByProduct[p.id] ?? 0;
      final avgDaily = sold <= 0 ? 0.2 : sold / 7;
      final days = avgDaily <= 0 ? 999 : (p.quantity / avgDaily).floor();
      final targetDaysCoverage = sold > 0 ? 21 : 14;
      final needed = ((avgDaily * targetDaysCoverage) - p.quantity).ceil();
      final suggestQty = needed < 0 ? 0 : needed;
      if (days > 21 && p.quantity > 6) continue;

      final reason = days <= 3
          ? 'Critical: stock may run out in ~${days.clamp(0, 999)} day(s)'
          : days <= 7
              ? 'Warning: stock may run out this week'
              : sold == 0
                  ? 'No sales yet; maintain minimal safety stock'
                  : 'Demand trend suggests upcoming stock pressure';

      result.add(
        RestockForecast(
          productId: p.id,
          productName: p.name,
          currentQty: p.quantity,
          avgDailySales: avgDaily,
          daysToStockout: days,
          suggestedRestockQty: suggestQty < 5 ? 5 : suggestQty,
          reason: reason,
        ),
      );
    }

    result.sort((a, b) => a.daysToStockout.compareTo(b.daysToStockout));
    return result;
  }
}
