import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/bdt_formatter.dart';
import '../../core/widgets/empty_state.dart';
import '../../providers/products_provider.dart';
import '../../providers/sales_provider.dart';
import '../../services/ai/analytics_service.dart';

class AdvancedAnalyticsScreen extends StatelessWidget {
  const AdvancedAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductsProvider>().products;
    final items = context.watch<SalesProvider>().saleItems;
    final analytics = const AnalyticsService().build(
      products: products,
      saleItems: items,
    );

    if (products.isEmpty && items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Advanced AI Analytics')),
        body: const EmptyState(
          title: 'No analytics data yet',
          subtitle: 'Add products and sales to see smart business intelligence.',
          icon: Icons.analytics_outlined,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Advanced AI Analytics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _MetricSection(title: 'Top selling products', metrics: analytics.topSelling),
          _MetricSection(title: 'Least selling products', metrics: analytics.leastSelling),
          _MetricSection(title: 'High profit products', metrics: analytics.highProfit),
          _ChartCard(
            title: 'Daily sales trend (mock)',
            child: _TrendLineChart(points: analytics.dailyTrend),
          ),
          _ChartCard(
            title: 'Weekly trend (mock)',
            child: _TrendBarChart(points: analytics.weeklyTrend),
          ),
          _ChartCard(
            title: 'Stock distribution',
            child: _TrendBarChart(points: analytics.stockDistribution),
          ),
          _AlertsCard(
            lowStock: analytics.lowStockAlerts,
            deadStock: analytics.deadStockAlerts,
            fastMoving: analytics.fastMovingAlerts,
          ),
        ],
      ),
    );
  }
}

class _MetricSection extends StatelessWidget {
  const _MetricSection({
    required this.title,
    required this.metrics,
  });

  final String title;
  final List<ProductMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            if (metrics.isEmpty)
              const Text('No data yet')
            else
              for (final m in metrics.take(4))
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '${m.productName}: sold ${m.unitsSold}, profit ${BdtFormatter.format(m.profit)}',
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 10),
            SizedBox(height: 200, child: child),
          ],
        ),
      ),
    );
  }
}

class _TrendLineChart extends StatelessWidget {
  const _TrendLineChart({required this.points});
  final List<TrendPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const Center(child: Text('No trend data'));
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= points.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(points[i].label, style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            barWidth: 3,
            color: Theme.of(context).colorScheme.primary,
            spots: [
              for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].value),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrendBarChart extends StatelessWidget {
  const _TrendBarChart({required this.points});
  final List<TrendPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const Center(child: Text('No data'));
    return BarChart(
      BarChartData(
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= points.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(points[i].label, style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < points.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: points[i].value,
                  width: 16,
                  borderRadius: BorderRadius.circular(4),
                  color: Theme.of(context).colorScheme.primaryContainer,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _AlertsCard extends StatelessWidget {
  const _AlertsCard({
    required this.lowStock,
    required this.deadStock,
    required this.fastMoving,
  });

  final List<String> lowStock;
  final List<String> deadStock;
  final List<String> fastMoving;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Smart alerts', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            ..._render('Low stock', lowStock),
            ..._render('Dead stock', deadStock),
            ..._render('Fast moving', fastMoving),
          ],
        ),
      ),
    );
  }

  List<Widget> _render(String title, List<String> values) {
    return [
      Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      if (values.isEmpty)
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text('No alert'),
        )
      else
        ...values.take(3).map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('- $e'),
              ),
            ),
      const SizedBox(height: 6),
    ];
  }
}
