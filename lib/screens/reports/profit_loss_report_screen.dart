import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/bdt_formatter.dart';
import '../../models/sale_item.dart';
import '../../providers/sales_provider.dart';

/// Approximate profit from recorded sale line items (revenue − cost at sale time).
class ProfitLossReportScreen extends StatelessWidget {
  const ProfitLossReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = context.watch<SalesProvider>().saleItems;
    final Map<String, double> profitBySale = {};
    double revenue = 0;
    double cost = 0;
    for (final SaleItem i in items) {
      revenue += i.lineTotal;
      cost += i.buyingPriceAtSale * i.quantity;
      profitBySale[i.saleId] = (profitBySale[i.saleId] ?? 0) + i.lineProfit;
    }
    final profit = revenue - cost;
    final perSaleEntries = profitBySale.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(title: const Text('Profit / Loss')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
            const Card(
              child: ListTile(title: Text('No sale lines available yet')),
            )
          else
            ...perSaleEntries.map(
              (entry) => Card(
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
    return Card(
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
    );
  }
}
