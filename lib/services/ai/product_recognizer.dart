import 'dart:math';

import 'package:image_picker/image_picker.dart';

/// Output shape for product recognition.
class ProductRecognitionResult {
  const ProductRecognitionResult({
    required this.productName,
    required this.confidence,
    required this.source,
  });

  final String productName;
  final double confidence;
  final String source;
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
    'tomato': 'Tomato',
    'rice': 'Chal',
    'oil': 'Soybean Oil',
  };

  static const List<String> _fallbackNames = [
    'Alu',
    'Peyaj',
    'Tomato',
    'Chal',
    'Soybean Oil',
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
    );
  }
}
