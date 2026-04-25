import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/premium/premium_ui.dart';
import '../../providers/products_provider.dart';
import '../../providers/sales_provider.dart';
import '../../services/ai/prediction_engine.dart';

class RestockPredictionScreen extends StatelessWidget {
  const RestockPredictionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductsProvider>().products;
    final items = context.watch<SalesProvider>().saleItems;
    final forecasts = const PredictionEngine().forecastRestock(
      products: products,
      saleItems: items,
    );

    return Scaffold(
      appBar: const PremiumAppBar(
        title: 'Predictive Restock',
        subtitle: 'Stockout risk',
      ),
      body: forecasts.isEmpty
          ? const EmptyStateWidget(
              title: 'No urgent restock suggestions',
              subtitle: 'AI will suggest products when stockout risk is detected.',
              icon: Icons.inventory_2_outlined,
            )
          : ListView.builder(
              padding: PremiumTokens.pagePadding(context),
              itemCount: forecasts.length,
              itemBuilder: (_, i) {
                final f = forecasts[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ReportCard(
                    child: ListTile(
                      leading: const Icon(Icons.trending_up),
                      title: Text(f.productName),
                      subtitle: Text(
                        'Current ${f.currentQty} · Avg/day ${f.avgDailySales.toStringAsFixed(1)}\n'
                        'Stockout ~${f.daysToStockout} day(s) · Suggest +${f.suggestedRestockQty}\n'
                        '${f.reason}',
                      ),
                      isThreeLine: true,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
