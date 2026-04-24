import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';

/// Product document in `products/{productId}`.
class Product {
  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.buyingPrice,
    required this.sellingPrice,
    required this.quantity,
    required this.unit,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  final String id;
  final String name;
  final String category;
  final double buyingPrice;
  final double sellingPrice;
  final int quantity;
  final String unit;
  final String? imageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String createdBy;

  bool get isLowStock => quantity <= AppConstants.lowStockThreshold;

  double get stockValue => buyingPrice * quantity;

  factory Product.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    return Product(
      id: doc.id,
      name: d['name'] as String? ?? '',
      category: d['category'] as String? ?? '',
      buyingPrice: (d['buyingPrice'] as num?)?.toDouble() ?? 0,
      sellingPrice: (d['sellingPrice'] as num?)?.toDouble() ?? 0,
      quantity: (d['quantity'] as num?)?.toInt() ?? 0,
      unit: d['unit'] as String? ?? 'pcs',
      imageUrl: d['imageUrl'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
      createdBy: d['createdBy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'category': category,
        'buyingPrice': buyingPrice,
        'sellingPrice': sellingPrice,
        'quantity': quantity,
        'unit': unit,
        'imageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  Map<String, dynamic> toCreateMap(String uid) => {
        ...toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': uid,
      };
}
