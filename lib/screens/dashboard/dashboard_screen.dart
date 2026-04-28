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
        icon: Icons.inventory_2_outlined,
        label: 'Products',
        subtitle: 'Browse, add, and edit inventory',
        onTap: () => Navigator.pushNamed(context, AppRoutes.products),
      ),
      _QuickActionItem(
        icon: Icons.qr_code_scanner_rounded,
        label: 'Scan QR - Stock in',
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
        icon: Icons.analytics_outlined,
        label: 'Sales report',
        onTap: () => Navigator.pushNamed(context, AppRoutes.reportSales),
      ),
      _QuickActionItem(
        icon: Icons.warehouse_outlined,
        label: 'Stock report',
        onTap: () => Navigator.pushNamed(context, AppRoutes.reportStock),
      ),
      _QuickActionItem(
        icon: Icons.trending_up,
        label: 'Profit / Loss',
        subtitle: auth.canViewProfitLoss ? null : 'Owner only',
        onTap: auth.canViewProfitLoss
            ? () => Navigator.pushNamed(context, AppRoutes.reportPnL)
            : null,
      ),
      _QuickActionItem(
        icon: Icons.group_outlined,
        label: 'Team management',
        subtitle: (auth.isOwner || auth.isAdmin) ? null : 'Admin only',
        onTap: (auth.isOwner || auth.isAdmin)
            ? () => Navigator.pushNamed(context, AppRoutes.team)
            : null,
      ),
      _QuickActionItem(
        icon: Icons.photo_camera_outlined,
        label: 'AI product recognition',
        onTap: () => Navigator.pushNamed(context, AppRoutes.aiRecognition),
      ),
      _QuickActionItem(
        icon: Icons.chat_bubble_outline_rounded,
        label: 'AI Assistant',
        onTap: () => Navigator.pushNamed(context, AppRoutes.aiAssistant),
      ),
      _QuickActionItem(
        icon: Icons.auto_graph_outlined,
        label: 'Advanced AI Analytics',
        onTap: () => Navigator.pushNamed(context, AppRoutes.aiAnalytics),
      ),
      _QuickActionItem(
        icon: Icons.insights_outlined,
        label: 'Smart Insights',
        onTap: () => Navigator.pushNamed(context, AppRoutes.aiInsights),
      ),
      _QuickActionItem(
        icon: Icons.inventory_outlined,
        label: 'Predictive Restock',
        onTap: () => Navigator.pushNamed(context, AppRoutes.aiRestock),
      ),
    ];

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
              GradientDashboardHeader(
                title: 'Warehouse Control Center',
                subtitle:
                    'Hello, ${user?.displayName ?? (auth.isLoggedIn ? 'Demo Admin' : 'User')}. '
                    'Track stock flow, sales pace, and AI guidance from one place.',
                role: user?.roleVisual,
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Icon(
                      Icons.storefront_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      child: const Text(
                        'Live Ops',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: cardRatio,
                children: [
                  StatCard(
                    title: 'Products',
                    value: '${products.length}',
                    icon: Icons.category_outlined,
                    accentColor: Colors.blue,
                  ),
                  StatCard(
                    title: 'Stock qty',
                    value: '$totalStockQty',
                    icon: Icons.format_list_numbered_rounded,
                    accentColor: Colors.indigo,
                  ),
                  StatCard(
                    title: 'Stock value',
                    value: BdtFormatter.format(totalStockValue),
                    icon: Icons.account_balance_wallet_outlined,
                    accentColor: Colors.teal,
                  ),
                  StatCard(
                    title: 'Today sales',
                    value: BdtFormatter.format(todaySales),
                    icon: Icons.point_of_sale,
                    accentColor: Colors.deepPurple,
                  ),
                  StatCard(
                    title: 'Low stock',
                    value: '$lowStock',
                    icon: Icons.warning_amber_rounded,
                    accentColor: lowStock > 0 ? Colors.deepOrange : Colors.green,
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
                      return ActionCard(
                        icon: item.icon,
                        label: item.label,
                        subtitle: item.subtitle,
                        onTap: item.onTap,
                      );
                    },
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
