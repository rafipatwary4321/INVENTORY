import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/bdt_formatter.dart';
import '../../models/app_user.dart';
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
      appBar: AppBar(
        title: Text(settings?.businessName ?? 'My Business'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.settings),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (user != null) _RoleChip(role: user.role),
          const SizedBox(height: 12),
          Text(
            'Hello, ${user?.displayName ?? (auth.isLoggedIn ? 'Demo Admin' : 'User')}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: crossAxisCount,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: cardRatio,
            children: [
              _StatCard(
                title: 'Products',
                value: '${products.length}',
                icon: Icons.category_outlined,
                color: Colors.blue,
              ),
              _StatCard(
                title: 'Stock qty',
                value: '$totalStockQty',
                icon: Icons.format_list_numbered_rounded,
                color: Colors.indigo,
              ),
              _StatCard(
                title: 'Stock value',
                value: BdtFormatter.format(totalStockValue),
                icon: Icons.account_balance_wallet_outlined,
                color: Colors.teal,
              ),
              _StatCard(
                title: 'Today sales',
                value: BdtFormatter.format(todaySales),
                icon: Icons.point_of_sale,
                color: Colors.deepPurple,
              ),
              _StatCard(
                title: 'Low stock',
                value: '$lowStock',
                icon: Icons.warning_amber_rounded,
                color: lowStock > 0 ? Colors.deepOrange : Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (lowStock > 0)
            Card(
              color: Colors.orange.shade50,
              child: ListTile(
                leading: const Icon(Icons.warning_amber_rounded),
                title: Text(
                  '$lowStock product(s) are below '
                  '${AppConstants.lowStockThreshold} units',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, AppRoutes.reportStock),
              ),
            ),
          const SizedBox(height: 24),
          Text('Shortcuts', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _ShortcutTile(
            icon: Icons.inventory_2_outlined,
            label: 'Products',
            onTap: () => Navigator.pushNamed(context, AppRoutes.products),
          ),
          _ShortcutTile(
            icon: Icons.qr_code_scanner,
            label: 'Scan QR — Stock in',
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
          _ShortcutTile(
            icon: Icons.shopping_cart_checkout,
            label: 'Sell / POS',
            onTap: () => Navigator.pushNamed(context, AppRoutes.sell),
          ),
          _ShortcutTile(
            icon: Icons.analytics_outlined,
            label: 'Sales report',
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.reportSales),
          ),
          _ShortcutTile(
            icon: Icons.warehouse_outlined,
            label: 'Stock report',
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.reportStock),
          ),
          _ShortcutTile(
            icon: Icons.trending_up,
            label: 'Profit / Loss',
            onTap: () => Navigator.pushNamed(context, AppRoutes.reportPnL),
          ),
          _ShortcutTile(
            icon: Icons.photo_camera_outlined,
            label: 'AI product recognition',
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.aiRecognition),
          ),
          _ShortcutTile(
            icon: Icons.chat_bubble_outline,
            label: 'AI Assistant',
            onTap: () => Navigator.pushNamed(context, AppRoutes.aiAssistant),
          ),
          _ShortcutTile(
            icon: Icons.auto_graph_outlined,
            label: 'Advanced AI Analytics',
            onTap: () => Navigator.pushNamed(context, AppRoutes.aiAnalytics),
          ),
          _ShortcutTile(
            icon: Icons.insights_outlined,
            label: 'Smart Insights',
            onTap: () => Navigator.pushNamed(context, AppRoutes.aiInsights),
          ),
          _ShortcutTile(
            icon: Icons.inventory_outlined,
            label: 'Predictive Restock',
            onTap: () => Navigator.pushNamed(context, AppRoutes.aiRestock),
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.role});
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == UserRole.admin;
    return Align(
      alignment: Alignment.centerLeft,
      child: Chip(
        avatar: Icon(
          isAdmin ? Icons.admin_panel_settings : Icons.badge_outlined,
          size: 18,
        ),
        label: Text(isAdmin ? 'Admin' : 'Staff'),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const Spacer(),
            Text(
              title,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
