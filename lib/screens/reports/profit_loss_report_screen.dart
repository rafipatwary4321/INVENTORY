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
      body: ListView(
        padding: PremiumTokens.pagePadding(context),
        children: [
          const FeatureHeaderCard(
            title: 'Profit & Loss',
            subtitle: 'Compare revenue against cost of goods sold.',
            icon: Icons.trending_up_rounded,
            trailingIcon: Icons.account_balance_wallet_outlined,
          ),
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
                child: ReportCard(
                  child: ListTile(
                    title: Text(
                      'Sale ${entry.key.length > 8 ? entry.key.substring(0, 8) : entry.key}',
                    ),
                    trailing: Text(
                      BdtFormatter.format(entry.value),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ReportCard(
        child: ListTile(
          title: Text(label),
          trailing: Text(
            value,
            style: emphasize
                ? Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    )
                : Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ),
    );
  }
}
