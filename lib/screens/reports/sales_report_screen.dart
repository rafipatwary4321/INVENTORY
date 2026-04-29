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
      return Scaffold(
        appBar: const PremiumAppBar(title: 'Sales report', subtitle: 'Revenue'),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF050C18), Color(0xFF0A1C35), Color(0xFF0F2F57)],
            ),
          ),
          child: const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: AnimatedFeatureHero(
                title: 'No Sales Data Yet',
                subtitle: 'Complete checkout to unlock live sales analytics.',
                icon: Icons.receipt_long_outlined,
                gradientColors: [Color(0xFF7A37FF), Color(0xFF13A7FF), Color(0xFF1DE2B0)],
                animationType: FeatureHeroAnimationType.reports,
              ),
            ),
          ),
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
            const AnimatedFeatureHero(
              title: 'Analytics Pulse',
              subtitle: 'Business trend visuals with live metric movement.',
              icon: Icons.bar_chart_rounded,
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
            _VisualChartCard(todayTotal: todayTotal, totalSales: totalSales),
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
            const SizedBox(height: 10),
            _ProfitLossIndicatorStrip(
              revenue: totalSales,
              estimatedCost: totalSales * 0.72,
            ),
            const SizedBox(height: 10),
            const _LowStockRiskVisualCard(),
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

class _VisualChartCard extends StatelessWidget {
  const _VisualChartCard({
    required this.todayTotal,
    required this.totalSales,
  });

  final double todayTotal;
  final double totalSales;

  @override
  Widget build(BuildContext context) {
    final ratio = totalSales <= 0 ? 0 : (todayTotal / totalSales).clamp(0, 1);
    return PremiumGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.show_chart_rounded),
            title: Text('Revenue trend'),
            subtitle: Text('Visual momentum card'),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 80,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6A37FF), Color(0xFF13A7FF), Color(0xFF19D49B)],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: ratio.toDouble(),
            minHeight: 7,
            borderRadius: BorderRadius.circular(999),
            backgroundColor: Colors.white.withValues(alpha: 0.1),
          ),
        ],
      ),
    );
  }
}

class _ProfitLossIndicatorStrip extends StatelessWidget {
  const _ProfitLossIndicatorStrip({
    required this.revenue,
    required this.estimatedCost,
  });

  final double revenue;
  final double estimatedCost;

  @override
  Widget build(BuildContext context) {
    final pnl = revenue - estimatedCost;
    return Row(
      children: [
        Expanded(
          child: _PillMetric(
            icon: Icons.trending_up_rounded,
            label: 'Profit',
            value: BdtFormatter.format(pnl),
            color: const Color(0xFF19D49B),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PillMetric(
            icon: Icons.trending_down_rounded,
            label: 'Cost',
            value: BdtFormatter.format(estimatedCost),
            color: const Color(0xFFFF5C8A),
          ),
        ),
      ],
    );
  }
}

class _PillMetric extends StatelessWidget {
  const _PillMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: color.withValues(alpha: 0.16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelSmall),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LowStockRiskVisualCard extends StatelessWidget {
  const _LowStockRiskVisualCard();

  @override
  Widget build(BuildContext context) {
    return PremiumGlassCard(
      borderColor: Colors.orangeAccent.withValues(alpha: 0.35),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [Color(0xFFFF8A3D), Color(0xFFFF5F8E)],
              ),
            ),
            child: const Icon(Icons.warning_amber_rounded, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Low stock risk card placeholder • connect to stock alerts stream.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
