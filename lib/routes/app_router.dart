import 'package:flutter/material.dart';

import '../models/qr_scan_args.dart';
import 'route_errors.dart';
import '../screens/ai/ai_product_recognition_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/products/add_edit_product_screen.dart';
import '../screens/products/product_details_screen.dart';
import '../screens/products/product_list_screen.dart';
import '../screens/qr/qr_generate_screen.dart';
import '../screens/qr/qr_scanner_screen.dart';
import '../screens/reports/profit_loss_report_screen.dart';
import '../screens/reports/sales_report_screen.dart';
import '../screens/reports/stock_report_screen.dart';
import '../screens/sell/sell_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/stock/stock_in_screen.dart';

/// Central route names and [onGenerateRoute] for simple navigation.
class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const login = '/login';
  static const dashboard = '/dashboard';
  static const products = '/products';
  static const productAdd = '/products/add';
  static const productEdit = '/products/edit';
  static const productDetails = '/products/details';
  static const qrGenerate = '/qr/generate';
  static const qrScan = '/qr/scan';
  static const stockIn = '/stock/in';
  static const sell = '/sell';
  static const cart = '/cart';
  static const reportSales = '/reports/sales';
  static const reportStock = '/reports/stock';
  static const reportPnL = '/reports/pnl';
  static const aiRecognition = '/ai/recognition';
  static const settings = '/settings';

  static Route<dynamic> onGenerateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case AppRoutes.dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case AppRoutes.products:
        return MaterialPageRoute(builder: (_) => const ProductListScreen());
      case AppRoutes.productAdd:
        return MaterialPageRoute(builder: (_) => const AddEditProductScreen());
      case AppRoutes.productEdit:
        final id = routeSettings.arguments as String?;
        if (routeIdMissing(id)) {
          return MaterialPageRoute(
            builder: (_) => const MissingRouteArgumentScreen(
              routeName: 'productEdit',
              hint: 'Pass the product document id as the route argument.',
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => AddEditProductScreen(productId: id),
        );
      case AppRoutes.productDetails:
        final id = routeSettings.arguments as String?;
        if (routeIdMissing(id)) {
          return MaterialPageRoute(
            builder: (_) => const MissingRouteArgumentScreen(
              routeName: 'productDetails',
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => ProductDetailsScreen(productId: id!),
        );
      case AppRoutes.qrGenerate:
        final id = routeSettings.arguments as String?;
        if (routeIdMissing(id)) {
          return MaterialPageRoute(
            builder: (_) => const MissingRouteArgumentScreen(
              routeName: 'qrGenerate',
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => QRGenerateScreen(productId: id!),
        );
      case AppRoutes.qrScan:
        final args = routeSettings.arguments as QRScanArgs?;
        return MaterialPageRoute(
          builder: (_) => QRScannerScreen(mode: args?.mode ?? QRScanMode.stockIn),
        );
      case AppRoutes.stockIn:
        final id = routeSettings.arguments as String?;
        if (routeIdMissing(id)) {
          return MaterialPageRoute(
            builder: (_) => const MissingRouteArgumentScreen(
              routeName: 'stockIn',
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => StockInScreen(productId: id!),
        );
      case AppRoutes.sell:
        final id = routeSettings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => SellScreen(prefillProductId: id),
        );
      case AppRoutes.cart:
        return MaterialPageRoute(builder: (_) => const CartScreen());
      case AppRoutes.reportSales:
        return MaterialPageRoute(builder: (_) => const SalesReportScreen());
      case AppRoutes.reportStock:
        return MaterialPageRoute(builder: (_) => const StockReportScreen());
      case AppRoutes.reportPnL:
        return MaterialPageRoute(builder: (_) => const ProfitLossReportScreen());
      case AppRoutes.aiRecognition:
        return MaterialPageRoute(builder: (_) => const AIProductRecognitionScreen());
      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Route not found')),
          ),
        );
    }
  }
}
