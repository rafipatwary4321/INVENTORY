import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/error_handler.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/premium/premium_ui.dart';
import '../../main.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_router.dart';
import '../../services/auth_service.dart';

/// Email / password login (Firebase Auth). Role comes from `users/{uid}`.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await context.read<AuthProvider>().signIn(
            _email.text.trim(),
            _password.text,
          );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    } catch (e) {
      if (mounted) ErrorHandler.showSnack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final startupState = context.read<AppStartupState>();
    final isDemoMode = !startupState.firebaseEnabled;

    Widget formContent = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
                    if (isDemoMode) ...[
                      PremiumGlassCard(
                        borderColor: Colors.amber.withValues(alpha: 0.28),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline_rounded, color: Colors.amberAccent),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                startupState.startupWarning ??
                                    'Demo mode active. Use demo credentials to continue.',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.white.withValues(alpha: 0.9),
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    PremiumTextField(
                      controller: _email,
                      label: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.email,
                      enabled: !_busy,
                    ),
                    const SizedBox(height: 16),
                    PremiumTextField(
                      controller: _password,
                      label: 'Password',
                      obscureText: _obscure,
                      prefixIcon: const Icon(Icons.password_outlined),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure ? Icons.visibility : Icons.visibility_off,
                        ),
                      ),
                      validator: Validators.password,
                      enabled: !_busy,
                    ),
                    const SizedBox(height: 28),
                    PremiumButton(
                      label: _busy ? 'Signing in…' : 'Login',
                      expand: true,
                      onPressed: _busy ? null : _submit,
                      icon: _busy ? null : Icons.login_rounded,
                    ),
                    if (isDemoMode) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: PremiumButton(
                              label: 'Demo owner',
                              outlined: true,
                              expand: true,
                              icon: Icons.workspace_premium_outlined,
                              onPressed: _busy
                                  ? null
                                  : () {
                                      _email.text = AuthService.demoOwnerEmail;
                                      _password.text = AuthService.demoPassword;
                                    },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: PremiumButton(
                              label: 'Demo staff',
                              outlined: true,
                              expand: true,
                              icon: Icons.badge_outlined,
                              onPressed: _busy
                                  ? null
                                  : () {
                                      _email.text = AuthService.demoStaffEmail;
                                      _password.text = AuthService.demoPassword;
                                    },
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 32),
        ],
      ),
    );

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF050C18),
              Color(0xFF0A1C35),
              Color(0xFF0F2F57),
            ],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 980;
            final brandPanel = Padding(
              padding: const EdgeInsets.fromLTRB(28, 56, 28, 28),
              child: PremiumGlassCard(
                borderColor: const Color(0xFF13A7FF).withValues(alpha: 0.35),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: isWide ? MainAxisAlignment.center : MainAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7A37FF), Color(0xFF13A7FF)],
                        ),
                      ),
                      child: const Icon(
                        Icons.inventory_2_rounded,
                        size: 34,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'INVENTORY',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.4,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'AI Powered Smart Inventory',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                    ),
                    const SizedBox(height: 10),
                    const AnimatedFeatureHero(
                      title: 'Smart Inventory Access',
                      subtitle: 'Secure sign-in to warehouse and POS operations.',
                      icon: Icons.lock_open_rounded,
                      compact: true,
                      gradientColors: [Color(0xFF7A37FF), Color(0xFF13A7FF), Color(0xFF1DE2B0)],
                      animationType: FeatureHeroAnimationType.settings,
                    ),
                    const SizedBox(height: 18),
                    _ModeIndicator(isDemoMode: isDemoMode),
                    const SizedBox(height: 12),
                    Text(
                      'Owner, admin, and staff use the same screen. Access is scoped by your business role.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.86),
                            height: 1.4,
                          ),
                    ),
                  ],
                ),
              ),
            );
            final loginCard = TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              tween: Tween(begin: 0.985, end: 1),
              builder: (context, value, child) {
                return Transform.scale(scale: value, child: child);
              },
              child: SingleChildScrollView(
                padding: PremiumTokens.pagePadding(context),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: PremiumGlassCard(
                      borderColor: Colors.cyanAccent.withValues(alpha: 0.26),
                      child: formContent,
                    ),
                  ),
                ),
              ),
            );
            if (!isWide) {
              return Column(
                children: [
                  brandPanel,
                  Expanded(child: loginCard),
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: brandPanel),
                Expanded(child: loginCard),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ModeIndicator extends StatelessWidget {
  const _ModeIndicator({required this.isDemoMode});

  final bool isDemoMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: (isDemoMode ? Colors.amber : Colors.green).withValues(alpha: 0.15),
        border: Border.all(
          color: (isDemoMode ? Colors.amber : Colors.green).withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        isDemoMode ? 'Mode: Demo' : 'Mode: Firebase',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
