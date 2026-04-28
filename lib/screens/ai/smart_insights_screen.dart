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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF050C18), Color(0xFF0A1C35), Color(0xFF0F2F57)],
          ),
        ),
        child: products.isEmpty && items.isEmpty
            ? const EmptyStateVisual(
                title: 'No insight data yet',
                subtitle: 'Add products and sales to unlock AI pattern insights.',
                icon: Icons.insights_outlined,
              )
            : ListView.separated(
                padding: PremiumTokens.pagePadding(context),
                itemCount: insights.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  if (i == 0) {
                    return const PremiumGlassCard(
                      child: ListTile(
                        leading: Icon(Icons.auto_graph_rounded),
                        title: Text('AI trend board'),
                        subtitle: Text('Chart-style insight visual placeholder'),
                      ),
                    );
                  }
                  final insight = insights[i - 1];
                  return PremiumGlassCard(
                    borderColor: Colors.cyanAccent.withValues(alpha: 0.3),
                    child: AIInsightCard(
                      title: insight.title,
                      body: insight.detail,
                    ),
                  );
                },
              ),
      ),
    );
  }
}
