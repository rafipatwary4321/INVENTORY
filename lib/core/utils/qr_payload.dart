import '../constants/app_constants.dart';

/// Encodes/decodes product id in QR strings shown on labels.
class QrPayload {
  QrPayload._();

  static String encodeProductId(String productId) {
    return '${AppConstants.qrPrefix}$productId';
  }

  /// Returns product id if valid payload; otherwise null.
  ///
  /// Accepts `inv:product:{id}` or a bare UUID (v4) string for testing and
  /// third-party printers that encode only the id.
  static String? decodeToProductId(String raw) {
    final t = raw.trim();
    if (t.startsWith(AppConstants.qrPrefix)) {
      final id = t.substring(AppConstants.qrPrefix.length);
      return id.isEmpty ? null : id;
    }
    if (_uuidV4.hasMatch(t)) {
      return t;
    }
    return null;
  }

  static final RegExp _uuidV4 = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );
}
