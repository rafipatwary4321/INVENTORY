import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/utils/bdt_formatter.dart';
import '../../models/sale.dart';
import '../../providers/sales_provider.dart';

/// Lists recent sales with running total (BDT).
class SalesReportScreen extends StatelessWidget {
  const SalesReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sales = context.watch<SalesProvider>().sales;
    final df = DateFormat.yMMMd();

    return Scaffold(
      appBar: AppBar(title: const Text('Sales report')),
      body: sales.isEmpty
          ? const Center(child: Text('No sales recorded yet'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: sales.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final Sale s = sales[i];
                final when = s.createdAt != null ? df.format(s.createdAt!) : '—';
                return Card(
                  child: ListTile(
                    title: Text(BdtFormatter.format(s.totalAmount)),
                    subtitle: Text(
                      '$when · ${s.itemCount} items · User ${s.userId.substring(0, 6)}…',
                    ),
                    trailing: const Icon(Icons.receipt_long_outlined),
                  ),
                );
              },
            ),
    );
  }
}
