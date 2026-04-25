import '../../models/product.dart';
import '../../models/sale_item.dart';

class ProductMetric {
  ProductMetric({
    required this.productId,
    required this.productName,
    required this.unitsSold,
    required this.revenue,
    required this.profit,
    required this.marginPct,
  });

  final String productId;
  final String productName;
  final int unitsSold;
  final double revenue;
  final double profit;
  final double marginPct;
}

class TrendPoint {
  const TrendPoint({
    required this.label,
    required this.value,
  });

  final String label;
  final double value;
}

class AnalyticsSnapshot {
  AnalyticsSnapshot({
    required this.topSelling,
    required this.leastSelling,
    required this.highProfit,
    required this.profitByProduct,
    required this.dailyTrend,
    required this.weeklyTrend,
    required this.stockDistribution,
    required this.lowStockAlerts,
    required this.deadStockAlerts,
    required this.fastMovingAlerts,
  });

  final List<ProductMetric> topSelling;
  final List<ProductMetric> leastSelling;
  final List<ProductMetric> highProfit;
  final List<ProductMetric> profitByProduct;
  final List<TrendPoint> dailyTrend;
  final List<TrendPoint> weeklyTrend;
  final List<TrendPoint> stockDistribution;
  final List<String> lowStockAlerts;
  final List<String> deadStockAlerts;
  final List<String> fastMovingAlerts;
}

/// Aggregates inventory and sales into BI-ready metrics.
class AnalyticsService {
  const AnalyticsService();

  AnalyticsSnapshot build({
    required List<Product> products,
    required List<SaleItem> saleItems,
  }) {
    final byProduct = <String, ProductMetric>{};
    for (final item in saleItems) {
      final existing = byProduct[item.productId];
      final nextUnits = (existing?.unitsSold ?? 0) + item.quantity;
      final nextRevenue = (existing?.revenue ?? 0) + item.lineTotal;
      final nextProfit = (existing?.profit ?? 0) + item.lineProfit;
      final marginPct =
          nextRevenue <= 0 ? 0.0 : (nextProfit / nextRevenue) * 100.0;
      byProduct[item.productId] = ProductMetric(
        productId: item.productId,
        productName: item.productName,
        unitsSold: nextUnits,
        revenue: nextRevenue,
        profit: nextProfit,
        marginPct: marginPct,
      );
    }

    final metrics = byProduct.values.toList();
    final topSelling = [...metrics]..sort((a, b) => b.unitsSold.compareTo(a.unitsSold));
    final highProfit = [...metrics]..sort((a, b) => b.profit.compareTo(a.profit));
    final leastSelling = [...metrics]..sort((a, b) => a.unitsSold.compareTo(b.unitsSold));

    final lowStock = products
        .where((p) => p.quantity < 5)
        .map((p) => '${p.name} low stock (${p.quantity} ${p.unit})')
        .toList();

    final deadStock = products
        .where((p) => !byProduct.containsKey(p.id) && p.quantity > 0)
        .map((p) => '${p.name} appears dead stock (no sales yet)')
        .toList();

    final fastMoving = topSelling
        .where((m) => m.unitsSold >= 5)
        .take(4)
        .map((m) => '${m.productName} is fast moving (${m.unitsSold} sold)')
        .toList();

    return AnalyticsSnapshot(
      topSelling: topSelling.take(5).toList(),
      leastSelling: leastSelling.take(5).toList(),
      highProfit: highProfit.take(5).toList(),
      profitByProduct: highProfit.take(8).toList(),
      dailyTrend: _mockDailyTrend(saleItems),
      weeklyTrend: _mockWeeklyTrend(saleItems),
      stockDistribution: _stockDistribution(products),
      lowStockAlerts: lowStock,
      deadStockAlerts: deadStock,
      fastMovingAlerts: fastMoving,
    );
  }

  List<TrendPoint> _mockDailyTrend(List<SaleItem> items) {
    final totalRevenue = items.fold<double>(0, (sum, i) => sum + i.lineTotal);
    final base = totalRevenue <= 0 ? 50 : totalRevenue / 7;
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final multipliers = [0.85, 0.92, 1.0, 1.08, 1.15, 1.22, 1.05];
    return List<TrendPoint>.generate(
      labels.length,
      (i) => TrendPoint(label: labels[i], value: base * multipliers[i]),
    );
  }

  List<TrendPoint> _mockWeeklyTrend(List<SaleItem> items) {
    final units = items.fold<int>(0, (sum, i) => sum + i.quantity).toDouble();
    final base = units <= 0 ? 20 : units / 4;
    return List<TrendPoint>.generate(
      4,
      (i) => TrendPoint(
        label: 'W${i + 1}',
        value: base * (0.9 + (i * 0.1)),
      ),
    );
  }

  List<TrendPoint> _stockDistribution(List<Product> products) {
    return products
        .take(8)
        .map(
          (p) => TrendPoint(
            label: p.name.length > 8 ? '${p.name.substring(0, 8)}…' : p.name,
            value: p.quantity.toDouble(),
          ),
        )
        .toList();
  }
}
