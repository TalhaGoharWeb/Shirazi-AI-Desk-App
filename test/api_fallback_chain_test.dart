import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shirazi_app/services/api_service.dart';
import 'package:shirazi_app/services/storage_service.dart';
import 'package:shirazi_app/providers/settings_provider.dart';
import 'package:shirazi_app/models/chat_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Multi-Tier Fallback and Encrypted BYOK Tests', () {
    late StorageService storage;
    late SettingsProvider settings;
    late ApiService api;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      storage = StorageService(prefs);
      api = ApiService();
      settings = SettingsProvider(storageService: storage, apiService: api);
    });

    test('Device-bound key encryption persists cipher and returns decrypted plain key', () async {
      const plainKey = 'AIzaSySecretGemini123';
      storage.geminiKey = plainKey;

      // Plain getter returns decrypted key
      expect(storage.geminiKey, plainKey);

      // Verify raw SharedPreferences does NOT store the plaintext key
      final prefs = await SharedPreferences.getInstance();
      final rawPersisted = prefs.getString('byok_gemini');
      expect(rawPersisted, isNotNull);
      expect(rawPersisted, isNot(plainKey));
      expect(rawPersisted!.startsWith('enc_'), isTrue);
    });

    test('Fallback chain respects preferred and secondary priority', () {
      storage.geminiKey = 'gemini-key-123';
      storage.groqKey = 'groq-key-456';
      storage.openRouterKey = 'openrouter-key-789';

      // Default: preferred is gemini, secondary is groq
      storage.preferredProvider = 'gemini';
      storage.secondaryProvider = 'groq';

      var chain = storage.getActiveFallbackChain();
      expect(chain, ['gemini', 'groq', 'openrouter']);

      // Switch preferred to groq, secondary to openrouter
      storage.preferredProvider = 'groq';
      storage.secondaryProvider = 'openrouter';

      chain = storage.getActiveFallbackChain();
      expect(chain, ['groq', 'openrouter', 'gemini']);
    });

    test('Disabling a provider removes it from the active fallback chain', () {
      storage.geminiKey = 'gemini-key-123';
      storage.groqKey = 'groq-key-456';
      storage.preferredProvider = 'gemini';
      storage.secondaryProvider = 'groq';

      expect(storage.getActiveFallbackChain(), ['gemini', 'groq']);

      // Disable gemini
      storage.setProviderEnabled('gemini', false);
      expect(storage.isProviderEnabled('gemini'), isFalse);

      // Active chain should now only contain groq
      final chain = storage.getActiveFallbackChain();
      expect(chain, ['groq']);
      expect(chain.contains('gemini'), isFalse);
    });

    test('Deleting a provider key removes it from storage and chain', () {
      storage.geminiKey = 'gemini-key-123';
      expect(storage.geminiKey, 'gemini-key-123');

      settings.deleteKey('gemini');
      expect(storage.geminiKey, '');
      expect(storage.getActiveFallbackChain().contains('gemini'), isFalse);
    });

    test('Masked key protects UI visibility while showing partial identity', () {
      storage.geminiKey = 'AIzaSyD538FakeKeySample999';
      final masked = settings.getMaskedKey('gemini');

      expect(masked.startsWith('AIzaSy'), isTrue);
      expect(masked.endsWith('e999'), isTrue);
      expect(masked.contains('••••'), isTrue);
      expect(masked, isNot('AIzaSyD538FakeKeySample999'));
    });

    test('Graceful failure protocol returns EXHAUSTED and preserves canRetry without fabricating answers', () async {
      // Intentionally configure an unreachable base URL and dummy keys
      final offlineApi = ApiService(baseUrl: 'http://127.0.0.1:54321');

      final result = await offlineApi.streamRealtimeQuery(
        text: 'ما حكم زكاة الفطر؟',
        persona: 'muhaqqiq',
        lang: 'ar',
        madhhab: 'Hanafi',
        providerPriority: ['gemini'],
        fallbackKeys: {'gemini': 'dummy-invalid-key'},
      );

      // Verify failure handling conforms to requirement 6:
      // Does NOT fabricate fake fatwa; returns structured exhaustion state
      expect(result['status'], 'EXHAUSTED');
      expect(result['isExhausted'], isTrue);
      expect(result['canRetry'], isTrue);
      expect(result['answer'], contains('تعذر معالجة الطلب'));
      expect(result['answer'], contains('إعادة المحاولة'));
    });

    test('ShiraziChatMessage model accurately serializes isError and canRetry states', () {
      final msg = ShiraziChatMessage(
        id: 'msg_test_1',
        conversationId: 'conv_test_1',
        sender: 'assistant',
        content: 'Network at capacity',
        timestamp: DateTime.now(),
        isError: true,
        canRetry: true,
        failedQuery: 'What are the pillars of Hajj?',
      );

      final map = msg.toFirestore();
      expect(map['isError'], isTrue);
      expect(map['canRetry'], isTrue);
      expect(map['failedQuery'], 'What are the pillars of Hajj?');

      final deserialized = ShiraziChatMessage.fromMap('msg_test_1', map);
      expect(deserialized.isError, isTrue);
      expect(deserialized.canRetry, isTrue);
      expect(deserialized.failedQuery, 'What are the pillars of Hajj?');
    });
  });
}
