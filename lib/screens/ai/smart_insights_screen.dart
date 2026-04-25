import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/premium/premium_ui.dart';
import '../../providers/products_provider.dart';
import '../../providers/sales_provider.dart';
import '../../services/ai/insights_engine.dart';

class SmartInsightsScreen extends StatelessWidget {
  const SmartInsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductsProvider>().products;
    final items = context.watch<SalesProvider>().saleItems;
    final insights = const InsightsEngine().generate(
      products: products,
      saleItems: items,
    );

    return Scaffold(
      appBar: const PremiumAppBar(
        title: 'Smart Business Insights',
        subtitle: 'AI patterns',
      ),
      body: products.isEmpty && items.isEmpty
          ? const EmptyStateWidget(
              title: 'No insight data yet',
              subtitle: 'Add products and sales to unlock AI pattern insights.',
              icon: Icons.insights_outlined,
            )
          : ListView.separated(
              padding: PremiumTokens.pagePadding(context),
              itemCount: insights.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final insight = insights[i];
                return AIInsightCard(
                  title: insight.title,
                  body: insight.detail,
                );
              },
            ),
    );
  }
}
