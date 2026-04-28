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
    return Scaffold(
      appBar: const PremiumAppBar(
        title: 'Settings',
        subtitle: 'Business & app',
      ),
      body: ListView(
        padding: PremiumTokens.pagePadding(context),
        children: [
          const FeatureHeaderCard(
            title: 'Workspace Settings',
            subtitle: 'Manage business profile, appearance, and account preferences.',
            icon: Icons.settings_suggest_outlined,
            trailingIcon: Icons.tune_rounded,
          ),
          BusinessProfileCard(
            businessName: businessName,
            businessId: auth.businessId,
            planLabel: startup.firebaseEnabled ? 'Live' : 'Demo',
          ),
          const SizedBox(height: 20),
          Text(
            'Business settings',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          ReportCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PremiumTextField(
                    controller: _businessName,
                    label: 'Business name',
                    enabled: canManage && !_busy,
                    validator: (v) =>
                        Validators.required(v, field: 'Business name'),
                  ),
                  const SizedBox(height: 12),
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Currency'),
                    subtitle: Text('BDT (৳) — fixed in this version'),
                  ),
                  const SizedBox(height: 8),
                  if (canManage)
                    PremiumButton(
                      label: _busy ? 'Saving…' : 'Save changes',
                      expand: true,
                      icon: _busy ? null : Icons.save_rounded,
                      onPressed:
                          _busy || settingsProvider == null ? null : _save,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'App & account',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          ReportCard(
            child: ListTile(
              leading: const Icon(Icons.cloud_outlined),
              title: const Text('Backend mode'),
              subtitle: Text(
                startup.firebaseEnabled ? 'Firebase mode' : 'Demo/local mode',
              ),
            ),
          ),
          const SizedBox(height: 10),
          ReportCard(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('App version'),
              subtitle: Text(_appVersion),
            ),
          ),
          const SizedBox(height: 10),
          ReportCard(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Appearance',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<ThemeMode>(
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
                      context
                          .read<ThemeModeController>()
                          .setThemeMode(next.first);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          PremiumButton(
            label: 'Logout',
            outlined: true,
            expand: true,
            icon: Icons.logout_rounded,
            onPressed: _logout,
          ),
        ],
      ),
    );
  }
}
