import '../../models/product.dart';
import '../../models/sale_item.dart';
import 'analytics_service.dart';
import 'prediction_engine.dart';

/// Local NLP-lite assistant for BI questions.
class AIAssistantService {
  const AIAssistantService();

  String respond({
    required String query,
    required List<Product> products,
    required List<SaleItem> saleItems,
  }) {
    final q = query.toLowerCase();
    final analytics = const AnalyticsService().build(
      products: products,
      saleItems: saleItems,
    );
    final forecast = const PredictionEngine().forecastRestock(
      products: products,
      saleItems: saleItems,
    );

    if (q.contains('most profitable') || q.contains('high margin') || q.contains('profit')) {
      if (analytics.highProfit.isEmpty) return 'No profit data yet. Complete a few sales first.';
      final p = analytics.highProfit.first;
      return '${p.productName} is most profitable now (profit ৳${p.profit.toStringAsFixed(2)}, margin ${p.marginPct.toStringAsFixed(1)}%).';
    }

    if (q.contains('restock') || q.contains('stock out') || q.contains('run out')) {
      if (forecast.isEmpty) return 'No urgent restock requirement detected right now.';
      final f = forecast.first;
      return 'Restock ${f.productName} first. It may run out in about ${f.daysToStockout} day(s). Suggested qty: +${f.suggestedRestockQty}.';
    }

    if (q.contains('top selling') || q.contains('best selling')) {
      if (analytics.topSelling.isEmpty) return 'No sales records yet.';
      final t = analytics.topSelling.first;
      return '${t.productName} is top selling with ${t.unitsSold} units sold.';
    }

    if (q.contains('least selling') || q.contains('low turnover')) {
      if (analytics.leastSelling.isEmpty) return 'No sales records yet.';
      final t = analytics.leastSelling.first;
      return '${t.productName} has the lowest turnover at ${t.unitsSold} unit(s).';
    }

    if (q.contains('alert') || q.contains('low stock')) {
      if (analytics.lowStockAlerts.isEmpty) return 'No low stock alerts currently.';
      return analytics.lowStockAlerts.take(3).join(' | ');
    }

    return 'Try asking: "Which product is most profitable?", "What should I restock?", "Top selling product?", or "Low stock alerts".';
  }
}
