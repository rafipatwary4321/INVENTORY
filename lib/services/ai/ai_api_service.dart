import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/product.dart';
import '../../models/sale_item.dart';

enum AIProvider {
  none,
  openai,
  gemini,
}

class AIApiConfig {
  const AIApiConfig({
    required this.providerRaw,
    required this.apiKey,
    required this.model,
  });

  final String providerRaw;
  final String apiKey;
  final String model;

  static const fromEnvironment = AIApiConfig(
    providerRaw: String.fromEnvironment('AI_PROVIDER', defaultValue: ''),
    apiKey: String.fromEnvironment('AI_API_KEY', defaultValue: ''),
    model: String.fromEnvironment('AI_MODEL', defaultValue: ''),
  );
}

/// Real AI gateway.
///
/// Configuration is read from compile-time env values (no hardcoded secrets):
/// - AI_PROVIDER=openai|gemini
/// - AI_API_KEY=...
/// - AI_MODEL=optional model name
///
/// Example:
/// flutter run -d chrome --dart-define=AI_PROVIDER=openai --dart-define=AI_API_KEY=YOUR_KEY --dart-define=AI_MODEL=gpt-4o-mini
class AIApiService {
  AIApiService({
    http.Client? client,
    AIApiConfig config = AIApiConfig.fromEnvironment,
  })  : _client = client ?? http.Client(),
        _config = config;

  final http.Client _client;
  final AIApiConfig _config;

  AIProvider get provider {
    switch (_config.providerRaw.trim().toLowerCase()) {
      case 'openai':
        return AIProvider.openai;
      case 'gemini':
        return AIProvider.gemini;
      default:
        return AIProvider.none;
    }
  }

  bool get isConfigured => provider != AIProvider.none && _config.apiKey.trim().isNotEmpty;

  Future<String> askAssistant({
    required String query,
    required List<Product> products,
    required List<SaleItem> saleItems,
  }) async {
    if (!isConfigured) {
      throw StateError('AI API is not configured');
    }
    final prompt = buildAssistantPrompt(
      query: query,
      products: products,
      saleItems: saleItems,
    );
    switch (provider) {
      case AIProvider.openai:
        return _askOpenAI(prompt);
      case AIProvider.gemini:
        return _askGemini(prompt);
      case AIProvider.none:
        throw StateError('No AI provider selected');
    }
  }

  String buildAssistantPrompt({
    required String query,
    required List<Product> products,
    required List<SaleItem> saleItems,
  }) {
    final productLines = products
        .take(30)
        .map(
          (p) =>
              '- ${p.name} | category=${p.category} | stock=${p.quantity} ${p.unit} | buy=${p.buyingPrice} | sell=${p.sellingPrice}',
        )
        .join('\n');

    final salesLines = saleItems
        .take(60)
        .map(
          (s) =>
              '- ${s.productName} | qty=${s.quantity} | lineTotal=${s.lineTotal.toStringAsFixed(2)} | lineProfit=${s.lineProfit.toStringAsFixed(2)}',
        )
        .join('\n');

    return '''
You are an inventory business intelligence assistant.
Answer briefly and practically for a small retail inventory owner.
Focus on:
1) business insights
2) restock suggestions
3) profit analysis
If data is limited, say what is missing and give best effort.

User question:
$query

Product list:
${productLines.isEmpty ? '(no products)' : productLines}

Sales data:
${salesLines.isEmpty ? '(no sales)' : salesLines}
''';
  }

  Future<String> _askOpenAI(String prompt) async {
    final model =
        _config.model.trim().isEmpty ? 'gpt-4o-mini' : _config.model.trim();
    final res = await _client.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${_config.apiKey}',
      },
      body: jsonEncode({
        'model': model,
        'messages': [
          {
            'role': 'system',
            'content': 'You are a smart inventory analyst.',
          },
          {
            'role': 'user',
            'content': prompt,
          },
        ],
        'temperature': 0.2,
      }),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw StateError('OpenAI request failed (${res.statusCode})');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final choices = body['choices'] as List<dynamic>? ?? const [];
    if (choices.isEmpty) throw StateError('OpenAI returned no choices');
    final message = choices.first['message'] as Map<String, dynamic>?;
    final content = message?['content'] as String?;
    if (content == null || content.trim().isEmpty) {
      throw StateError('OpenAI returned empty content');
    }
    return content.trim();
  }

  Future<String> _askGemini(String prompt) async {
    final model =
        _config.model.trim().isEmpty ? 'gemini-1.5-flash' : _config.model.trim();
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=${_config.apiKey}',
    );
    final res = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.2,
        },
      }),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw StateError('Gemini request failed (${res.statusCode})');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final candidates = body['candidates'] as List<dynamic>? ?? const [];
    if (candidates.isEmpty) throw StateError('Gemini returned no candidates');
    final content = candidates.first['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>? ?? const [];
    if (parts.isEmpty) throw StateError('Gemini returned empty parts');
    final text = parts.first['text'] as String?;
    if (text == null || text.trim().isEmpty) {
      throw StateError('Gemini returned empty text');
    }
    return text.trim();
  }
}
