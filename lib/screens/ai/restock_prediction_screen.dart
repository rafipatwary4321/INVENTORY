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
      appBar: const NeonAppBar(
        title: 'Predictive Restock',
        subtitle: 'Stockout risk',
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B0F1A), Color(0xFF101B32), Color(0xFF162643)],
          ),
        ),
        child: forecasts.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: AnimatedFeatureHero(
                    title: 'No Urgent Restock',
                    subtitle: 'AI will recommend restock when stockout risk rises.',
                    icon: Icons.inventory_2_outlined,
                    gradientColors: [Color(0xFF7A37FF), Color(0xFF13A7FF), Color(0xFF1DE2B0)],
                    animationType: FeatureHeroAnimationType.ai,
                  ),
                ),
              )
            : ListView.builder(
                padding: PremiumTokens.pagePadding(context),
                itemCount: forecasts.length,
                itemBuilder: (_, i) {
                  final f = forecasts[i];
                  final riskColor = f.daysToStockout <= 2
                      ? Colors.red
                      : (f.daysToStockout <= 5 ? Colors.orange : Colors.green);
                  final riskLabel = f.daysToStockout <= 2
                      ? 'High risk'
                      : (f.daysToStockout <= 5 ? 'Medium risk' : 'Low risk');
                  return TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 220),
                    tween: Tween(begin: 0.98, end: 1),
                    curve: Curves.easeOut,
                    builder: (context, value, child) => Transform.scale(scale: value, child: child),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: NeonGlassCard(
                        borderColor: riskColor.withValues(alpha: 0.35),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.trending_up),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    f.productName,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: riskColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    riskLabel,
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                          color: riskColor,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      riskColor.withValues(alpha: 0.45),
                                      riskColor,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Current ${f.currentQty} · Avg/day ${f.avgDailySales.toStringAsFixed(1)}\n'
                              'Stockout ~${f.daysToStockout} day(s) · Suggest +${f.suggestedRestockQty}\n'
                              '${f.reason}',
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
