import 'package:flutter/material.dart';

import '../core/widgets/premium/premium_ui.dart';

/// Shown when a named route is opened without a required argument (e.g. product id).
class MissingRouteArgumentScreen extends StatelessWidget {
  const MissingRouteArgumentScreen({
    super.key,
    required this.routeName,
    this.hint = 'Open this screen from the app menu with a valid item.',
  });

  final String routeName;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const NeonAppBar(
        title: 'Missing information',
        subtitle: 'Navigation',
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: PremiumTokens.darkAnalyticsGradient),
        child: Center(
          child: SingleChildScrollView(
            padding: PremiumTokens.pagePadding(context),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: ErrorStateWidget(
                title: 'This page needs an id or argument.',
                subtitle: 'Route: $routeName\n$hint',
                retryLabel: 'Go back',
                retryIcon: Icons.arrow_back_rounded,
                onRetry: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    // Keep in sync with [AppRoutes.dashboard] in app_router.dart.
                    Navigator.of(context).pushReplacementNamed('/dashboard');
                  }
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

bool routeIdMissing(String? id) => id == null || id.trim().isEmpty;
