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
      body: ListView(
        padding: PremiumTokens.pagePadding(context),
        children: [
          GradientDashboardHeader(
            title: 'Welcome back',
            subtitle:
                'Hello, ${user?.displayName ?? (auth.isLoggedIn ? 'Demo Admin' : 'User')}. '
                'Here is a snapshot of your business.',
            role: user != null ? user.role.toVisual() : null,
          ),
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
            ActionCard(
              icon: Icons.warning_amber_rounded,
              label: 'Low stock alert',
              subtitle:
                  '$lowStock product(s) below ${AppConstants.lowStockThreshold} units',
              iconColor: Colors.deepOrange,
              onTap: () => Navigator.pushNamed(context, AppRoutes.reportStock),
            ),
          const SizedBox(height: 20),
          Text(
            'Shortcuts',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          ActionCard(
            icon: Icons.inventory_2_outlined,
            label: 'Products',
            subtitle: 'Browse, add, and edit inventory',
            onTap: () => Navigator.pushNamed(context, AppRoutes.products),
          ),
          const SizedBox(height: 10),
          ActionCard(
            icon: Icons.qr_code_scanner_rounded,
            label: 'Scan QR — Stock in',
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
          ActionCard(
            icon: Icons.shopping_cart_checkout,
            label: 'Sell / POS',
            subtitle: 'Checkout and cart',
            onTap: () => Navigator.pushNamed(context, AppRoutes.sell),
          ),
          ActionCard(
            icon: Icons.analytics_outlined,
            label: 'Sales report',
            onTap: () => Navigator.pushNamed(context, AppRoutes.reportSales),
          ),
          ActionCard(
            icon: Icons.warehouse_outlined,
            label: 'Stock report',
            onTap: () => Navigator.pushNamed(context, AppRoutes.reportStock),
          ),
          ActionCard(
            icon: Icons.trending_up,
            label: 'Profit / Loss',
            subtitle: auth.canViewProfitLoss ? null : 'Owner only',
            onTap: auth.canViewProfitLoss
                ? () => Navigator.pushNamed(context, AppRoutes.reportPnL)
                : null,
          ),
          ActionCard(
            icon: Icons.group_outlined,
            label: 'Team management',
            subtitle: (auth.isOwner || auth.isAdmin) ? null : 'Admin only',
            onTap: (auth.isOwner || auth.isAdmin)
                ? () => Navigator.pushNamed(context, AppRoutes.team)
                : null,
          ),
          ActionCard(
            icon: Icons.photo_camera_outlined,
            label: 'AI product recognition',
            onTap: () => Navigator.pushNamed(context, AppRoutes.aiRecognition),
          ),
          ActionCard(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'AI Assistant',
            onTap: () => Navigator.pushNamed(context, AppRoutes.aiAssistant),
          ),
          ActionCard(
            icon: Icons.auto_graph_outlined,
            label: 'Advanced AI Analytics',
            onTap: () => Navigator.pushNamed(context, AppRoutes.aiAnalytics),
          ),
          ActionCard(
            icon: Icons.insights_outlined,
            label: 'Smart Insights',
            onTap: () => Navigator.pushNamed(context, AppRoutes.aiInsights),
          ),
          ActionCard(
            icon: Icons.inventory_outlined,
            label: 'Predictive Restock',
            onTap: () => Navigator.pushNamed(context, AppRoutes.aiRestock),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
