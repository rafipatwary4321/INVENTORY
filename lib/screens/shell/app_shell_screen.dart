import 'package:flutter/material.dart';

import '../../models/qr_scan_args.dart';
import '../../routes/app_router.dart';
import '../dashboard/dashboard_screen.dart';
import '../products/product_list_screen.dart';
import '../sell/sell_screen.dart';
import '../settings/settings_screen.dart';

/// Main shell: bottom navigation between Home, Inventory, POS, and Settings.
class AppShellScreen extends StatefulWidget {
  const AppShellScreen({super.key});

  @override
  State<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends State<AppShellScreen> {
  int _index = 0;

  Future<void> _scanStockIn(BuildContext context) async {
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.qrScan,
      arguments: QRScanArgs(mode: QRScanMode.stockIn),
    );
    final id = result as String?;
    if (!context.mounted || id == null) return;
    await Navigator.pushNamed(context, AppRoutes.stockIn, arguments: id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        sizing: StackFit.expand,
        children: const [
          DashboardScreen(),
          ProductListScreen(),
          SellScreen(),
          SettingsScreen(),
        ],
      ),
      floatingActionButton: _index == 0
          ? FloatingActionButton.extended(
              heroTag: 'shell_scan_fab',
              onPressed: () => _scanStockIn(context),
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text('Scan QR'),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2_rounded),
            label: 'Products',
          ),
          NavigationDestination(
            icon: Icon(Icons.point_of_sale_outlined),
            selectedIcon: Icon(Icons.point_of_sale_rounded),
            label: 'Sell',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
