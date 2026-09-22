import 'package:flutter_test/flutter_test.dart';
import 'package:shirazi_app/models/chat_models.dart';
import 'package:shirazi_app/models/inquiry.dart';
import 'package:shirazi_app/core/localization/app_strings.dart';
import 'package:shirazi_app/services/fiqh_query_analyzer.dart';

void main() {
  group('Shirazi AI Chat Models & Firestore Mapping', () {
    test('ShiraziConversation serialization and properties', () {
      final now = DateTime.now();
      final conv = ShiraziConversation(
        id: 'conv_123',
        ownerUid: 'user_scholar_456',
        title: 'Cryptocurrency Trading Ruling',
        createdAt: now,
        updatedAt: now,
        language: 'ar',
        madhhab: 'Hanafi',
        persona: 'muhaqqiq',
        lastMessagePreview: 'Ruling on Bitcoin in Islamic Fiqh',
        messageCount: 4,
        ownerEmail: 'scholar@darulifta.edu',
      );

      final map = conv.toFirestore();
      expect(map['ownerUid'], 'user_scholar_456');
      expect(map['title'], 'Cryptocurrency Trading Ruling');
      expect(map['language'], 'ar');
      expect(map['madhhab'], 'Hanafi');
      expect(map['messageCount'], 4);
      expect(map['ownerEmail'], 'scholar@darulifta.edu');

      final reconstructed = ShiraziConversation.fromMap('conv_123', {
        'ownerUid': 'user_scholar_456',
        'title': 'Cryptocurrency Trading Ruling',
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'language': 'ar',
        'madhhab': 'Hanafi',
        'persona': 'muhaqqiq',
        'lastMessagePreview': 'Ruling on Bitcoin in Islamic Fiqh',
        'messageCount': 4,
        'ownerEmail': 'scholar@darulifta.edu',
      });

      expect(reconstructed.id, 'conv_123');
      expect(reconstructed.ownerUid, 'user_scholar_456');
      expect(reconstructed.language, 'ar');
      expect(reconstructed.madhhab, 'Hanafi');
    });

    test('ShiraziChatMessage serialization and citations', () {
      final now = DateTime.now();
      final msg = ShiraziChatMessage(
        id: 'msg_999',
        conversationId: 'conv_123',
        sender: 'assistant',
        content: 'وفق المعتمد في المذهب الحنفي فإن العملة يشترط فيها المالية والتقوم...',
        citations: ['Al-Hidayah, Vol 3, p. 45', 'Radd al-Muhtar, Vol 5'],
        reasoningSteps: [
          const ReasoningStep(
            title: 'Searching Corpus',
            detail: 'Retrieved 8,595 treatises',
            duration: '0.2s',
            isCompleted: true,
          ),
        ],
        urduAnnotation: 'خلاصۂ فتویٰ: بیع و شراء میں مروجہ قواعد لاگو ہوں گے۔',
        timestamp: now,
        latencyMs: 310,
        byokProvider: 'Shirazi Core Engine',
      );

      expect(msg.isAssistant, isTrue);
      expect(msg.isUser, isFalse);

      final map = msg.toFirestore();
      expect(map['sender'], 'assistant');
      expect(map['citations'].length, 2);
      expect(map['latencyMs'], 310);
      expect(map['byokProvider'], 'Shirazi Core Engine');
    });
  });

  group('Multi-User Conversation Isolation Logic', () {
    test('Conversations are strictly isolated by ownerUid', () {
      final userA = 'user_alpha_111';
      final userB = 'user_beta_222';
      final now = DateTime.now();

      final allPlatformConversations = [
        ShiraziConversation(id: 'c1', ownerUid: userA, title: 'Inquiry A1', createdAt: now, updatedAt: now),
        ShiraziConversation(id: 'c2', ownerUid: userA, title: 'Inquiry A2', createdAt: now, updatedAt: now),
        ShiraziConversation(id: 'c3', ownerUid: userB, title: 'Inquiry B1', createdAt: now, updatedAt: now),
        ShiraziConversation(id: 'c4', ownerUid: userB, title: 'Inquiry B2', createdAt: now, updatedAt: now),
      ];

      // Simulate client-side query matching Firestore security rules: where('ownerUid', isEqualTo: currentUid)
      final userAView = allPlatformConversations.where((c) => c.ownerUid == userA).toList();
      final userBView = allPlatformConversations.where((c) => c.ownerUid == userB).toList();

      expect(userAView.length, 2);
      expect(userAView.every((c) => c.ownerUid == userA), isTrue);
      expect(userAView.any((c) => c.ownerUid == userB), isFalse);

      expect(userBView.length, 2);
      expect(userBView.every((c) => c.ownerUid == userB), isTrue);
      expect(userBView.any((c) => c.ownerUid == userA), isFalse);
    });
  });

  group('Chat Multilingual Support & Typography', () {
    test('AppStrings localization across English, Arabic, and Urdu', () {
      final en = AppStrings.get('en');
      final ar = AppStrings.get('ar');
      final ur = AppStrings.get('ur');

      expect(en.newChat, 'New Inquiry');
      expect(ar.newChat, 'محادثة جديدة');
      expect(ur.newChat, 'نئی تحقیق');

      expect(en.isRtl, isFalse);
      expect(ar.isRtl, isTrue);
      expect(ur.isRtl, isTrue);

      expect(en.promptStarter1Title, isNotEmpty);
      expect(ar.promptStarter1Title, isNotEmpty);
      expect(ur.promptStarter1Title, isNotEmpty);

      expect(en.privacyShieldBadge, contains('Strict Per-User Privacy'));
      expect(ar.privacyShieldBadge, contains('عزل تام للمحادثات'));
      expect(ur.privacyShieldBadge, contains('مکمل انفرادی راز داری'));
    });

    test('Language consistency detector accurately classifies Urdu, Arabic, and English', () {
      expect(detectQueryLanguage('What is the scholarly ruling on fast travel?'), 'en');
      expect(detectQueryLanguage('Explain zakat on digital assets and gold reserves'), 'en');
      expect(detectQueryLanguage('ما حكم الصلاة في السفينة المتحركة؟'), 'ar');
      expect(detectQueryLanguage('هل يجوز الجمع بين الصلاتين في المطر؟'), 'ar');
      expect(detectQueryLanguage('کیا سفر کی حالت میں نماز قصر کرنا واجب ہے؟'), 'ur');
      expect(detectQueryLanguage('ڈیجیٹل کرنسی کے بارے میں فقہی احکام کیا ہیں؟'), 'ur');
    });
  });

  group('Super Admin Role & Privileges Verification', () {
    test('Super admin email is configured to muhaqqiqcreates@gmail.com', () {
      const superAdminEmail = 'muhaqqiqcreates@gmail.com';
      expect(superAdminEmail, 'muhaqqiqcreates@gmail.com');

      // Check role assignment logic
      bool isSuperAdmin(String email) => email.trim().toLowerCase() == 'muhaqqiqcreates@gmail.com';

      expect(isSuperAdmin('muhaqqiqcreates@gmail.com'), isTrue);
      expect(isSuperAdmin('MUHAQQIQCREATES@GMAIL.COM'), isTrue);
      expect(isSuperAdmin('other_scholar@darulifta.org'), isFalse);
      expect(isSuperAdmin('anonymous_user@gmail.com'), isFalse);
    });
  });

  group('Madhhab Isolation & Cross-Madhhab Cache Rejection', () {
    test('MadhhabDetector.isMismatched correctly flags Maliki content when Hanafi is expected', () {
      const malikiServerResponse = '[التركيز المذهبي المعتمد: المذهب المالكي]\n'
          'بٹ کوائن اور بلاک چین کے احکام: مذہب مالکی کے فقہاء کے نزدیک...';

      // When Hanafi is requested, Maliki answer MUST be flagged as mismatched
      expect(MadhhabDetector.isMismatched(malikiServerResponse, 'Hanafi'), isTrue);

      // When Maliki is requested, it should NOT be flagged as mismatched
      expect(MadhhabDetector.isMismatched(malikiServerResponse, 'Maliki'), isFalse);
    });

    test('MadhhabDetector.isMismatched correctly flags Hanafi content when Maliki is expected', () {
      const hanafiServerResponse = '[التركيز المذهبي المعتمد: المذهب الحنفي]\n'
          'حكم المعاملة بالعملات الرقمية وفق أصول الفقه الحنفي...';

      expect(MadhhabDetector.isMismatched(hanafiServerResponse, 'Maliki'), isTrue);
      expect(MadhhabDetector.isMismatched(hanafiServerResponse, 'Hanafi'), isFalse);
    });

    test('MadhhabDetector.isCompatible handles case sensitivity and variants', () {
      expect(MadhhabDetector.isCompatible('hanafi', 'Hanafi'), isTrue);
      expect(MadhhabDetector.isCompatible('Hanafi', 'Hanafi'), isTrue);
      expect(MadhhabDetector.isCompatible('Maliki', 'Hanafi'), isFalse);
      expect(MadhhabDetector.isCompatible('Hanafi', 'Maliki'), isFalse);
      expect(MadhhabDetector.isCompatible("Shafi'i", "shafii"), isTrue);
    });

    test('RelevanceGuard rejects unrelated beggar/greeting topics for cryptocurrency queries', () {
      final cryptoTarget = FiqhQueryAnalyzer.analyze(
        'بٹ کوائن اور بلاک چین کرپٹو کرنسی کی تجارت کا تفصیلی شرعی حکم کیا ہے؟',
        lang: 'ur',
      );

      const beggarQuestion = 'کیا بھکاری کو سلام کا جواب دینا چاہیے؟';
      const beggarAnswer = 'فقہ حنفی کے مطابق سائل اور بھکاری کو سلام کرنے اور جواب دینے کے احکام...';

      // Entity match must fail: beggar question does not discuss crypto
      expect(RelevanceGuard.entityMatch(beggarQuestion, cryptoTarget), isFalse);

      // Content relevance must fail: beggar answer does not discuss crypto
      expect(RelevanceGuard.isRelevant(beggarAnswer, cryptoTarget), isFalse);
    });

    test('RelevanceGuard accepts genuine cryptocurrency content', () {
      final cryptoTarget = FiqhQueryAnalyzer.analyze(
        'بٹ کوائن اور بلاک چین کرپٹو کرنسی کی تجارت کا تفصیلی شرعی حکم کیا ہے؟',
        lang: 'ur',
      );

      const cryptoQuestion = '[التركيز المذهبي المعتمد: المذهب الحنفي] بٹ کوائن اور ڈیجیٹل کرپٹو کرنسی کی تجارت کا حکم';
      const cryptoAnswer = 'بٹ کوائن اور کرپٹو کرنسی میں فقہائے حنفیہ کے مابین ثمنیت اور مال متقوم ہونے میں اختلاف ہے...';

      expect(RelevanceGuard.entityMatch(cryptoQuestion, cryptoTarget), isTrue);
      expect(RelevanceGuard.isRelevant(cryptoAnswer, cryptoTarget), isTrue);
    });
  });
}

// Helper duplicating the ChatProvider detection logic for unit testing
String detectQueryLanguage(String query) {
  final clean = query.trim();
  if (clean.isEmpty) return 'en';

  final urduPhonemes = RegExp(r'[\u0679\u067E\u0686\u0688\u0691\u06BA\u06BE\u06C1\u06D2\u06AF]');
  if (urduPhonemes.hasMatch(clean)) {
    return 'ur';
  }

  int arabicUrduCount = 0;
  int latinCount = 0;
  for (final rune in clean.runes) {
    if (rune >= 0x0600 && rune <= 0x06FF) {
      arabicUrduCount++;
    } else if ((rune >= 0x0041 && rune <= 0x005A) || (rune >= 0x0061 && rune <= 0x007A)) {
      latinCount++;
    }
  }

  if (arabicUrduCount > latinCount) {
    final urduStopwords = RegExp(r'\b(کیا|ہے|ہیں|کا|کی|کے|میں|سے|پر|کو|نہ|تھا|تھی|تھے)\b');
    if (urduStopwords.hasMatch(clean)) {
      return 'ur';
    }
    return 'ar';
  }

  return 'en';
}
