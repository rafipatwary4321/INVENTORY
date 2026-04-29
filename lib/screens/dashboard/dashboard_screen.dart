import 'package:flutter/material.dart';
import 'dart:ui';
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

    final totalStockValue = products.fold<double>(
      0,
      (a, p) => a + p.stockValue,
    );
    final totalStockQty = products.fold<int>(
      0,
      (a, p) => a + p.quantity,
    );
    final lowStock = products
        .where((p) => p.quantity < AppConstants.lowStockThreshold)
        .length;
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width >= 1100
        ? 4
        : width >= 820
            ? 3
            : 2;
    final cardRatio = width < 380 ? 1.0 : 1.12;
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
    Future<void> openStockInScan() async {
      final result = await Navigator.pushNamed(
        context,
        AppRoutes.qrScan,
        arguments: QRScanArgs(mode: QRScanMode.stockIn),
      );
      final id = result as String?;
      if (!context.mounted || id == null) return;
      Navigator.pushNamed(context, AppRoutes.stockIn, arguments: id);
    }

    return Scaffold(
      appBar: PremiumAppBar(
        title: settings?.businessName ?? 'My Business',
        subtitle: 'Dashboard',
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: _DashboardBackdrop()),
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
              ),
              const SizedBox(height: 10),
              _PremiumDashboardHero(
                businessName: settings?.businessName ?? 'My Business',
                userName: user?.displayName ?? 'User',
                todaySales: todaySales,
                totalStockValue: totalStockValue,
                stockHealth: stockHealth,
                lowStock: lowStock,
                onStartSelling: () => Navigator.pushNamed(context, AppRoutes.sell),
                onStockIn: openStockInScan,
              ),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: cardRatio,
                children: [
                  GlassStatCard(
                    title: 'Products',
                    value: '${products.length}',
                    icon: Icons.category_outlined,
                    accentColor: Colors.blue,
                    changeLabel: 'Inventory size',
                    changeColor: Colors.cyanAccent,
                  ),
                  GlassStatCard(
                    title: 'Today sales',
                    value: BdtFormatter.format(todaySales),
                    icon: Icons.point_of_sale,
                    accentColor: Colors.deepPurple,
                    changeLabel: '$totalStockQty units on hand',
                    changeColor: Colors.cyanAccent,
                  ),
                  GlassStatCard(
                    title: 'Stock value',
                    value: BdtFormatter.format(totalStockValue),
                    icon: Icons.account_balance_wallet_outlined,
                    accentColor: Colors.teal,
                    changeLabel: 'Cost basis',
                    changeColor: Colors.greenAccent,
                  ),
                  GlassStatCard(
                    title: 'Low stock',
                    value: '$lowStock',
                    icon: Icons.warning_amber_rounded,
                    accentColor: lowStock > 0 ? Colors.deepOrange : Colors.green,
                    changeLabel: lowStock > 0 ? 'Action needed' : 'Healthy',
                    changeColor: lowStock > 0 ? Colors.orangeAccent : Colors.greenAccent,
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
              const SizedBox(height: 20),
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
                  final actionCols = constraints.maxWidth >= 920
                      ? 3
                      : constraints.maxWidth >= 620
                          ? 2
                          : 1;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: quickActions.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: actionCols,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: actionCols == 1 ? 3.8 : 2.4,
                    ),
                    itemBuilder: (context, i) {
                      final item = quickActions[i];
                      return PremiumActionCard(
                        icon: item.icon,
                        label: item.label,
                        subtitle: item.subtitle,
                        onTap: item.onTap,
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 12),
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
                        const _ChartPlaceholderCard(
                          title: 'Sales overview',
                          subtitle: 'Chart placeholder for daily/weekly trend',
                        ),
                        const SizedBox(height: 10),
                        _StockDistributionCard(stockHealth: stockHealth),
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
                      const Expanded(
                        flex: 3,
                        child: _ChartPlaceholderCard(
                          title: 'Sales overview',
                          subtitle: 'Chart placeholder for daily/weekly trend',
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
  });

  final String businessName;
  final String userName;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: TextField(
            readOnly: true,
            decoration: InputDecoration(
              hintText: 'Search products, sales, reports...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: cs.surface.withValues(alpha: 0.7),
            ),
          ),
        ),
        const SizedBox(width: 10),
        IconButton.filledTonal(
          onPressed: () {},
          icon: const Icon(Icons.notifications_none_rounded),
        ),
        const SizedBox(width: 8),
        CircleAvatar(
          backgroundColor: cs.primaryContainer,
          child: Text(
            userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
            style: TextStyle(color: cs.onPrimaryContainer),
          ),
        ),
      ],
    );
  }
}

class _PremiumDashboardHero extends StatelessWidget {
  const _PremiumDashboardHero({
    required this.businessName,
    required this.userName,
    required this.todaySales,
    required this.totalStockValue,
    required this.stockHealth,
    required this.lowStock,
    required this.onStartSelling,
    required this.onStockIn,
  });

  final String businessName;
  final String userName;
  final double todaySales;
  final double totalStockValue;
  final double stockHealth;
  final int lowStock;
  final VoidCallback onStartSelling;
  final VoidCallback onStockIn;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.985, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4D2BFF), Color(0xFF127DFF), Color(0xFF15CFA7)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4D2BFF).withValues(alpha: 0.34),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Stack(
            children: [
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Color(0xAD02040A),
                        Color(0x78030A16),
                        Color(0x22000000),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
                  child: AnimatedFeatureHero(
                    title: 'Warehouse Activity',
                    subtitle: 'Smart inventory movement and shelf health',
                    icon: Icons.warehouse_rounded,
                    compact: true,
                    gradientColors: const [
                      Color(0x007A37FF),
                      Color(0x0013A7FF),
                      Color(0x001DE2B0),
                    ],
                    animationType: FeatureHeroAnimationType.warehouse,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      businessName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Hi ${userName.isEmpty ? 'User' : userName} · Today ${BdtFormatter.format(todaySales)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.92),
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      BdtFormatter.format(totalStockValue),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            shadows: [
                              Shadow(
                                color: const Color(0xFF20E3BE).withValues(alpha: 0.7),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                    ),
                    Text(
                      'Inventory Value',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SizedBox(
                          width: 168,
                          child: GlowButton(
                            onPressed: onStartSelling,
                            icon: Icons.shopping_cart_checkout_rounded,
                            label: 'Start Selling',
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: onStockIn,
                          icon: const Icon(Icons.qr_code_scanner_rounded),
                          label: const Text('Stock In'),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        _HeroStockRing(stockHealth: stockHealth, lowStock: lowStock),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroStockRing extends StatelessWidget {
  const _HeroStockRing({
    required this.stockHealth,
    required this.lowStock,
  });

  final double stockHealth;
  final int lowStock;

  @override
  Widget build(BuildContext context) {
    final valueColor = lowStock > 0 ? Colors.orangeAccent : Colors.greenAccent;
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              value: stockHealth,
              strokeWidth: 5,
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(valueColor),
            ),
          ),
          Text(
            '${(stockHealth * 100).round()}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
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

class _ChartPlaceholderCard extends StatelessWidget {
  const _ChartPlaceholderCard({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 10),
          Container(
            height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  cs.primary.withValues(alpha: 0.16),
                  cs.tertiary.withValues(alpha: 0.08),
                ],
              ),
            ),
          ),
        ],
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

class _DashboardBackdrop extends StatelessWidget {
  const _DashboardBackdrop();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    cs.primary.withValues(alpha: 0.2),
                    cs.secondary.withValues(alpha: 0.14),
                    cs.surface,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -18,
            right: -8,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Icon(
                Icons.warehouse_rounded,
                size: 220,
                color: cs.primary.withValues(alpha: 0.16),
              ),
            ),
          ),
          Positioned(
            bottom: 90,
            left: -20,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Icon(
                Icons.storefront_rounded,
                size: 210,
                color: cs.secondary.withValues(alpha: 0.15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

