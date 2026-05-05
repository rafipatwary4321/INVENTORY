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
      appBar: const NeonAppBar(
        title: 'Smart Business Insights',
        subtitle: 'AI patterns',
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: PremiumTokens.darkAnalyticsGradient),
        child: products.isEmpty && items.isEmpty
            ? const EmptyStatePremium(
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
                    return Column(
                      children: [
                        const AnimatedFeatureHero(
                          title: 'AI Insight Deck',
                          subtitle: 'Recommendations, risks, and growth patterns.',
                          icon: Icons.auto_graph_rounded,
                          gradientColors: [Color(0xFF7A37FF), Color(0xFF13A7FF), Color(0xFF1DE2B0)],
                          animationType: FeatureHeroAnimationType.ai,
                        ),
                        NeonGlassCard(
                          child: Row(
                            children: [
                              Icon(
                                Icons.date_range_outlined,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Date filter (coming soon): Today / 7 days / 30 days / Custom',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Colors.white.withValues(alpha: 0.88),
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        NeonGlassCard(
                          child: ListTile(
                            iconColor: const Color(0xFF22D3EE),
                            textColor: Colors.white,
                            leading: const Icon(Icons.auto_graph_rounded),
                            title: Text(
                              'AI trend board',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            subtitle: Text(
                              'Chart-style insight visual placeholder',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.78),
                                  ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  final insight = insights[i - 1];
                  return NeonGlassCard(
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
