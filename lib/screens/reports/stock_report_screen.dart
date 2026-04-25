import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/bdt_formatter.dart';
import '../../core/widgets/premium/premium_ui.dart';
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
      appBar: const PremiumAppBar(
        title: 'Stock report',
        subtitle: 'On-hand value',
      ),
      body: products.isEmpty
          ? const EmptyStateWidget(
              title: 'No products found',
              subtitle: 'Add products to see your stock report.',
              icon: Icons.inventory_2_outlined,
            )
          : Column(
              children: [
                Padding(
                  padding: PremiumTokens.pagePadding(context).copyWith(bottom: 8),
                  child: ReportCard(
                    child: ListTile(
                      title: const Text('Total inventory value (at cost)'),
                      subtitle: Text(
                        BdtFormatter.format(totalValue),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      trailing: Chip(
                        avatar:
                            const Icon(Icons.warning_amber_rounded, size: 16),
                        label: Text('Low: $lowStockCount'),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: PremiumTokens.pagePadding(context).copyWith(top: 0),
                    itemCount: products.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final p = products[i];
                      final low = p.quantity < AppConstants.lowStockThreshold;
                      return ReportCard(
                        child: ListTile(
                          leading: low
                              ? Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.deepOrange.shade400,
                                )
                              : const Icon(Icons.inventory_2_outlined),
                          title: Text(p.name),
                          subtitle: Text(
                            '${p.category} · ${p.unit}'
                            '${low ? ' · Low stock' : ''}',
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
