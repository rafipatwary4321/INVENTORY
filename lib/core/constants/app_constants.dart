/// App-wide constants (Firestore paths, thresholds, labels).
class AppConstants {
  AppConstants._();

  // Firestore collection names
  static const String usersCollection = 'users';
  static const String productsCollection = 'products';
  static const String stockTransactionsCollection = 'stock_transactions';
  static const String salesCollection = 'sales';
  static const String saleItemsCollection = 'sale_items';
  static const String settingsCollection = 'settings';

  /// Single document id for business settings (one shop per app instance).
  static const String settingsDocId = 'business';

  static const String defaultCurrency = 'BDT';

  /// Quantity strictly below this value counts as "low stock".
  static const int lowStockThreshold = 5;

  /// QR payload prefix so scans are clearly ours (optional safety).
  static const String qrPrefix = 'inv:product:';
}
