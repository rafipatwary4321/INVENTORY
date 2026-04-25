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
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cs.primary,
              Color.lerp(cs.primary, cs.tertiary, 0.4)!,
              cs.tertiary.withValues(alpha: 0.95),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.inventory_2_rounded,
                    size: 72,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'INVENTORY',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3,
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Stock · Sales · Insights',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                ),
                const SizedBox(height: 36),
                SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Preparing your workspace…',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.88),
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
