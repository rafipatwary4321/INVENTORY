import 'package:cloud_firestore/cloud_firestore.dart';

/// Business settings in `settings/business`.
class AppSettings {
  AppSettings({
    required this.businessName,
    required this.currency,
  });

  final String businessName;
  final String currency;

  factory AppSettings.fromMap(Map<String, dynamic>? d) {
    return AppSettings(
      businessName: d?['businessName'] as String? ?? 'My Shop',
      currency: d?['currency'] as String? ?? 'BDT',
    );
  }

  Map<String, dynamic> toMap() => {
        'businessName': businessName,
        'currency': currency,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
