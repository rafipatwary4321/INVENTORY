import 'package:flutter_test/flutter_test.dart';
import 'package:inventory/models/product.dart';
import 'package:inventory/models/sale_item.dart';
import 'package:inventory/services/ai/ai_api_service.dart';

Product _product({
  required String id,
  required String name,
  required int quantity,
}) {
  return Product(
    id: id,
    name: name,
    category: 'General',
    buyingPrice: 50,
    sellingPrice: 70,
    quantity: quantity,
    unit: 'pcs',
    imageUrl: null,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    createdBy: 'test',
  );
}

SaleItem _saleItem({
  required String id,
  required String productId,
  required String productName,
  required int qty,
}) {
  return SaleItem(
    id: id,
    saleId: 's1',
    productId: productId,
    productName: productName,
    unitPrice: 70,
    quantity: qty,
    lineTotal: 70.0 * qty,
    buyingPriceAtSale: 50,
    createdAt: DateTime(2026, 1, 2),
  );
}

void main() {
  group('AIApiService configuration and prompt', () {
    test('is not configured when API key missing', () {
      const config = AIApiConfig(
        providerRaw: 'openai',
        apiKey: '',
        model: '',
      );
      final service = AIApiService(config: config);
      expect(service.provider, AIProvider.openai);
      expect(service.isConfigured, isFalse);
    });

    test('is configured when provider and API key exist', () {
      const config = AIApiConfig(
        providerRaw: 'gemini',
        apiKey: 'test-key',
        model: '',
      );
      final service = AIApiService(config: config);
      expect(service.provider, AIProvider.gemini);
      expect(service.isConfigured, isTrue);
    });

    test('builds prompt with inventory and sales context', () {
      final service = AIApiService(
        config: const AIApiConfig(
          providerRaw: 'none',
          apiKey: '',
          model: '',
        ),
      );
      final prompt = service.buildAssistantPrompt(
        query: 'What should I restock?',
        products: [
          _product(id: 'p1', name: 'Oil', quantity: 3),
          _product(id: 'p2', name: 'Rice', quantity: 20),
        ],
        saleItems: [
          _saleItem(id: 'i1', productId: 'p1', productName: 'Oil', qty: 5),
        ],
      );

      expect(prompt, contains('What should I restock?'));
      expect(prompt, contains('Product list:'));
      expect(prompt, contains('Oil'));
      expect(prompt, contains('stock=3 pcs'));
      expect(prompt, contains('Sales data:'));
      expect(prompt, contains('lineProfit=100.00'));
    });
  });
}
