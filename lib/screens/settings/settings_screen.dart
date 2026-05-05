import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../../core/utils/error_handler.dart';
import '../../core/utils/validators.dart';
import '../../core/theme/theme_mode_controller.dart';
import '../../core/widgets/premium/premium_ui.dart';
import '../../main.dart';
import '../../models/app_settings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../routes/app_router.dart';

/// Business name, fixed BDT currency, and logout.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessName = TextEditingController();
  bool _busy = false;
  String _appVersion = '...';
  bool _notifSales = true;
  bool _notifLowStock = true;
  bool _securityBiometric = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _appVersion = '${info.version}+${info.buildNumber}';
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = context.read<SettingsProvider?>()?.settings;
    if (s == null) return;
    if (_businessName.text.isEmpty && s.businessName.isNotEmpty) {
      _businessName.text = s.businessName;
    }
  }

  @override
  void dispose() {
    _businessName.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final settingsProvider = context.read<SettingsProvider?>();
    if (settingsProvider == null) {
      ErrorHandler.showSnack(
        context,
        Exception('Settings storage is unavailable in demo mode.'),
      );
      return;
    }
    final canManage = context.read<AuthProvider>().canManageBusinessSettings;
    if (!canManage) {
      ErrorHandler.showSnack(context, Exception('Only owners can change business settings'));
      return;
    }
    setState(() => _busy = true);
    try {
      await settingsProvider.save(
            AppSettings(
              businessName: _businessName.text.trim(),
              currency: 'BDT',
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved')),
        );
      }
    } catch (e) {
      if (mounted) ErrorHandler.showSnack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('You will need to login again to continue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await context.read<AuthProvider>().signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    final startup = context.read<AppStartupState>();
    final auth = context.watch<AuthProvider>();
    final canManage = auth.canManageBusinessSettings;
    final settingsProvider = context.watch<SettingsProvider?>();
    final businessName =
        settingsProvider?.settings.businessName ?? 'My Business';
    final themeCtrl = context.watch<ThemeModeController>();
    final isWide = MediaQuery.sizeOf(context).width >= 980;
    return Scaffold(
      appBar: const NeonAppBar(
        title: 'Settings',
        subtitle: 'Business & app',
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B0F1A), Color(0xFF101B32), Color(0xFF162643)],
          ),
        ),
        child: ListView(
          padding: PremiumTokens.pagePadding(context),
          children: [
            NeonGlassCard(
              radius: 26,
              child: BusinessProfileCard(
                businessName: businessName,
                businessId: auth.businessId,
                planLabel: startup.firebaseEnabled ? 'Live' : 'Demo',
              ),
            ),
            const SizedBox(height: 10),
            NeonGlassCard(
              radius: 24,
              child: const ListTile(
                leading: CircleAvatar(
                  radius: 18,
                  child: Icon(Icons.store_rounded),
                ),
                title: Text('Business Logo'),
                subtitle: Text('Logo placeholder (upload in next release)'),
              ),
            ),
            const SizedBox(height: 10),
            NeonGlassCard(
              child: ListTile(
                leading: Icon(
                  startup.firebaseEnabled
                      ? Icons.cloud_done_outlined
                      : Icons.developer_mode_outlined,
                ),
                title: Text(startup.firebaseEnabled ? 'Firebase mode' : 'Demo mode'),
                subtitle: Text(
                  startup.firebaseEnabled
                      ? 'Live backend and role-based access are active.'
                      : 'Local demo mode is active. Some cloud features are limited.',
                ),
                trailing: Chip(
                  label: Text(startup.firebaseEnabled ? 'LIVE' : 'DEMO'),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _SettingsGroupCard(
              title: 'General',
              icon: Icons.tune_rounded,
              child: Row(
                children: [
                  _SettingsChip(
                    label: 'Workspace',
                    icon: Icons.apartment_rounded,
                    color: const Color(0xFF7C3BFF),
                  ),
                  const SizedBox(width: 8),
                  _SettingsChip(
                    label: 'Theme',
                    icon: Icons.palette_outlined,
                    color: const Color(0xFF13A7FF),
                  ),
                  const SizedBox(width: 8),
                  _SettingsChip(
                    label: 'Roles',
                    icon: Icons.admin_panel_settings_outlined,
                    color: const Color(0xFF1DE2B0),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _SettingsGroupCard(
              title: 'Security',
              icon: Icons.security_outlined,
              child: ListTile(
                leading: const Icon(Icons.security_outlined),
                title: const Text('Security / environment status'),
                subtitle: Text(
                  startup.firebaseEnabled
                      ? 'Cloud auth and data sync enabled.'
                      : 'Running in local demo environment.',
                ),
                trailing: Switch(
                  value: _securityBiometric,
                  onChanged: (v) => setState(() => _securityBiometric = v),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _SettingsGroupCard(
              title: 'Notifications',
              icon: Icons.notifications_active_outlined,
              child: Column(
                children: [
                  SwitchListTile(
                    value: _notifSales,
                    onChanged: (v) => setState(() => _notifSales = v),
                    title: const Text('Sales alerts'),
                    subtitle: const Text('Checkout and billing updates'),
                  ),
                  SwitchListTile(
                    value: _notifLowStock,
                    onChanged: (v) => setState(() => _notifLowStock = v),
                    title: const Text('Low stock alerts'),
                    subtitle: const Text('Notify when product quantity drops'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _SettingsGroupCard(
              title: 'Business Settings',
              icon: Icons.business_center_outlined,
              child: ListTile(
                leading: const Icon(Icons.contact_phone_outlined),
                title: const Text('Contact info'),
                subtitle: Text('Owner: ${auth.appUser?.displayName ?? 'N/A'}'),
              ),
            ),
            const SizedBox(height: 20),
            if (!isWide) ...[
              _BusinessSettingsCard(
                formKey: _formKey,
                businessName: _businessName,
                canManage: canManage,
                busy: _busy,
                settingsProviderExists: settingsProvider != null,
                onSave: _save,
              ),
              const SizedBox(height: 10),
              _AppSettingsCard(
                appVersion: _appVersion,
                themeCtrl: themeCtrl,
              ),
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _BusinessSettingsCard(
                      formKey: _formKey,
                      businessName: _businessName,
                      canManage: canManage,
                      busy: _busy,
                      settingsProviderExists: settingsProvider != null,
                      onSave: _save,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _AppSettingsCard(
                      appVersion: _appVersion,
                      themeCtrl: themeCtrl,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 28),
            _SettingsGroupCard(
              title: 'Logout',
              icon: Icons.logout_rounded,
              borderColor: Colors.red.withValues(alpha: 0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Logout',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Sign out from this business workspace and return to login.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  PremiumButton(
                    label: 'Logout',
                    outlined: true,
                    expand: true,
                    icon: Icons.logout_rounded,
                    onPressed: _logout,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BusinessSettingsCard extends StatelessWidget {
  const _BusinessSettingsCard({
    required this.formKey,
    required this.businessName,
    required this.canManage,
    required this.busy,
    required this.settingsProviderExists,
    required this.onSave,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController businessName;
  final bool canManage;
  final bool busy;
  final bool settingsProviderExists;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return NeonGlassCard(
      radius: 24,
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Business settings',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            NeonTextField(
              controller: businessName,
              label: 'Business name',
              enabled: canManage && !busy,
              validator: (v) => Validators.required(v, field: 'Business name'),
            ),
            const SizedBox(height: 12),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.currency_exchange_outlined),
              title: Text('Currency'),
              subtitle: Text('BDT (৳) — fixed in this version'),
            ),
            const SizedBox(height: 8),
            if (canManage)
              PremiumButton(
                label: busy ? 'Saving...' : 'Save changes',
                expand: true,
                icon: busy ? null : Icons.save_rounded,
                onPressed: busy || !settingsProviderExists ? null : onSave,
              ),
          ],
        ),
      ),
    );
  }
}

class _AppSettingsCard extends StatelessWidget {
  const _AppSettingsCard({
    required this.appVersion,
    required this.themeCtrl,
  });

  final String appVersion;
  final ThemeModeController themeCtrl;

  @override
  Widget build(BuildContext context) {
    return NeonGlassCard(
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.info_outline),
            title: const Text('App version'),
            subtitle: Text(appVersion),
          ),
          const SizedBox(height: 6),
          Text(
            'Appearance',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('System'),
                  icon: Icon(Icons.brightness_auto_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Light'),
                  icon: Icon(Icons.light_mode_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.dark_mode_outlined),
                ),
              ],
              selected: {themeCtrl.themeMode},
              onSelectionChanged: (next) {
                if (next.isEmpty) return;
                themeCtrl.setThemeMode(next.first);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsChip extends StatelessWidget {
  const _SettingsChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsGroupCard extends StatelessWidget {
  const _SettingsGroupCard({
    required this.title,
    required this.icon,
    required this.child,
    this.borderColor,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return NeonGlassCard(
      radius: 24,
      borderColor: borderColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF22D3EE)),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
