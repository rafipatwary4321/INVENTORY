import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/bdt_formatter.dart';
import '../../providers/products_provider.dart';

/// On-hand quantities and cost-based stock value per product.
class StockReportScreen extends StatelessWidget {
  const StockReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductsProvider>().products;
    final totalValue = products.fold<double>(0, (a, p) => a + p.stockValue);
    final lowStockCount = products
        .where((p) => p.quantity < AppConstants.lowStockThreshold)
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text('Stock report')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: ListTile(
                title: const Text('Total inventory value (at cost)'),
                subtitle: Text(
                  BdtFormatter.format(totalValue),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                trailing: Chip(
                  avatar: const Icon(Icons.warning_amber_rounded, size: 16),
                  label: Text('Low: $lowStockCount'),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final p = products[i];
                return Card(
                  color: p.quantity < AppConstants.lowStockThreshold
                      ? Colors.orange.shade50
                      : null,
                  child: ListTile(
                    title: Text(p.name),
                    subtitle: Text(
                      '${p.category} · ${p.unit}'
                      '${p.quantity < AppConstants.lowStockThreshold ? ' · Low stock' : ''}',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Qty ${p.quantity}'),
                        Text(BdtFormatter.format(p.stockValue)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
