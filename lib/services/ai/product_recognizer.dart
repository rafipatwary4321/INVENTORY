import 'dart:math';

import 'package:image_picker/image_picker.dart';

/// Output shape for product recognition.
class ProductRecognitionResult {
  const ProductRecognitionResult({
    required this.productName,
    required this.confidence,
    required this.source,
    this.detectedCategory,
    this.suggestedBuyingPrice,
    this.suggestedSellingPrice,
  });

  final String productName;
  final double confidence;
  final String source;
  final String? detectedCategory;
  final double? suggestedBuyingPrice;
  final double? suggestedSellingPrice;
}

/// Future-facing interface for swapping mock AI with TFLite / ML Kit.
abstract class ProductRecognizer {
  Future<ProductRecognitionResult> recognize(
    XFile image, {
    String? mockHint,
  });
}

/// Mock implementation:
/// - keyword matching from image path/name
/// - fallback deterministic pseudo-random label
class MockProductRecognizer implements ProductRecognizer {
  const MockProductRecognizer();

  static const Map<String, String> _keywordMap = {
    'potato': 'Alu',
    'alu': 'Alu',
    'onion': 'Peyaj',
    'peyaj': 'Peyaj',
    'chal': 'Chal',
    'tomato': 'Tomato',
    'rice': 'Chal',
    'dal': 'Dal',
    'oil': 'Soybean Oil',
    'sugar': 'Sugar',
  };

  static const List<String> _fallbackNames = [
    'Alu',
    'Peyaj',
    'Chal',
    'Dal',
    'Soybean Oil',
    'Sugar',
  ];

  @override
  Future<ProductRecognitionResult> recognize(
    XFile image, {
    String? mockHint,
  }) async {
    // Simulate lightweight local inference latency.
    await Future<void>.delayed(const Duration(milliseconds: 450));

    final lower = '${mockHint ?? ''} ${image.path}'.toLowerCase();
    for (final entry in _keywordMap.entries) {
      if (lower.contains(entry.key)) {
        return ProductRecognitionResult(
          productName: entry.value,
          confidence: 0.91,
          source: 'mock-keyword',
          detectedCategory: _categoryFor(entry.value),
          suggestedBuyingPrice: _suggestedBuy(entry.value),
          suggestedSellingPrice: _suggestedSell(entry.value),
        );
      }
    }

    final rng = Random(image.path.hashCode);
    final detected = _fallbackNames[rng.nextInt(_fallbackNames.length)];
    final confidence = 0.62 + (rng.nextDouble() * 0.18);
    return ProductRecognitionResult(
      productName: detected,
      confidence: confidence,
      source: 'mock-random',
      detectedCategory: _categoryFor(detected),
      suggestedBuyingPrice: _suggestedBuy(detected),
      suggestedSellingPrice: _suggestedSell(detected),
    );
  }

  String _categoryFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('oil')) return 'Grocery';
    if (n.contains('sugar') || n.contains('chal') || n.contains('dal')) {
      return 'Staples';
    }
    return 'Vegetable';
  }

  double _suggestedBuy(String name) {
    switch (name.toLowerCase()) {
      case 'alu':
        return 35;
      case 'peyaj':
        return 95;
      case 'chal':
        return 62;
      case 'dal':
        return 110;
      case 'soybean oil':
        return 170;
      case 'sugar':
        return 120;
      default:
        return 80;
    }
  }

  double _suggestedSell(String name) => _suggestedBuy(name) * 1.15;
}
