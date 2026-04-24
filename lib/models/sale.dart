import 'package:cloud_firestore/cloud_firestore.dart';

/// Header document in `sales/{saleId}`.
class Sale {
  Sale({
    required this.id,
    required this.totalAmount,
    required this.itemCount,
    required this.userId,
    this.customerNote,
    required this.createdAt,
  });

  final String id;
  final double totalAmount;
  final int itemCount;
  final String userId;
  final String? customerNote;
  final DateTime? createdAt;

  factory Sale.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Sale(
      id: doc.id,
      totalAmount: (d['totalAmount'] as num?)?.toDouble() ?? 0,
      itemCount: (d['itemCount'] as num?)?.toInt() ?? 0,
      userId: d['userId'] as String? ?? '',
      customerNote: d['customerNote'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  static Map<String, dynamic> createMap({
    required double totalAmount,
    required int itemCount,
    required String userId,
    String? customerNote,
  }) =>
      {
        'totalAmount': totalAmount,
        'itemCount': itemCount,
        'userId': userId,
        'customerNote': customerNote,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
