import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/error_handler.dart';
import '../../core/utils/validators.dart';
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
  static const _appVersion = '1.0.0+1';

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
        Exception('Settings sync is unavailable in demo mode.'),
      );
      return;
    }
    final role = context.read<AuthProvider>().appUser?.isAdmin ?? false;
    if (!role) {
      ErrorHandler.showSnack(context, Exception('Only admins can change settings'));
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
        content: const Text('You will need to sign in again.'),
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
    final isAdmin = context.watch<AuthProvider>().appUser?.isAdmin ?? false;
    final settingsProvider = context.watch<SettingsProvider?>();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _businessName,
                  enabled: isAdmin && !_busy,
                  decoration: const InputDecoration(
                    labelText: 'Business name',
                  ),
                  validator: (v) => Validators.required(v, field: 'Business name'),
                ),
                const SizedBox(height: 12),
                const ListTile(
                  title: Text('Currency'),
                  subtitle: Text('BDT (৳) — fixed in this version'),
                ),
                const SizedBox(height: 16),
                if (isAdmin)
                  FilledButton(
                    onPressed:
                        _busy || settingsProvider == null ? null : _save,
                    child: _busy
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.cloud_outlined),
              title: const Text('Backend mode'),
              subtitle: Text(
                startup.firebaseEnabled ? 'Firebase mode' : 'Demo/local mode',
              ),
            ),
          ),
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('App version'),
              subtitle: Text(_appVersion),
            ),
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
