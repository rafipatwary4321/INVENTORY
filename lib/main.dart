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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final firestore = FirebaseFirestore.instance;
  final productService = ProductService(firestore);
  final saleService = SaleService(firestore, productService);

  runApp(InventoryApp(
    productService: productService,
    saleService: saleService,
  ));
}

/// Root widget: services + [Provider] notifiers + MaterialApp.
class InventoryApp extends StatelessWidget {
  const InventoryApp({
    super.key,
    required this.productService,
    required this.saleService,
  });

  final ProductService productService;
  final SaleService saleService;

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;
    final storage = FirebaseStorage.instance;

    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService(auth)),
        Provider<UserService>(create: (_) => UserService(firestore)),
        Provider<ProductService>.value(value: productService),
        Provider<SaleService>.value(value: saleService),
        Provider<StorageService>(create: (_) => StorageService(storage)),
        Provider<SettingsService>(create: (_) => SettingsService(firestore)),
        ChangeNotifierProvider(
          create: (c) => AuthProvider(c.read<AuthService>(), c.read<UserService>()),
        ),
        ChangeNotifierProvider(
          create: (c) => ProductsProvider(c.read<ProductService>()),
        ),
        ChangeNotifierProvider(
          create: (c) => SalesProvider(c.read<SaleService>()),
        ),
        ChangeNotifierProvider(
          create: (c) => SettingsProvider(c.read<SettingsService>()),
        ),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        title: 'INVENTORY',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }
}
