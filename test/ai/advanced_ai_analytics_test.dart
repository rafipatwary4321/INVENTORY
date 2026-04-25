import 'package:flutter_test/flutter_test.dart';
import 'package:inventory/models/product.dart';
import 'package:inventory/models/sale_item.dart';
import 'package:inventory/services/ai/ai_assistant_service.dart';
import 'package:inventory/services/ai/analytics_service.dart';
import 'package:inventory/services/ai/prediction_engine.dart';

Product _product({
  required String id,
  required String name,
  required int qty,
  required double buy,
  required double sell,
}) {
  return Product(
    id: id,
    name: name,
    category: 'General',
    buyingPrice: buy,
    sellingPrice: sell,
    quantity: qty,
    unit: 'pcs',
    imageUrl: null,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    createdBy: 'test',
  );
}

SaleItem _item({
  required String id,
  required String productId,
  required String name,
  required int qty,
  required double unitPrice,
  required double buyAtSale,
}) {
  return SaleItem(
    id: id,
    saleId: 's1',
    productId: productId,
    productName: name,
    unitPrice: unitPrice,
    quantity: qty,
    lineTotal: unitPrice * qty,
    buyingPriceAtSale: buyAtSale,
    createdAt: DateTime(2026, 1, 2),
  );
}

void main() {
  group('Advanced AI analytics', () {
    final products = [
      _product(id: 'p1', name: 'Oil', qty: 3, buy: 100, sell: 140),
      _product(id: 'p2', name: 'Rice', qty: 20, buy: 50, sell: 65),
      _product(id: 'p3', name: 'Onion', qty: 12, buy: 60, sell: 90),
      _product(id: 'p4', name: 'Sugar', qty: 8, buy: 70, sell: 85),
    ];

    final items = [
      _item(
        id: 'i1',
        productId: 'p1',
        name: 'Oil',
        qty: 8,
        unitPrice: 140,
        buyAtSale: 100,
      ),
      _item(
        id: 'i2',
        productId: 'p2',
        name: 'Rice',
        qty: 4,
        unitPrice: 65,
        buyAtSale: 50,
      ),
      _item(
        id: 'i3',
        productId: 'p3',
        name: 'Onion',
        qty: 6,
        unitPrice: 90,
        buyAtSale: 60,
      ),
    ];

    test('top selling and high profit products are calculated correctly', () {
      final snapshot = const AnalyticsService().build(
        products: products,
        saleItems: items,
      );

      expect(snapshot.topSelling.first.productName, 'Oil');
      expect(snapshot.topSelling.first.unitsSold, 8);
      expect(snapshot.highProfit.first.productName, 'Oil');
      expect(snapshot.highProfit.first.profit, closeTo(320, 0.001));
      expect(snapshot.dailyTrend.length, 7);
      expect(snapshot.weeklyTrend.length, 4);
    });

    test('smart alerts include low stock, dead stock and fast moving', () {
      final snapshot = const AnalyticsService().build(
        products: products,
        saleItems: items,
      );

      expect(
        snapshot.lowStockAlerts.any((a) => a.toLowerCase().contains('oil')),
        isTrue,
      );
      expect(
        snapshot.deadStockAlerts.any((a) => a.toLowerCase().contains('sugar')),
        isTrue,
      );
      expect(
        snapshot.fastMovingAlerts.any((a) => a.toLowerCase().contains('oil')),
        isTrue,
      );
    });

    test('predictive restock generates stockout-based suggestions', () {
      final forecast = const PredictionEngine().forecastRestock(
        products: products,
        saleItems: items,
      );

      expect(forecast, isNotEmpty);
      expect(forecast.first.productName, 'Oil');
      expect(forecast.first.daysToStockout, lessThanOrEqualTo(3));
      expect(forecast.first.suggestedRestockQty, greaterThan(0));
    });

    test('assistant answers key business intelligence queries', () {
      const assistant = AIAssistantService();

      final profitable = assistant.respond(
        query: 'Which product is most profitable?',
        products: products,
        saleItems: items,
      );
      expect(profitable.toLowerCase(), contains('oil'));

      final restock = assistant.respond(
        query: 'What should I restock?',
        products: products,
        saleItems: items,
      );
      expect(restock.toLowerCase(), contains('restock'));

      final lowStock = assistant.respond(
        query: 'Show low stock products',
        products: products,
        saleItems: items,
      );
      expect(lowStock.toLowerCase(), contains('low stock'));

      final bestSelling = assistant.respond(
        query: 'What is the best selling product?',
        products: products,
        saleItems: items,
      );
      expect(bestSelling.toLowerCase(), contains('top selling'));
    });
  });
}
