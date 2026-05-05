import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/bdt_formatter.dart';
import '../../core/widgets/premium/premium_ui.dart';
import '../../models/qr_scan_args.dart';
import '../../models/sale.dart';
import '../../providers/auth_provider.dart';
import '../../providers/products_provider.dart';
import '../../providers/sales_provider.dart';
import '../../providers/settings_provider.dart';
import '../../routes/app_router.dart';

/// Home hub: KPI cards + shortcuts to major flows.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final products = context.watch<ProductsProvider>().products;
    final List<Sale> sales = context.watch<SalesProvider>().sales;
    final settings = context.watch<SettingsProvider?>()?.settings;
    final user = auth.appUser;

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todaySales = sales.where((s) {
      final c = s.createdAt;
      if (c == null) return false;
      return !c.isBefore(todayStart);
    }).fold<double>(0, (a, b) => a + b.totalAmount);

    final totalStockQty = products.fold<int>(
      0,
      (a, p) => a + p.quantity,
    );
    final lowStock = products
        .where((p) => p.quantity < AppConstants.lowStockThreshold)
        .length;
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width >= 1200
        ? 4
        : width >= 880
            ? 3
            : width >= 560
                ? 2
                : 1;
    final cardRatio = width >= 1200
        ? 1.2
        : width >= 880
            ? 1.15
            : width >= 560
                ? 1.06
                : 1.35;
    final quickActions = <_QuickActionItem>[
      _QuickActionItem(
        icon: Icons.add_box_outlined,
        label: 'Add Product',
        subtitle: auth.isAdmin ? 'Create a new inventory item' : 'Admin only',
        onTap: auth.isAdmin
            ? () => Navigator.pushNamed(context, AppRoutes.productAdd)
            : null,
      ),
      _QuickActionItem(
        icon: Icons.qr_code_scanner_rounded,
        label: 'Stock In',
        subtitle: 'Receive stock from labels',
        onTap: () async {
          final result = await Navigator.pushNamed(
            context,
            AppRoutes.qrScan,
            arguments: QRScanArgs(mode: QRScanMode.stockIn),
          );
          final id = result as String?;
          if (!context.mounted || id == null) return;
          Navigator.pushNamed(context, AppRoutes.stockIn, arguments: id);
        },
      ),
      _QuickActionItem(
        icon: Icons.shopping_cart_checkout,
        label: 'Sell / POS',
        subtitle: 'Checkout and cart',
        onTap: () => Navigator.pushNamed(context, AppRoutes.sell),
      ),
      _QuickActionItem(
        icon: Icons.chat_bubble_outline_rounded,
        label: 'AI Assistant',
        onTap: () => Navigator.pushNamed(context, AppRoutes.aiAssistant),
      ),
    ];
    final stockHealth = products.isEmpty
        ? 1.0
        : ((products.length - lowStock) / products.length).clamp(0, 1).toDouble();
    final recentSales = sales.take(5).toList();
    return Scaffold(
      appBar: null,
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedGradientBackground()),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.32),
                    Colors.black.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                  stops: const [0, 0.28, 0.6],
                ),
              ),
            ),
          ),
          ListView(
            padding: PremiumTokens.pagePadding(context),
            children: [
              _TopDashboardBar(
                businessName: settings?.businessName ?? 'My Business',
                userName: user?.displayName ?? 'User',
                onSearchTap: () {},
                onNotificationTap: () {},
                onSettingsTap: () => Navigator.pushNamed(context, AppRoutes.settings),
              ),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: cardRatio,
                children: [
                  _DashboardStatCard(
                    title: 'Total Products',
                    value: '${products.length}',
                    icon: Icons.category_outlined,
                    accentColor: const Color(0xFF3B82F6),
                    subtitle: 'Inventory size',
                    subtitleColor: const Color(0xFF22D3EE),
                  ),
                  _DashboardStatCard(
                    title: 'Today sales',
                    value: BdtFormatter.format(todaySales),
                    icon: Icons.point_of_sale,
                    accentColor: const Color(0xFFA855F7),
                    subtitle: '$totalStockQty units on hand',
                    subtitleColor: const Color(0xFF22D3EE),
                  ),
                  _DashboardStatCard(
                    title: 'Low stock',
                    value: '$lowStock',
                    icon: Icons.warning_amber_rounded,
                    accentColor: const Color(0xFFF97316),
                    subtitle: lowStock > 0 ? 'Action needed' : 'Healthy',
                    subtitleColor: lowStock > 0 ? const Color(0xFFF97316) : Colors.greenAccent,
                  ),
                  _DashboardStatCard(
                    title: 'Profit',
                    value: auth.canViewProfitLoss
                        ? BdtFormatter.format(todaySales * 0.28)
                        : 'Locked',
                    icon: Icons.trending_up_rounded,
                    accentColor: const Color(0xFF22D3EE),
                    subtitle: auth.canViewProfitLoss ? 'Est. today margin' : 'Owner/Admin only',
                    subtitleColor: auth.canViewProfitLoss ? Colors.greenAccent : Colors.white70,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Analytics',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 900;
                  if (!isWide) {
                    return Column(
                      children: [
                        _SalesLineChartCard(todaySales: todaySales),
                        const SizedBox(height: 10),
                        _CategoryPieChartCard(
                          inStock: products.length - lowStock,
                          lowStock: lowStock,
                        ),
                        const SizedBox(height: 10),
                        _ProfitSummaryCard(
                          canViewProfit: auth.canViewProfitLoss,
                          todaySales: todaySales,
                        ),
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: _SalesLineChartCard(todaySales: todaySales),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: _CategoryPieChartCard(
                          inStock: products.length - lowStock,
                          lowStock: lowStock,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _StockDistributionCard(stockHealth: stockHealth),
                            const SizedBox(height: 10),
                            _ProfitSummaryCard(
                              canViewProfit: auth.canViewProfitLoss,
                              todaySales: todaySales,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),
              Text(
                'Quick actions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) {
                  final actionCols = constraints.maxWidth >= 1020
                      ? 4
                      : constraints.maxWidth >= 560
                          ? 2
                          : 1;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: quickActions.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: actionCols,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: actionCols == 4 ? 1.4 : actionCols == 2 ? 1.25 : 2.4,
                    ),
                    itemBuilder: (context, i) {
                      final item = quickActions[i];
                      return _BigQuickActionCard(item: item);
                    },
                  );
                },
              ),
              const SizedBox(height: 14),
              if (lowStock > 0)
                _LowStockAlertCard(
                  lowStock: lowStock,
                  threshold: AppConstants.lowStockThreshold,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.reportStock),
                ),
              AIInsightCard(
                title: 'AI insight preview',
                body: lowStock > 0
                    ? '$lowStock product(s) are under threshold. Open Smart Insights for prioritized restock recommendations.'
                    : 'Stock is currently healthy. Open AI analytics for demand and sales trend predictions.',
                icon: lowStock > 0 ? Icons.auto_awesome_rounded : Icons.psychology_alt_outlined,
              ),
              const SizedBox(height: 10),
              _RecentActivityCard(sales: recentSales),
              const SizedBox(height: 24),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopDashboardBar extends StatelessWidget {
  const _TopDashboardBar({
    required this.businessName,
    required this.userName,
    required this.onSearchTap,
    required this.onNotificationTap,
    required this.onSettingsTap,
  });

  final String businessName;
  final String userName;
  final VoidCallback onSearchTap;
  final VoidCallback onNotificationTap;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 760;
        Widget iconBtn(IconData icon, VoidCallback onTap) {
          return IconButton.filledTonal(
            style: IconButton.styleFrom(
              backgroundColor: const Color(0x33111827),
              foregroundColor: Colors.white,
            ),
            onPressed: onTap,
            icon: Icon(icon),
          );
        }

        final textSection = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${userName.isEmpty ? 'Owner' : userName}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              businessName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        );
        final actionSection = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconBtn(Icons.search_rounded, onSearchTap),
            const SizedBox(width: 8),
            iconBtn(Icons.notifications_none_rounded, onNotificationTap),
            const SizedBox(width: 8),
            iconBtn(Icons.settings_outlined, onSettingsTap),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: cs.primaryContainer.withValues(alpha: 0.95),
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'O',
                style: TextStyle(
                  color: cs.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );

        return isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: textSection),
                  const SizedBox(width: 12),
                  actionSection,
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  textSection,
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: actionSection.children,
                  ),
                ],
              );
      },
    );
  }
}

class _DashboardStatCard extends StatelessWidget {
  const _DashboardStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
    required this.subtitle,
    required this.subtitleColor,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;
  final String subtitle;
  final Color subtitleColor;

  @override
  Widget build(BuildContext context) {
    return NeonGlassCard(
      padding: const EdgeInsets.all(14),
      child: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontWeight: FontWeight.w700,
                  ),
            ),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: subtitleColor,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SalesLineChartCard extends StatelessWidget {
  const _SalesLineChartCard({required this.todaySales});

  final double todaySales;

  @override
  Widget build(BuildContext context) {
    return NeonChartCard(
      title: 'Sales Overview',
      subtitle: 'Today / This week',
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF22D3EE).withValues(alpha: 0.18),
              const Color(0xFF3B82F6).withValues(alpha: 0.15),
            ],
          ),
          border: Border.all(color: const Color(0x5522D3EE)),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
                child: CustomPaint(
                  painter: _LineChartPainter(),
                ),
              ),
            ),
            Positioned(
              right: 10,
              top: 8,
              child: Text(
                BdtFormatter.format(todaySales),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryPieChartCard extends StatelessWidget {
  const _CategoryPieChartCard({
    required this.inStock,
    required this.lowStock,
  });

  final int inStock;
  final int lowStock;

  @override
  Widget build(BuildContext context) {
    final total = (inStock + lowStock).clamp(1, 999999);
    final lowRatio = (lowStock / total).clamp(0, 1).toDouble();
    return NeonChartCard(
      title: 'Category / Stock Distribution',
      subtitle: 'Stock health split',
      child: Row(
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: 1 - lowRatio,
                  strokeWidth: 12,
                  backgroundColor: Colors.deepOrange.withValues(alpha: 0.28),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF22D3EE)),
                ),
                Text(
                  '${((1 - lowRatio) * 100).round()}%',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LegendLine(
                  color: const Color(0xFF22D3EE),
                  label: 'In stock',
                  value: '$inStock',
                ),
                const SizedBox(height: 8),
                _LegendLine(
                  color: Colors.deepOrangeAccent,
                  label: 'Low stock',
                  value: '$lowStock',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendLine extends StatelessWidget {
  const _LegendLine({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}

class _BigQuickActionCard extends StatelessWidget {
  const _BigQuickActionCard({required this.item});

  final _QuickActionItem item;

  @override
  Widget build(BuildContext context) {
    return NeonGlassCard(
      padding: const EdgeInsets.all(14),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFFA855F7)],
                ),
              ),
              child: Icon(item.icon, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            if (item.subtitle != null)
              Text(
                item.subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white70,
                    ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..strokeWidth = 1;
    for (var i = 1; i <= 3; i++) {
      final y = (size.height / 4) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final path = Path()
      ..moveTo(0, size.height * 0.78)
      ..quadraticBezierTo(
        size.width * 0.18,
        size.height * 0.55,
        size.width * 0.34,
        size.height * 0.62,
      )
      ..quadraticBezierTo(
        size.width * 0.52,
        size.height * 0.72,
        size.width * 0.68,
        size.height * 0.46,
      )
      ..quadraticBezierTo(
        size.width * 0.82,
        size.height * 0.3,
        size.width,
        size.height * 0.38,
      );

    final linePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF22D3EE), Color(0xFF3B82F6)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StockDistributionCard extends StatelessWidget {
  const _StockDistributionCard({required this.stockHealth});

  final double stockHealth;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ReportCard(
      child: Column(
        children: [
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.analytics_outlined),
            title: Text('Stock distribution'),
          ),
          SizedBox(
            width: 130,
            height: 130,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: stockHealth,
                  strokeWidth: 12,
                  backgroundColor: cs.surfaceContainerHighest,
                ),
                Text('${(stockHealth * 100).round()}%'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfitSummaryCard extends StatelessWidget {
  const _ProfitSummaryCard({
    required this.canViewProfit,
    required this.todaySales,
  });

  final bool canViewProfit;
  final double todaySales;

  @override
  Widget build(BuildContext context) {
    return ReportCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.trending_up_rounded),
        title: const Text('Profit summary'),
        subtitle: Text(
          canViewProfit
              ? 'Today sales: ${BdtFormatter.format(todaySales)}'
              : 'Owner/Admin only',
        ),
        trailing: canViewProfit
            ? const Icon(Icons.lock_open_rounded)
            : const Icon(Icons.lock_outline_rounded),
      ),
    );
  }
}

class _LowStockAlertCard extends StatelessWidget {
  const _LowStockAlertCard({
    required this.lowStock,
    required this.threshold,
    required this.onTap,
  });

  final int lowStock;
  final int threshold;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(PremiumTokens.radiusMd),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.deepOrange.withValues(alpha: 0.13),
            cs.surface,
          ],
        ),
        border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.35)),
        boxShadow: PremiumTokens.cardShadow(context),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PremiumTokens.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.deepOrange.withValues(alpha: 0.16),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.deepOrange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Low stock visual alert',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$lowStock product(s) are below $threshold units. Review stock report now.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionItem {
  const _QuickActionItem({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({required this.sales});

  final List<Sale> sales;

  @override
  Widget build(BuildContext context) {
    return NeonGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          if (sales.isEmpty)
            Text(
              'No recent sales yet.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
            )
          else
            ...sales.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long_outlined, color: Color(0xFF22D3EE), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${s.itemCount} item(s) sold',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                    ),
                    Text(
                      BdtFormatter.format(s.totalAmount),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

