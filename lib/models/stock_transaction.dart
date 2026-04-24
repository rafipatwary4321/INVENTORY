import 'package:cloud_firestore/cloud_firestore.dart';

/// Stock movement: in (receive), out (sale/adjustment down), adjust.
enum StockTxType { in_, out, adjust }

extension StockTxTypeX on StockTxType {
  String get firestoreValue {
    switch (this) {
      case StockTxType.in_:
        return 'in';
      case StockTxType.out:
        return 'out';
      case StockTxType.adjust:
        return 'adjust';
    }
  }

  static StockTxType fromString(String? s) {
    switch (s) {
      case 'out':
        return StockTxType.out;
      case 'adjust':
        return StockTxType.adjust;
      default:
        return StockTxType.in_;
    }
  }
}

class StockTransaction {
  StockTransaction({
    required this.id,
    required this.productId,
    required this.type,
    required this.quantity,
    required this.userId,
    this.note,
    this.relatedSaleId,
    required this.createdAt,
  });

  final String id;
  final String productId;
  final StockTxType type;
  final int quantity;
  final String userId;
  final String? note;
  final String? relatedSaleId;
  final DateTime? createdAt;

  factory StockTransaction.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    return StockTransaction(
      id: doc.id,
      productId: d['productId'] as String? ?? '',
      type: StockTxTypeX.fromString(d['type'] as String?),
      quantity: (d['quantity'] as num?)?.toInt() ?? 0,
      userId: d['userId'] as String? ?? '',
      note: d['note'] as String?,
      relatedSaleId: d['relatedSaleId'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  static Map<String, dynamic> createMap({
    required String productId,
    required StockTxType type,
    required int quantity,
    required String userId,
    String? note,
    String? relatedSaleId,
  }) =>
      {
        'productId': productId,
        'type': type.firestoreValue,
        'quantity': quantity,
        'userId': userId,
        'note': note,
        'relatedSaleId': relatedSaleId,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
