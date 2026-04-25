import 'package:cloud_firestore/cloud_firestore.dart';

class BusinessProfile {
  BusinessProfile({
    required this.businessId,
    required this.businessName,
    required this.ownerId,
    required this.address,
    required this.phone,
    required this.currency,
    required this.subscriptionPlan,
    required this.createdAt,
  });

  final String businessId;
  final String businessName;
  final String ownerId;
  final String address;
  final String phone;
  final String currency;
  final String subscriptionPlan;
  final DateTime? createdAt;

  factory BusinessProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    return BusinessProfile(
      businessId: doc.id,
      businessName: d['businessName'] as String? ?? 'My Business',
      ownerId: d['ownerId'] as String? ?? '',
      address: d['address'] as String? ?? '',
      phone: d['phone'] as String? ?? '',
      currency: d['currency'] as String? ?? 'BDT',
      subscriptionPlan: d['subscriptionPlan'] as String? ?? 'free',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'businessName': businessName,
        'ownerId': ownerId,
        'address': address,
        'phone': phone,
        'currency': currency,
        'subscriptionPlan': subscriptionPlan,
      };
}
