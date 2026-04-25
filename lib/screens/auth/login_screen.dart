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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 56, 24, 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    cs.primary,
                    Color.lerp(cs.primary, cs.secondary, 0.35)!,
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(PremiumTokens.radiusXl),
                ),
                boxShadow: PremiumTokens.cardShadow(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.layers_rounded,
                    size: 40,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Sign in',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Owner, admin, and staff use the same screen. '
                    'Access is scoped by your business role.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          height: 1.4,
                        ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: PremiumTokens.pagePadding(context),
            sliver: SliverToBoxAdapter(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isDemoMode) ...[
                      ReportCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline_rounded, color: cs.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                startupState.startupWarning ??
                                    'Demo mode active. Use demo credentials to continue.',
                                style: Theme.of(context).textTheme.bodySmall,
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}
