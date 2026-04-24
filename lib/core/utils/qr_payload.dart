import '../constants/app_constants.dart';

/// Encodes/decodes product id in QR strings shown on labels.
class QrPayload {
  QrPayload._();

  static String encodeProductId(String productId) {
    return '${AppConstants.qrPrefix}$productId';
  }

  /// Returns product id if valid payload; otherwise null.
  static String? decodeToProductId(String raw) {
    final t = raw.trim();
    if (t.startsWith(AppConstants.qrPrefix)) {
      final id = t.substring(AppConstants.qrPrefix.length);
      return id.isEmpty ? null : id;
    }
    return null;
  }
}
