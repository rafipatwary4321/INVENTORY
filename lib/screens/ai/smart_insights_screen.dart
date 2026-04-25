import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/bdt_formatter.dart';
import '../../core/widgets/empty_state.dart';
import '../../providers/products_provider.dart';
import '../../providers/sales_provider.dart';
import '../../services/ai/smart_insights_service.dart';

class SmartInsightsScreen extends StatelessWidget {
  const SmartInsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductsProvider>().products;
    final items = context.watch<SalesProvider>().saleItems;
    final insights = const SmartInsightsService().analyze(
      products: products,
      saleItems: items,
    );

    if (products.isEmpty && items.isEmpty) {
      return const Scaffold(
        body: EmptyState(
          title: 'No insights yet',
          subtitle: 'Add products and sales to unlock AI-powered insights.',
          icon: Icons.insights_outlined,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Smart Insights')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InsightCard(
            title: 'Profit insight',
            icon: Icons.account_balance_wallet_outlined,
            items: ['Estimated profit: ${BdtFormatter.format(insights.profit)}'],
          ),
          _InsightCard(
            title: 'Best selling products',
            icon: Icons.trending_up,
            items: insights.bestSelling.isEmpty
                ? const ['No sales yet']
                : insights.bestSelling,
          ),
          _InsightCard(
            title: 'Slow moving products',
            icon: Icons.trending_down,
            items: insights.slowMoving.isEmpty
                ? const ['No data yet']
                : insights.slowMoving,
          ),
          _InsightCard(
            title: 'Low stock risk',
            icon: Icons.warning_amber_rounded,
            items: insights.lowStockRisk.isEmpty
                ? const ['No immediate stock risk']
                : insights.lowStockRisk,
          ),
          _InsightCard(
            title: 'AI business tips',
            icon: Icons.lightbulb_outline,
            items: insights.tips,
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.title,
    required this.icon,
    required this.items,
  });

  final String title;
  final IconData icon;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('- $item'),
              ),
          ],
        ),
      ),
    );
  }
}
