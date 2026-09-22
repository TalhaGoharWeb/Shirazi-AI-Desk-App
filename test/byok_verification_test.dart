import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shirazi_app/services/api_service.dart';
import 'package:shirazi_app/services/storage_service.dart';
import 'package:shirazi_app/providers/settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BYOK Sanitization and Verification Tests', () {
    test('sanitizeApiKey strips whitespace, quotes, and Bearer prefix', () {
      expect(ApiService.sanitizeApiKey('  AIzaSyTest123  '), 'AIzaSyTest123');
      expect(ApiService.sanitizeApiKey('"gsk_my_groq_key"'), 'gsk_my_groq_key');
      expect(ApiService.sanitizeApiKey("'sk-or-v1-my-key'"), 'sk-or-v1-my-key');
      expect(ApiService.sanitizeApiKey('Bearer gsk_token123'), 'gsk_token123');
      expect(ApiService.sanitizeApiKey('Bearer "sk-or-secret"'), 'sk-or-secret');
      expect(ApiService.sanitizeApiKey("Bearer   'AIzaSyToken' \n"), 'AIzaSyToken');
    });

    test('SettingsProvider handles empty testConnection attempt', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = StorageService(prefs);
      final api = ApiService();
      final settings = SettingsProvider(storageService: storage, apiService: api);

      // Testing without entering a key should NOT say 'Key Verification Failed'
      await settings.testConnection('');
      expect(settings.testStatus, 'Please enter an API key');

      await settings.testConnection('    ');
      expect(settings.testStatus, 'Please enter an API key');
    });

    test('SettingsProvider auto-saves key when testing connection with candidate key', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = StorageService(prefs);
      final api = ApiService();
      final settings = SettingsProvider(storageService: storage, apiService: api);

      settings.selectProvider('gemini');
      expect(settings.currentApiKey, '');

      // User enters key with whitespace and quotes
      const rawCandidate = '  "AIzaSyFakeSampleKey123"  ';
      await settings.testConnection(rawCandidate);

      // Verify that the sanitized key was automatically saved to storage
      expect(settings.currentApiKey, 'AIzaSyFakeSampleKey123');
      expect(storage.geminiKey, 'AIzaSyFakeSampleKey123');
      // Status will report invalid key or network, but definitely not immediate empty failure
      expect(settings.testStatus, isNot('Key Verification Failed'));
      print('Diagnostics status for fake key: ${settings.testStatus}');
    });

    test('ApiService rejects server limit messages and returns EXHAUSTED failure without fabricating answers', () async {
      final api = ApiService();
      const serverOutageMsg = 'اس وقت تحقیقی نظام کے تمام دستیاب AI ذرائع عارضی طور پر مصروف یا دستیاب نہیں ہیں۔ براہِ کرم کچھ دیر بعد دوبارہ کوشش فرمائیں۔';

      // Simulating a query without keys where server would emit outage message or timeout
      final res = await api.streamRealtimeQuery(
        text: 'ما حكم صلاة العيد؟',
        persona: 'mufti',
        lang: 'ur',
      );

      // In accordance with Requirement 6: Do not silently generate a fabricated answer
      expect(res['status'], 'EXHAUSTED');
      expect(res['isExhausted'], isTrue);
      expect(res['canRetry'], isTrue);
      expect(res['answer'], isNot(contains(serverOutageMsg)));
      print('Fallback response: ${res['answer']}');
    });
  });
}
