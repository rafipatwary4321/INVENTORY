import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../firebase_options.dart';
import '../../main.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_router.dart';
import '../../services/settings_service.dart';

/// Shows logo while Firebase + default settings initialize, then routes user.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _startupTimeout = Duration(seconds: 3);
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  bool _isFirebaseConfigured() {
    try {
      final options = DefaultFirebaseOptions.currentPlatform;
      final keys = [
        options.apiKey,
        options.appId,
        options.messagingSenderId,
        options.projectId,
      ];
      return keys.every(
        (value) => value.isNotEmpty && !value.startsWith('YOUR_'),
      );
    } catch (_) {
      return false;
    }
  }

  void _go(String route, {String? warning}) {
    if (!mounted || _navigated) return;
    _navigated = true;
    Navigator.pushReplacementNamed(context, route);
    if (warning != null && warning.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(warning)),
        );
      });
    }
  }

  Future<void> _boot() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    final startupState = context.read<AppStartupState>();
    final auth = context.read<AuthProvider>();
    var startupWarning = startupState.startupWarning ?? '';

    // When Firebase options are still placeholders, never block startup.
    if (startupState.firebaseEnabled && _isFirebaseConfigured()) {
      try {
        await context
            .read<SettingsService>()
            .ensureDefaults()
            .timeout(_startupTimeout);
      } on TimeoutException {
        startupWarning = 'Startup took too long. Continuing to login.';
      } catch (e) {
        startupWarning =
            'Could not load startup data. You can continue from login.';
        debugPrint('Splash startup error: $e');
      }
    }

    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    final target = auth.isLoggedIn ? AppRoutes.dashboard : AppRoutes.login;
    _go(target, warning: startupWarning);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_rounded,
              size: 88,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'INVENTORY',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
            ),
            const SizedBox(height: 12),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
