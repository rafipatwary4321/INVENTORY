import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/utils/bdt_formatter.dart';
import '../../core/widgets/premium/premium_ui.dart';
import '../../models/sale.dart';
import '../../models/sale_item.dart';
import '../../providers/sales_provider.dart';

/// Today total + recent sales + sold item lines.
class SalesReportScreen extends StatelessWidget {
  const SalesReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sales = context.watch<SalesProvider>().sales;
    final items = context.watch<SalesProvider>().saleItems;
    final df = DateFormat.yMMMd();
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final totalSales = sales.fold<double>(0, (sum, s) => sum + s.totalAmount);
    final todayTotal = sales
        .where((s) => s.createdAt != null && !s.createdAt!.isBefore(todayStart))
        .fold<double>(0, (sum, s) => sum + s.totalAmount);
    if (sales.isEmpty && items.isEmpty) {
      return const Scaffold(
        appBar: PremiumAppBar(title: 'Sales report', subtitle: 'Revenue'),
        body: EmptyStateWidget(
          icon: Icons.receipt_long_outlined,
          title: 'No sales yet',
          subtitle: 'Complete a checkout to generate sales reports.',
        ),
      );
    }

    return Scaffold(
      appBar: const PremiumAppBar(
        title: 'Sales report',
        subtitle: 'Revenue & receipts',
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
              title: 'Sales Overview',
              subtitle: 'Track revenue trends and sold item activity.',
              icon: Icons.bar_chart_rounded,
              trailingIcon: Icons.receipt_long_outlined,
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
                leading: Icon(Icons.show_chart_rounded),
                title: Text('Revenue trend'),
                subtitle: Text('Chart-style visual placeholder for sales movement'),
              ),
            ),
            const SizedBox(height: 10),
            ReportSummaryCard(
              icon: Icons.summarize_outlined,
              title: 'Total sales amount',
              value: BdtFormatter.format(totalSales),
            ),
            const SizedBox(height: 10),
            ReportSummaryCard(
              icon: Icons.today_outlined,
              title: 'Today sales total',
              value: BdtFormatter.format(todayTotal),
            ),
            const SizedBox(height: 12),
            Text(
              'Sales',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            if (sales.isEmpty)
              ReportCard(
                child: ListTile(
                  title: Text(
                    'No sales recorded yet',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              )
            else
              ...sales.map((Sale s) {
                final when = s.createdAt != null ? df.format(s.createdAt!) : '—';
                final shortUser =
                    s.userId.length > 6 ? '${s.userId.substring(0, 6)}…' : s.userId;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: PremiumGlassCard(
                    child: ListTile(
                      title: Text(BdtFormatter.format(s.totalAmount)),
                      subtitle: Text('$when · ${s.itemCount} items · User $shortUser'),
                      trailing: const Icon(Icons.receipt_long_outlined),
                    ),
                  ),
                );
              }),
            const SizedBox(height: 12),
            Text(
              'Sold items',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              ReportCard(
                child: ListTile(
                  title: Text(
                    'No sold item lines yet',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              )
            else
              ...items.map((SaleItem item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: PremiumGlassCard(
                    child: ListTile(
                      title: Text(item.productName),
                      subtitle: Text(
                        '${BdtFormatter.format(item.unitPrice)} × ${item.quantity}',
                      ),
                      trailing: Text(
                        BdtFormatter.format(item.lineTotal),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
