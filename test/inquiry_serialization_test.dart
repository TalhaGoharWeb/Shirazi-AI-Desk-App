import 'package:flutter_test/flutter_test.dart';
import 'package:shirazi_app/models/inquiry.dart';

void main() {
  group('Inquiry Model Serialization & BYOK', () {
    test('Roundtrip serialization preserves Arabic, Urdu, and BYOK metadata', () {
      final original = Inquiry(
        id: 'inq-test-101',
        questionArabic: 'ما حكم العملات الرقمية المشفرة في فقه المعاملات؟',
        questionEnglish: 'What is the ruling on cryptocurrencies in transactional fiqh?',
        category: '# Fiqh al-Mu\'amalat',
        madhhab: 'Hanafi',
        persona: 'muhaqqiq',
        timestamp: DateTime(2026, 9, 20, 8, 30),
        isPinned: true,
        isVerified: true,
        dossierRef: '#101',
        scriptureArabic: 'وَأَحَلَّ اللَّهُ الْبَيْعَ وَحَرَّمَ الرِّبَا',
        scriptureRef: 'البقرة: ٢٧٥',
        scholarlyAnswerArabic: 'العملات المشفرة تحقق صفة المالية بالعرف الرقمي الخاص.',
        urduAnnotation: 'خلاصۂ فقہی: ڈیجیٹل کرنسی کا لین دین جائز ہے۔',
        isByokFallback: true,
        byokProvider: 'Google Gemini 1.5 Flash (BYOK)',
        principles: const [
          ScholarlyPrinciple(
            titleArabic: 'صفة المالية',
            titleEnglish: 'Maliyyah',
            categoryArabic: 'التمول',
            descriptionArabic: 'ما يميل إليه طبع الإنسان.',
          ),
        ],
        citations: const ['Radd al-Muhtar (Vol 4, p 501)', 'AAOIFI Standard 59'],
        reasoningSteps: const [
          ReasoningStep(
            title: 'Shamela DB Scan',
            detail: 'Retrieved Hanafi texts',
            duration: '0.34s',
            isCompleted: true,
          ),
        ],
      );

      final json = original.toJson();
      final restored = Inquiry.fromJson(json);

      expect(restored.id, equals('inq-test-101'));
      expect(restored.questionArabic, equals('ما حكم العملات الرقمية المشفرة في فقه المعاملات؟'));
      expect(restored.urduAnnotation, equals('خلاصۂ فقہی: ڈیجیٹل کرنسی کا لین دین جائز ہے۔'));
      expect(restored.isByokFallback, isTrue);
      expect(restored.byokProvider, equals('Google Gemini 1.5 Flash (BYOK)'));
      expect(restored.isPinned, isTrue);
      expect(restored.principles.length, equals(1));
      expect(restored.principles.first.titleArabic, equals('صفة المالية'));
      expect(restored.citations.length, equals(2));
      expect(restored.reasoningSteps.length, equals(1));
      expect(restored.reasoningSteps.first.isCompleted, isTrue);
    });
  });
}
