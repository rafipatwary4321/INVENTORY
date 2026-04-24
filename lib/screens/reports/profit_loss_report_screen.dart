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
    double revenue = 0;
    double cost = 0;
    for (final SaleItem i in items) {
      revenue += i.lineTotal;
      cost += i.buyingPriceAtSale * i.quantity;
    }
    final profit = revenue - cost;

    return Scaffold(
      appBar: AppBar(title: const Text('Profit / Loss')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
              label: 'Gross profit',
              value: BdtFormatter.format(profit),
              emphasize: true,
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
