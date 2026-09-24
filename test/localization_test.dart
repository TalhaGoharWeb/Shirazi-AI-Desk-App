import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shirazi_app/core/localization/app_strings.dart';
import 'package:shirazi_app/services/storage_service.dart';
import 'package:shirazi_app/services/api_service.dart';
import 'package:shirazi_app/providers/settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Localization & Language Selection Tests', () {
    late StorageService storageService;
    late SettingsProvider settingsProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storageService = await StorageService.init();
      settingsProvider = SettingsProvider(
        storageService: storageService,
        apiService: ApiService(),
      );
    });

    test('Default language starts as English (en)', () {
      expect(storageService.language, 'en');
      expect(settingsProvider.language, 'en');

      final strings = AppStrings.get(settingsProvider.language);
      expect(strings.isRtl, false);
      expect(strings.direction, TextDirection.ltr);
      expect(strings.navResearch, 'Research');
      expect(strings.navLibrary, 'Library');
      expect(strings.navArchive, 'Archive');
      expect(strings.navSettings, 'Settings');
      expect(strings.brandTitle, 'SHIRAZI JURISPRUDENCE');
    });

    test('Switching to Arabic (ar) updates all strings and direction to RTL', () {
      settingsProvider.setLanguage('ar');

      expect(storageService.language, 'ar');
      expect(settingsProvider.language, 'ar');

      final strings = AppStrings.get('ar');
      expect(strings.isRtl, true);
      expect(strings.direction, TextDirection.rtl);
      expect(strings.navResearch, 'البحث');
      expect(strings.navLibrary, 'المكتبة');
      expect(strings.navArchive, 'الأرشيف');
      expect(strings.navSettings, 'الإعدادات');
      expect(strings.brandTitle, 'فقه الشيرازي');
      expect(strings.tabVerdict, 'الحكم الشرعي');
      expect(strings.tabCitations, 'المصادر المعتمدة');
      expect(strings.bookmarkText, 'حفظ');
      expect(strings.filterAll, 'الكل');
      expect(strings.welcomeTitle, 'الموسوعة الفقهية والتحقيق المعاصر');
      expect(strings.welcomeEnterSanctuary, 'الدخول إلى منصة الشيرازي');
    });

    test('Switching to Urdu (ur) updates all strings and direction to RTL', () {
      settingsProvider.setLanguage('ur');

      expect(storageService.language, 'ur');
      expect(settingsProvider.language, 'ur');

      final strings = AppStrings.get('ur');
      expect(strings.isRtl, true);
      expect(strings.direction, TextDirection.rtl);
      expect(strings.navResearch, 'تحقیق');
      expect(strings.navLibrary, 'کتب خانہ');
      expect(strings.navArchive, 'محفوظات');
      expect(strings.navSettings, 'ترتیبات');
      expect(strings.brandTitle, 'شیرازی ریسرچ ڈیسک');
      expect(strings.tabVerdict, 'شرعی حکم');
      expect(strings.tabCitations, 'معتمد مراجع');
      expect(strings.bookmarkText, 'محفوظ کریں');
      expect(strings.filterAll, 'تمام');
      expect(strings.welcomeTitle, 'جامع فقہی انسائیکلوپیڈیا اور معاصر تحقیق');
      expect(strings.welcomeEnterSanctuary, 'شیرازی فقہی پلیٹ فارم میں داخل ہوں');
    });
  });
}
