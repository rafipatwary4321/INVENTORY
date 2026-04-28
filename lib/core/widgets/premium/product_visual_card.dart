import 'package:flutter/material.dart';

import '../../../models/product.dart';
import 'product_card.dart';

class ProductVisualCard extends StatelessWidget {
  const ProductVisualCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ProductCard(product: product, onTap: onTap);
  }
}
