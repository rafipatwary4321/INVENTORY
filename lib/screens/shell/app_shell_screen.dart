import 'package:flutter/material.dart';
import 'dart:ui';

import '../../models/qr_scan_args.dart';
import '../../routes/app_router.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../dashboard/dashboard_screen.dart';
import '../products/product_list_screen.dart';
import '../sell/sell_screen.dart';
import '../reports/sales_report_screen.dart';
import '../ai/ai_assistant_screen.dart';
import '../settings/settings_screen.dart';
import '../../core/widgets/premium/premium_ui.dart';

/// Main shell: bottom navigation between Home, Inventory, POS, and Settings.
class AppShellScreen extends StatefulWidget {
  const AppShellScreen({super.key});

  @override
  State<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends State<AppShellScreen> {
  int _index = 0;
  bool _sidebarCollapsed = false;

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
    final isWide = MediaQuery.sizeOf(context).width >= 980;
    final auth = context.watch<AuthProvider>();
    final tabs = <_NavTab>[
      const _NavTab(
        label: 'Dashboard',
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard_rounded,
        screen: DashboardScreen(),
      ),
      const _NavTab(
        label: 'Products',
        icon: Icons.inventory_2_outlined,
        activeIcon: Icons.inventory_2_rounded,
        screen: ProductListScreen(),
      ),
      const _NavTab(
        label: 'POS',
        icon: Icons.point_of_sale_outlined,
        activeIcon: Icons.point_of_sale_rounded,
        screen: SellScreen(),
      ),
      const _NavTab(
        label: 'Reports',
        icon: Icons.bar_chart_outlined,
        activeIcon: Icons.bar_chart_rounded,
        screen: SalesReportScreen(),
      ),
      const _NavTab(
        label: 'AI',
        icon: Icons.smart_toy_outlined,
        activeIcon: Icons.smart_toy_rounded,
        screen: AIAssistantScreen(),
      ),
      const _NavTab(
        label: 'Settings',
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings_rounded,
        screen: SettingsScreen(),
        hideFromBottomNav: true,
      ),
      if (auth.isOwner || auth.isAdmin)
        const _NavTab(
          label: 'Team',
          icon: Icons.group_outlined,
          activeIcon: Icons.group_rounded,
          routeName: AppRoutes.team,
          hideFromBottomNav: true,
        ),
    ];

    final bottomTabs = tabs.where((t) => !t.hideFromBottomNav).toList();
    final bottomIndex = (_index < bottomTabs.length) ? _index : 0;
    final activeTab = isWide ? tabs[_index] : bottomTabs[bottomIndex];
    final selectedScreen = activeTab.screen;
    final bool showsScaffoldActionFab = selectedScreen is DashboardScreen;

    if (!isWide) {
      return Scaffold(
        body: AnimatedGradientBackground(
          child: IndexedStack(
            index: bottomIndex,
            sizing: StackFit.expand,
            children: bottomTabs.map((t) => t.screen ?? const SizedBox.shrink()).toList(),
          ),
        ),
        floatingActionButton: showsScaffoldActionFab
            ? FloatingActionButton.extended(
                heroTag: 'shell_scan_fab',
                onPressed: () => _scanStockIn(context),
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: const Text('Scan QR'),
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: NeonBottomNavigation(
          selectedIndex: bottomIndex,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: bottomTabs
              .map(
                (t) => NavigationDestination(
                  icon: Icon(t.icon),
                  selectedIcon: Icon(t.activeIcon),
                  label: t.label,
                ),
              )
              .toList(),
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          _SaasSidebar(
            collapsed: _sidebarCollapsed,
            tabs: tabs,
            selectedIndex: _index,
            onToggleCollapse: () => setState(() => _sidebarCollapsed = !_sidebarCollapsed),
            onSelect: (i) async {
              final t = tabs[i];
              if (t.routeName != null) {
                await Navigator.pushNamed(context, t.routeName!);
                return;
              }
              setState(() => _index = i);
            },
          ),
          Expanded(
            child: Stack(
              children: [
                if (selectedScreen != null) selectedScreen,
                if (showsScaffoldActionFab)
                  Positioned(
                    right: 20,
                    bottom: 20,
                    child: FloatingActionButton.extended(
                      heroTag: 'shell_scan_fab',
                      onPressed: () => _scanStockIn(context),
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                      label: const Text('Scan QR'),
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

class _NavTab {
  const _NavTab({
    required this.label,
    required this.icon,
    required this.activeIcon,
    this.screen,
    this.routeName,
    this.hideFromBottomNav = false,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Widget? screen;
  final String? routeName;
  final bool hideFromBottomNav;
}

class _SaasSidebar extends StatelessWidget {
  const _SaasSidebar({
    required this.collapsed,
    required this.tabs,
    required this.selectedIndex,
    required this.onToggleCollapse,
    required this.onSelect,
  });

  final bool collapsed;
  final List<_NavTab> tabs;
  final int selectedIndex;
  final VoidCallback onToggleCollapse;
  final void Function(int index) onSelect;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final width = collapsed ? 86.0 : 248.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      width: width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF071424).withValues(alpha: 0.95),
            const Color(0xFF0B1F35).withValues(alpha: 0.92),
          ],
        ),
        border: Border(
          right: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.2)),
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.cyanAccent.withValues(alpha: 0.16),
                        ),
                        child: const Icon(Icons.inventory_2_rounded, color: Colors.cyanAccent),
                      ),
                      if (!collapsed) ...[
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'INVENTORY',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                      IconButton(
                        onPressed: onToggleCollapse,
                        icon: Icon(
                          collapsed ? Icons.keyboard_arrow_right : Icons.keyboard_arrow_left,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: tabs.length,
                    itemBuilder: (context, i) {
                      final t = tabs[i];
                      final selected = selectedIndex == i && t.screen != null;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => onSelect(i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 240),
                            curve: Curves.easeInOut,
                            padding: EdgeInsets.symmetric(
                              horizontal: collapsed ? 10 : 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: selected
                                  ? LinearGradient(
                                      colors: [
                                        Colors.cyanAccent.withValues(alpha: 0.18),
                                        Colors.blueAccent.withValues(alpha: 0.16),
                                      ],
                                    )
                                  : null,
                              border: Border.all(
                                color: selected
                                    ? Colors.cyanAccent.withValues(alpha: 0.35)
                                    : Colors.white.withValues(alpha: 0.05),
                              ),
                              boxShadow: selected
                                  ? [
                                      BoxShadow(
                                        color: Colors.cyanAccent.withValues(alpha: 0.26),
                                        blurRadius: 14,
                                        spreadRadius: 0.2,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: collapsed
                                  ? MainAxisAlignment.center
                                  : MainAxisAlignment.start,
                              children: [
                                Icon(
                                  selected ? t.activeIcon : t.icon,
                                  color: selected ? Colors.cyanAccent : Colors.white70,
                                ),
                                if (!collapsed) ...[
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      t.label,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: selected ? Colors.white : Colors.white70,
                                        fontWeight:
                                            selected ? FontWeight.w700 : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
