import 'package:flutter/material.dart';

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
      appBar: AppBar(title: const Text('Missing information')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.link_off_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'This page needs an id or argument.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Route: $routeName\n$hint',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    // Must match [AppRoutes.dashboard] in app_router.dart.
                    Navigator.of(context)
                        .pushReplacementNamed('/dashboard');
                  }
                },
                child: const Text('Go back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

bool routeIdMissing(String? id) => id == null || id.trim().isEmpty;
