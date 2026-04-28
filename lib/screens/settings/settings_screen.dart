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
      appBar: const PremiumAppBar(
        title: 'Settings',
        subtitle: 'Business & app',
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
              title: 'Workspace Settings',
              subtitle: 'Manage business profile, appearance, and account preferences.',
              icon: Icons.settings_suggest_outlined,
              trailingIcon: Icons.tune_rounded,
            ),
            PremiumGlassCard(
              child: BusinessProfileCard(
                businessName: businessName,
                businessId: auth.businessId,
                planLabel: startup.firebaseEnabled ? 'Live' : 'Demo',
              ),
            ),
            const SizedBox(height: 10),
            PremiumGlassCard(
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
            PremiumGlassCard(
              child: ListTile(
                leading: const Icon(Icons.security_outlined),
                title: const Text('Security / environment status'),
                subtitle: Text(
                  startup.firebaseEnabled
                      ? 'Cloud auth and data sync enabled.'
                      : 'Running in local demo environment.',
                ),
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
            PremiumGlassCard(
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
    return PremiumGlassCard(
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
            PremiumTextField(
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
    return PremiumGlassCard(
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
