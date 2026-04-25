import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/empty_state.dart';
import '../../providers/products_provider.dart';
import '../../providers/sales_provider.dart';
import '../../services/ai/restock_prediction_service.dart';

class RestockPredictionScreen extends StatelessWidget {
  const RestockPredictionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductsProvider>().products;
    final saleItems = context.watch<SalesProvider>().saleItems;
    final suggestions = const RestockPredictionService().suggest(
      products: products,
      saleItems: saleItems,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Restock Predictions')),
      body: suggestions.isEmpty
          ? const EmptyState(
              title: 'No urgent restock suggestions',
              subtitle: 'AI will suggest products when stock risk increases.',
              icon: Icons.inventory_2_outlined,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: suggestions.length,
              itemBuilder: (context, i) {
                final s = suggestions[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const Icon(Icons.auto_graph_outlined),
                    title: Text(s.productName),
                    subtitle: Text(
                      'Current: ${s.currentQty} · Suggested restock: +${s.suggestedQty}\n'
                      'Reason: ${s.reasons.join(', ')}',
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}
