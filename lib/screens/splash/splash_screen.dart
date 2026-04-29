import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../firebase_options.dart';
import '../../main.dart';
import '../../core/widgets/premium/premium_ui.dart';
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
  bool _pulse = false;

  @override
  void initState() {
    super.initState();
    _pulse = true;
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
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF050C18),
              const Color(0xFF0A1C35),
              const Color(0xFF0F2F57),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.96, end: _pulse ? 1.0 : 0.96),
                  duration: const Duration(milliseconds: 1100),
                  curve: Curves.easeInOut,
                  onEnd: () => setState(() => _pulse = !_pulse),
                  builder: (context, value, child) {
                    return Transform.scale(scale: value, child: child);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyanAccent.withValues(alpha: 0.28),
                          blurRadius: 34,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.28),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.inventory_2_rounded,
                      size: 72,
                      color: Colors.white.withValues(alpha: 0.98),
                    ),
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
                  'AI Powered Smart Inventory',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        letterSpacing: 0.2,
                      ),
                ),
                const SizedBox(height: 10),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: AnimatedFeatureHero(
                    title: 'Booting Warehouse Engine',
                    subtitle: 'Loading inventory, POS, reports, and AI modules.',
                    icon: Icons.inventory_2_rounded,
                    compact: true,
                    gradientColors: [Color(0xFF7A37FF), Color(0xFF13A7FF), Color(0xFF1DE2B0)],
                    animationType: FeatureHeroAnimationType.warehouse,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7A37FF), Color(0xFF13A7FF), Color(0xFF1DE2B0)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF13A7FF).withValues(alpha: 0.35),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                  child: Text(
                    'Premium Mobile Workspace',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
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
                  'Preparing your premium workspace...',
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
