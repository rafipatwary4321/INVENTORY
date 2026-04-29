import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/bdt_formatter.dart';
import '../../core/widgets/premium/premium_ui.dart';
import '../../models/sale_item.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sales_provider.dart';

/// Approximate profit from recorded sale line items (revenue − cost at sale time).
class ProfitLossReportScreen extends StatelessWidget {
  const ProfitLossReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final canView = context.watch<AuthProvider>().canViewProfitLoss;
    if (!canView) {
      return const Scaffold(
        appBar: PremiumAppBar(title: 'Profit / Loss'),
        body: EmptyStateWidget(
          icon: Icons.lock_outline_rounded,
          title: 'Access restricted',
          subtitle:
              'Only owner or admin can view profit and loss reports for this business.',
        ),
      );
    }
    final items = context.watch<SalesProvider>().saleItems;
    final Map<String, double> profitBySale = {};
    double revenue = 0;
    double cost = 0;
    for (final SaleItem i in items) {
      revenue += i.lineTotal;
      cost += i.buyingPriceAtSale * i.quantity;
      profitBySale[i.saleId] = (profitBySale[i.saleId] ?? 0) + i.lineProfit;
    }
    if (items.isEmpty) {
      return const Scaffold(
        appBar: PremiumAppBar(title: 'Profit / Loss'),
        body: EmptyStateWidget(
          title: 'No profit data yet',
          subtitle: 'Sell products first to see profit and loss analytics.',
          icon: Icons.trending_up,
        ),
      );
    }
    final profit = revenue - cost;
    final perSaleEntries = profitBySale.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: const PremiumAppBar(
        title: 'Profit / Loss',
        subtitle: 'Revenue vs cost',
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF050C18), Color(0xFF0A1C35), Color(0xFF0F2F57)],
          ),
        ),
        child: ListView(
          padding: PremiumTokens.pagePadding(context),
          children: [
            const FeatureHeaderCard(
              title: 'Profit & Loss',
              subtitle: 'Compare revenue against cost of goods sold.',
              icon: Icons.trending_up_rounded,
              trailingIcon: Icons.account_balance_wallet_outlined,
            ),
            const AnimatedFeatureHero(
              title: 'Profit Signal',
              subtitle: 'Revenue, cost, and margin dynamics visualized.',
              icon: Icons.stacked_line_chart_rounded,
              gradientColors: [Color(0xFF7A37FF), Color(0xFF13A7FF), Color(0xFF1DE2B0)],
              animationType: FeatureHeroAnimationType.reports,
            ),
            PremiumGlassCard(
              child: Row(
                children: const [
                  Icon(Icons.date_range_outlined),
                  SizedBox(width: 10),
                  Expanded(child: Text('Date filter (coming soon): Today / 7 days / 30 days / Custom')),
                ],
              ),
            ),
            const SizedBox(height: 10),
            PremiumGlassCard(
              child: const ListTile(
                leading: Icon(Icons.stacked_line_chart_rounded),
                title: Text('Profit trend'),
                subtitle: Text('Chart-style visual placeholder for revenue vs cost'),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Based on loaded sale lines (${items.length}). '
              'For large datasets, add server-side aggregation.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            _MetricTile(label: 'Revenue (selling)', value: BdtFormatter.format(revenue)),
            _MetricTile(label: 'Cost of goods sold', value: BdtFormatter.format(cost)),
            const Divider(height: 32),
            _MetricTile(
              label: 'Total profit',
              value: BdtFormatter.format(profit),
              emphasize: true,
              isPositive: profit >= 0,
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: ReportSummaryCard(
                    icon: Icons.arrow_upward_rounded,
                    title: 'Revenue',
                    value: BdtFormatter.format(revenue),
                    valueColor: const Color(0xFF1DE2B0),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ReportSummaryCard(
                    icon: Icons.arrow_downward_rounded,
                    title: 'Cost',
                    value: BdtFormatter.format(cost),
                    valueColor: const Color(0xFFFF6B9A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ReportSummaryCard(
              icon: Icons.assessment_outlined,
              title: 'Profit status',
              value: profit >= 0 ? 'Positive' : 'Negative',
              valueColor: profit >= 0 ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 12),
            Text(
              'Profit per sale',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            if (perSaleEntries.isEmpty)
              ReportCard(
                child: ListTile(
                  title: Text(
                    'No sale lines available yet',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              )
            else
              ...perSaleEntries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: PremiumGlassCard(
                    child: ListTile(
                      title: Text(
                        'Sale ${entry.key.length > 8 ? entry.key.substring(0, 8) : entry.key}',
                      ),
                      trailing: Text(
                        BdtFormatter.format(entry.value),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: entry.value >= 0 ? Colors.green : Colors.red,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    this.emphasize = false,
    this.isPositive = true,
  });

  final String label;
  final String value;
  final bool emphasize;
  final bool isPositive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PremiumGlassCard(
        child: ListTile(
          title: Text(label),
          trailing: Text(
            value,
            style: emphasize
                ? Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isPositive ? Colors.green : Colors.red,
                    )
                : Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ),
    );
  }
}
