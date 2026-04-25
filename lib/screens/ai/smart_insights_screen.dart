import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/empty_state.dart';
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
      appBar: AppBar(title: const Text('Smart Business Insights')),
      body: products.isEmpty && items.isEmpty
          ? const EmptyState(
              title: 'No insight data yet',
              subtitle: 'Add products and sales to unlock AI pattern insights.',
              icon: Icons.insights_outlined,
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: insights.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final insight = insights[i];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.auto_awesome_outlined),
                    title: Text(insight.title),
                    subtitle: Text(insight.detail),
                  ),
                );
              },
            ),
    );
  }
}
