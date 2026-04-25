import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/products_provider.dart';
import 'providers/sales_provider.dart';
import 'providers/settings_provider.dart';
import 'routes/app_router.dart';
import 'services/auth_service.dart';
import 'services/product_service.dart';
import 'services/sale_service.dart';
import 'services/settings_service.dart';
import 'services/storage_service.dart';
import 'services/user_service.dart';

class AppStartupState {
  const AppStartupState({
    required this.firebaseEnabled,
    this.startupWarning,
  });

  final bool firebaseEnabled;
  final String? startupWarning;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var firebaseEnabled = false;
  String? startupWarning;

  bool isFirebaseConfigured() {
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

  if (isFirebaseConfigured()) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      firebaseEnabled = true;
    } catch (e, stack) {
      debugPrint('Firebase.initializeApp failed: $e\n$stack');
      startupWarning = 'Firebase unavailable. Running in demo mode.';
    }
  } else {
    startupWarning =
        'Firebase not configured. Running in demo mode. Configure with flutterfire configure.';
  }

  final firestore = firebaseEnabled ? FirebaseFirestore.instance : null;
  final auth = firebaseEnabled ? FirebaseAuth.instance : null;
  final storage = firebaseEnabled ? FirebaseStorage.instance : null;
  final productService = ProductService(
    firestore: firestore,
    firebaseEnabled: firebaseEnabled,
  );
  final saleService = SaleService(
    firestore: firestore,
    products: productService,
    firebaseEnabled: firebaseEnabled,
  );
  final settingsService =
      firestore != null ? SettingsService(firestore) : null;
  final storageService = StorageService(
    storage: storage,
    firebaseEnabled: firebaseEnabled,
  );
  final userService = firestore != null ? UserService(firestore) : null;

  runApp(InventoryProviders(
    startupState: AppStartupState(
      firebaseEnabled: firebaseEnabled,
      startupWarning: startupWarning,
    ),
    auth: auth,
    productService: productService,
    saleService: saleService,
    settingsService: settingsService,
    storageService: storageService,
    userService: userService,
  ));
}

/// Top-level provider scope for the whole app tree.
class InventoryProviders extends StatelessWidget {
  const InventoryProviders({
    super.key,
    required this.startupState,
    required this.auth,
    required this.productService,
    required this.saleService,
    required this.settingsService,
    required this.storageService,
    required this.userService,
  });

  final AppStartupState startupState;
  final FirebaseAuth? auth;
  final ProductService productService;
  final SaleService saleService;
  final SettingsService? settingsService;
  final StorageService storageService;
  final UserService? userService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppStartupState>.value(value: startupState),
        Provider<AuthService>(
          create: (_) =>
              AuthService(auth: auth, firebaseEnabled: startupState.firebaseEnabled),
        ),
        if (userService != null) Provider<UserService>.value(value: userService!),
        Provider<ProductService>.value(value: productService),
        Provider<SaleService>.value(value: saleService),
        Provider<StorageService>.value(value: storageService),
        if (settingsService != null)
          Provider<SettingsService>.value(value: settingsService!),
        ChangeNotifierProvider(
          create: (c) => AuthProvider(
            c.read<AuthService>(),
            userService,
          ),
        ),
        ChangeNotifierProvider(
          create: (c) => ProductsProvider(c.read<ProductService>()),
        ),
        ChangeNotifierProvider(
          create: (c) => SalesProvider(c.read<SaleService>()),
        ),
        if (settingsService != null)
          ChangeNotifierProvider(
            create: (c) => SettingsProvider(c.read<SettingsService>()),
          ),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: const InventoryApp(),
    );
  }
}

/// App shell with routes/screens; providers are injected above this widget.
class InventoryApp extends StatelessWidget {
  const InventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'INVENTORY',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
