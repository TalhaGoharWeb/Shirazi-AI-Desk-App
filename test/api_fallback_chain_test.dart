import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shirazi_app/services/api_service.dart';
import 'package:shirazi_app/services/storage_service.dart';
import 'package:shirazi_app/providers/settings_provider.dart';
import 'package:shirazi_app/models/chat_models.dart';

import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Multi-Tier Fallback and Encrypted BYOK Tests', () {
    late StorageService storage;
    late SettingsProvider settings;
    late ApiService api;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      mockSecureStorage();
      final prefs = await SharedPreferences.getInstance();
      storage = StorageService(prefs);
      // BYOK keys are namespaced by account UID; the test vault needs an
      // owner, mirroring setActiveUid on sign-in in production.
      await storage.setActiveUid('test-uid');
      api = ApiService();
      settings = SettingsProvider(storageService: storage, apiService: api);
    });

    test('Secure key storage persists via platform secure storage, never as plaintext prefs', () async {
      const plainKey = 'AIzaSySecretGemini123';
      // NOTE: use the awaitable saveKey — the `geminiKey` setter is
      // fire-and-forget by design, so it cannot be asserted synchronously.
      final ok = await storage.saveKey('gemini', plainKey);
      expect(ok, isTrue);

      // Plain getter returns the saved key
      expect(storage.geminiKey, plainKey);

      // The plaintext key must NOT land in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('byok_gemini'), isNull);
    });

    test('Fallback chain respects preferred and secondary priority', () async {
      await storage.saveKey('gemini', 'gemini-key-123');
      await storage.saveKey('groq', 'groq-key-456');
      await storage.saveKey('openrouter', 'openrouter-key-789');

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

    test('Disabling a provider removes it from the active fallback chain', () async {
      await storage.saveKey('gemini', 'gemini-key-123');
      await storage.saveKey('groq', 'groq-key-456');
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

    test('Deleting a provider key removes it from storage and chain', () async {
      await storage.saveKey('gemini', 'gemini-key-123');
      expect(storage.geminiKey, 'gemini-key-123');

      // Awaitable form of the delete path (SettingsProvider.deleteKey
      // delegates to it); empty value deletes the key from secure storage.
      await storage.saveKey('gemini', '');
      expect(storage.geminiKey, '');
      expect(storage.getActiveFallbackChain().contains('gemini'), isFalse);
    });

    test('Keys are isolated per account UID and wiped on sign-out', () async {
      // Account A saves a key in its own namespace.
      await storage.setActiveUid('uid-A');
      expect(await storage.saveKey('gemini', 'A-key'), isTrue);
      expect(storage.getKeyForProvider('gemini'), 'A-key');

      // Sign out: the in-memory vault is wiped synchronously.
      await storage.setActiveUid(null);
      expect(storage.getKeyForProvider('gemini'), '');

      // Account B on the same device sees none of A's keys.
      await storage.setActiveUid('uid-B');
      expect(storage.getKeyForProvider('gemini'), '');

      // B's own keys land in B's namespace only.
      expect(await storage.saveKey('gemini', 'B-key'), isTrue);
      expect(storage.getKeyForProvider('gemini'), 'B-key');

      // Back to A: A's keys are restored, B's are invisible.
      await storage.setActiveUid('uid-A');
      expect(storage.getKeyForProvider('gemini'), 'A-key');
    });

    test('saveKey refuses writes with no signed-in account', () async {
      await storage.setActiveUid(null);
      expect(await storage.saveKey('gemini', 'no-owner-key'), isFalse);
      expect(storage.lastKeyWriteError, isNotNull);
    });

    test('Masked key protects UI visibility while showing partial identity', () async {
      await storage.saveKey('gemini', 'AIzaSyD538FakeKeySample999');
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
      // Does NOT fabricate fake fatwa; returns structured exhaustion state.
      // NOTE: plain-HTTP endpoints are now refused outright — the client must
      // never transmit user keys over insecure transport (§1, §5).
      expect(result['status'], 'EXHAUSTED');
      expect(result['isExhausted'], isTrue);
      expect(result['canRetry'], isTrue);
      expect(result['failure'], 'insecureTransportBlocked');
      expect(result['answer'], contains('قيد أمني'));
      expect(result['answer'], isNot(contains('dummy-invalid-key')));
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
