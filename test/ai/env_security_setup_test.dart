import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory/services/ai/ai_api_service.dart';

void main() {
  group('Security + .env AI setup', () {
    test('fallback mode when env key missing', () {
      dotenv.testLoad(fileInput: 'AI_PROVIDER=\nAI_API_KEY=\nAI_MODEL=\n');
      final service = AIApiService();
      expect(service.isConfigured, isFalse);
      expect(service.provider, AIProvider.none);
    });

    test('reads provider and key from .env values', () {
      dotenv.testLoad(
        fileInput:
            'AI_PROVIDER=openai\nAI_API_KEY=test-secret-key\nAI_MODEL=gpt-4o-mini\n',
      );
      final service = AIApiService();
      expect(service.provider, AIProvider.openai);
      expect(service.isConfigured, isTrue);
    });
  });
}
