import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../theme/shirazi_colors.dart';
import '../theme/shirazi_typography.dart';

class AppStrings {
  final String lang;

  const AppStrings(this.lang);

  static AppStrings of(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    return AppStrings(settings.language);
  }

  static AppStrings get(String lang) => AppStrings(lang);

  bool get isRtl => lang == 'ar' || lang == 'ur';
  TextDirection get direction => isRtl ? TextDirection.rtl : TextDirection.ltr;

  // --- Bottom Navigation ---
  String get navResearch {
    switch (lang) {
      case 'ar': return 'البحث';
      case 'ur': return 'تحقیق';
      default: return 'Research';
    }
  }

  String get navLibrary {
    switch (lang) {
      case 'ar': return 'المكتبة';
      case 'ur': return 'کتب خانہ';
      default: return 'Library';
    }
  }

  String get navArchive {
    switch (lang) {
      case 'ar': return 'الأرشيف';
      case 'ur': return 'محفوظات';
      default: return 'Archive';
    }
  }

  String get navSettings {
    switch (lang) {
      case 'ar': return 'الإعدادات';
      case 'ur': return 'ترتیبات';
      default: return 'Settings';
    }
  }

  // --- App Bar ---
  String get brandTitle {
    switch (lang) {
      case 'ar': return 'فقه الشيرازي';
      case 'ur': return 'شیرازی ریسرچ ڈیسک';
      default: return 'SHIRAZI JURISPRUDENCE';
    }
  }

  // --- Research Desk & Query Console ---
  String get queryConsolePlaceholder {
    switch (lang) {
      case 'ar': return 'اطرح مسألة فقهية أو نازلة معاصرة للتحقيق والتوثيق...';
      case 'ur': return 'تحقیق و توثیق کے لیے کوئی فقہی یا معاصر مسئلہ درج کریں...';
      default: return 'Submit juristic query, contemporary dilemma, or Hadith verification...';
    }
  }

  String get synthesizeVerdict {
    switch (lang) {
      case 'ar': return 'استنباط الحكم الفقهي';
      case 'ur': return 'شرعی حکم اخذ کریں';
      default: return 'Synthesize Verdict';
    }
  }

  String get synthesizing {
    switch (lang) {
      case 'ar': return 'جارٍ الاستنباط والتحقيق...';
      case 'ur': return 'تحقیق و استنباط جاری ہے...';
      default: return 'Synthesizing Verdict...';
    }
  }

  String get activeModelLabel {
    switch (lang) {
      case 'ar': return 'النموذج النشط';
      case 'ur': return 'فعال ماڈل';
      default: return 'Active Engine';
    }
  }

  // --- Personas ---
  String get personaJurist {
    switch (lang) {
      case 'ar': return 'الفقيه المحقق';
      case 'ur': return 'فقیہ محقق';
      default: return 'Jurist (Faqih)';
    }
  }

  String get personaMufti {
    switch (lang) {
      case 'ar': return 'المفتي المعاصر';
      case 'ur': return 'مفتی معاصر';
      default: return 'Mufti';
    }
  }

  String get personaResearcher {
    switch (lang) {
      case 'ar': return 'الباحث الأكاديمي';
      case 'ur': return 'علمی محقق';
      default: return 'Academic Researcher';
    }
  }

  String get personaStudent {
    switch (lang) {
      case 'ar': return 'طالب العلم';
      case 'ur': return 'طالب علم';
      default: return 'Student of Knowledge';
    }
  }

  // --- Madhhabs ---
  String get madhhabHanafi {
    switch (lang) {
      case 'ar': return 'المذهب الحنفي';
      case 'ur': return 'فقہ حنفی';
      default: return 'Hanafi School';
    }
  }

  String get madhhabMaliki {
    switch (lang) {
      case 'ar': return 'المذهب المالكي';
      case 'ur': return 'فقہ مالکی';
      default: return 'Maliki School';
    }
  }

  String get madhhabShafii {
    switch (lang) {
      case 'ar': return 'المذهب الشافعي';
      case 'ur': return 'فقہ شافعی';
      default: return 'Shafi\'i School';
    }
  }

  String get madhhabHanbali {
    switch (lang) {
      case 'ar': return 'المذهب الحنبلي';
      case 'ur': return 'فقہ حنبلی';
      default: return 'Hanbali School';
    }
  }

  // --- Reasoning Stepper Stages ---
  String get stageCorpus {
    switch (lang) {
      case 'ar': return 'استرجاع النصوص والمراجع';
      case 'ur': return 'متون و مراجع کی تلاش';
      default: return 'Corpus Retrieval';
    }
  }

  String get stageIsnad {
    switch (lang) {
      case 'ar': return 'تحقيق الأسانيد وتخريج الأحاديث';
      case 'ur': return 'تحقیق اسناد و تخریج';
      default: return 'Isnad Verification';
    }
  }

  String get stageDeduction {
    switch (lang) {
      case 'ar': return 'التخريج الفقهي وتطبيق القواعد';
      case 'ur': return 'تخریج فقہی و اطلاقِ قواعد';
      default: return 'Juridical Deduction';
    }
  }

  String get stageSynthesis {
    switch (lang) {
      case 'ar': return 'اكتمال استنباط الحكم والفتوى';
      case 'ur': return 'فتویٰ و استنباط مکمل';
      default: return 'Synthesis Complete';
    }
  }

  // --- Scholarly Answer Card ---
  String get tabVerdict {
    switch (lang) {
      case 'ar': return 'الحكم الشرعي';
      case 'ur': return 'شرعی حکم';
      default: return 'Verdict';
    }
  }

  String get tabEvidence {
    switch (lang) {
      case 'ar': return 'مصفوفة الأدلة';
      case 'ur': return 'دلائل و اصول';
      default: return 'Evidence Matrix';
    }
  }

  String get tabCitations {
    switch (lang) {
      case 'ar': return 'المصادر المعتمدة';
      case 'ur': return 'معتمد مراجع';
      default: return 'Citations';
    }
  }

  String get tabReviewerNotes {
    switch (lang) {
      case 'ar': return 'ملاحظات المراجعة';
      case 'ur': return 'ریویو نوٹس';
      default: return 'Reviewer Notes';
    }
  }

  String get copyText {
    switch (lang) {
      case 'ar': return 'نسخ';
      case 'ur': return 'کاپی';
      default: return 'Copy';
    }
  }

  String get shareText {
    switch (lang) {
      case 'ar': return 'مشاركة';
      case 'ur': return 'شیئر';
      default: return 'Share';
    }
  }

  String get bookmarkText {
    switch (lang) {
      case 'ar': return 'حفظ';
      case 'ur': return 'محفوظ کریں';
      default: return 'Bookmark';
    }
  }

  String get copiedToClipboard {
    switch (lang) {
      case 'ar': return 'تم نسخ النص إلى الحافظة بنجاح';
      case 'ur': return 'متن کلپ بورڈ پر کاپی ہو گیا';
      default: return 'Copied to clipboard';
    }
  }

  // --- Research Archive ---
  String get archiveTitle {
    switch (lang) {
      case 'ar': return 'أرشيف الأبحاث الفقهية';
      case 'ur': return 'تحقیقی محفوظات';
      default: return 'Research Archive';
    }
  }

  String get archiveSearchPlaceholder {
    switch (lang) {
      case 'ar': return 'ابحث في الفتاوى، المسائل، أو أرقام المراجع...';
      case 'ur': return 'فتاویٰ، مسائل یا حوالہ نمبر میں تلاش کریں...';
      default: return 'Search fatwas, citations, or references...';
    }
  }

  String get filterAll {
    switch (lang) {
      case 'ar': return 'الكل';
      case 'ur': return 'تمام';
      default: return 'All';
    }
  }

  String get filterFiqh {
    switch (lang) {
      case 'ar': return 'فقه';
      case 'ur': return 'فقہ';
      default: return 'Fiqh';
    }
  }

  String get filterHadith {
    switch (lang) {
      case 'ar': return 'حديث';
      case 'ur': return 'حدیث';
      default: return 'Hadith';
    }
  }

  String get filterVerified {
    switch (lang) {
      case 'ar': return 'معتمد';
      case 'ur': return 'تصدیق شدہ';
      default: return 'Verified';
    }
  }

  String get filterBookmarked {
    switch (lang) {
      case 'ar': return 'المحفوظات';
      case 'ur': return 'محفوظ شدہ';
      default: return 'Bookmarked';
    }
  }

  String get noDossiersFound {
    switch (lang) {
      case 'ar': return 'لم يتم العثور على أبحاث مطابقة';
      case 'ur': return 'کوئی مماثل ریکارڈ نہیں ملا';
      default: return 'No research dossiers found';
    }
  }

  // --- Settings Screen ---
  String get languageSectionTitle {
    switch (lang) {
      case 'ar': return 'لغة العرض والاستفسار';
      case 'ur': return 'نمائش اور سوال کی زبان';
      default: return 'Display & Inquiry Language';
    }
  }

  String get languageSubtitle {
    switch (lang) {
      case 'ar': return 'يحدد لغة واجهة التطبيق وصياغة الأحكام المستنبطة';
      case 'ur': return 'ایپ انٹرفیس اور مستنبط احکام کی زبان کا تعین کرتا ہے';
      default: return 'Sets app UI language and AI juristic response language';
    }
  }

  String get languageEnglish => 'English';
  String get languageArabic => 'العربية';
  String get languageUrdu => 'اردو';

  String get settingsTitle {
    switch (lang) {
      case 'ar': return 'الإعدادات والمفاتيح';
      case 'ur': return 'ترتیبات و اے آئی کیز';
      default: return 'Settings & BYOK Routing';
    }
  }

  String get offlineCacheTitle {
    switch (lang) {
      case 'ar': return 'التخزين المؤقت المحلي (آفلاين)';
      case 'ur': return 'مقامی آف لائن کیش';
      default: return 'Local Offline Cache';
    }
  }

  String get autoFailoverTitle {
    switch (lang) {
      case 'ar': return 'التحويل التلقائي عند انقطاع الخدمة';
      case 'ur': return 'خودکار فال بیک متبادل';
      default: return 'Automatic Failover Routing';
    }
  }

  String get scholarProfile {
    switch (lang) {
      case 'ar': return 'الملف العلمي';
      case 'ur': return 'علمی پروفائل';
      default: return 'Scholar Profile';
    }
  }

  String get guestScholarNode {
    switch (lang) {
      case 'ar': return 'عقدة علمية غير مسجلة (زائر)';
      case 'ur': return 'غیر رجسٹرڈ علمی نوڈ (مہمان)';
      default: return 'Guest Scholarly Node';
    }
  }

  String get signInBtn {
    switch (lang) {
      case 'ar': return 'تسجيل الدخول';
      case 'ur': return 'لاگ ان کریں';
      default: return 'Sign In';
    }
  }

  String get registerBtn {
    switch (lang) {
      case 'ar': return 'تسجيل حساب جديد';
      case 'ur': return 'نیا اکاؤنٹ بنائیں';
      default: return 'Register Profile';
    }
  }

  String get signOutBtn {
    switch (lang) {
      case 'ar': return 'تسجيل الخروج';
      case 'ur': return 'لاگ آؤٹ';
      default: return 'Sign Out';
    }
  }

  // --- Library Screen ---
  String get libraryTitle {
    switch (lang) {
      case 'ar': return 'المكتبة الشاملة الرقمية';
      case 'ur': return 'مکتبہ شاملہ ڈیجیٹل کتب خانہ';
      default: return 'Maktaba Shamela Digital Archive';
    }
  }

  String get librarySubtitle {
    switch (lang) {
      case 'ar': return 'المكتبة الشاملة • ٨,٥٩٥ مجلداً تراثياً مفهرساً';
      case 'ur': return 'مکتبہ شاملہ • 8,595 تراثی مجلدات';
      default: return 'Maktaba Shamela • 8,595 Indexed Classical Volumes';
    }
  }

  String get libraryDescription {
    switch (lang) {
      case 'ar': return 'فهرسة دقيقة لـ 7.6 مليون صفحة بزمن استجابة فائق السرعة.\nالبحث النشط متصل بالخادم السحابي.';
      case 'ur': return '7.6 ملین صفحات پر محیط تیز ترین تلاش۔\nکلاؤڈ سرور سے فعال رابطہ۔';
      default: return 'Sub-15ms Lucene full-text indexed across 7.6M pages.\nQuerying active on Cloud Server Port 8020.';
    }
  }

  // --- Dynamic Typography Helpers ---
  TextStyle headlineStyle({
    double fontSize = 20.0,
    FontWeight fontWeight = FontWeight.bold,
    Color? color,
    double? height,
  }) =>
      ShiraziTypography.dynamicHeadline(
        lang,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? ShiraziColors.onSurface,
        height: height,
      );

  TextStyle bodyStyle({
    double fontSize = 14.0,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
    double? height,
  }) =>
      ShiraziTypography.dynamicBody(
        lang,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? ShiraziColors.onSurfaceVariant,
        height: height,
      );

  TextStyle labelStyle({
    double fontSize = 12.0,
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
    double? letterSpacing,
  }) =>
      ShiraziTypography.dynamicLabel(
        lang,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? ShiraziColors.onSurface,
        letterSpacing: letterSpacing,
      );

  // --- Welcome Screen Strings ---
  String get welcomeStepHeader {
    switch (lang) {
      case 'ar': return 'الخطوة ٢ من ٢ • ميثاق المنصة العلمية';
      case 'ur': return 'مرحلہ ۲ از ۲ • علمی پلیٹ فارم ضوابط';
      default: return 'STEP 2 OF 2 • RESEARCH PLATFORM PROTOCOL';
    }
  }

  String get welcomeSkip {
    switch (lang) {
      case 'ar': return 'تخطي';
      case 'ur': return 'چھوڑیں';
      default: return 'Skip';
    }
  }

  String get welcomeTitle {
    switch (lang) {
      case 'ar': return 'الموسوعة الفقهية والتحقيق المعاصر';
      case 'ur': return 'جامع فقہی انسائیکلوپیڈیا اور معاصر تحقیق';
      default: return 'Comprehensive Jurisprudence & Contemporary Research';
    }
  }

  String get welcomeSubtitle {
    switch (lang) {
      case 'ar': return 'مدونة الشيرازي للذكاء الاصطناعي • رقمنة الفقه الإسلامي';
      case 'ur': return 'شیرازی اے آئی کوڈیکس • ڈیجیٹل اسلامی فقہ';
      default: return 'SHIRAZI AI CODEX • DIGITIZED JURISPRUDENCE';
    }
  }

  String get welcomeMottoQuote {
    switch (lang) {
      case 'ar': return '«مَنْ يُرِدِ اللَّهُ بِهِ خَيْرًا يُفَقِّهْهُ فِي الدِّينِ»';
      case 'ur': return '”جس کے لیے اللہ بھلائی چاہتا ہے، اسے دین میں فقہ (گہری سمجھ) عطا کرتا ہے۔“';
      default: return '"Whoever Allah wants good for, He grants him Fiqh (deep understanding) of the religion."';
    }
  }

  String get welcomeMottoSub {
    switch (lang) {
      case 'ar': return 'ذخائر التراث المعتمدة • تخريج النوازل المعاصرة الموثقة';
      case 'ur': return 'معتمد کلاسیکی متون • تصدیق شدہ معاصر فتاویٰ و تخریج';
      default: return 'Authenticated Classical Corpus • Verified Contemporary Deductions';
    }
  }

  String get welcomeLangTitle {
    switch (lang) {
      case 'ar': return 'اختر لغة البحث والعرض المفضلة';
      case 'ur': return 'اپنی پسندیدہ زبان منتخب کریں';
      default: return 'SELECT YOUR PREFERRED LANGUAGE';
    }
  }

  String get welcomeLangSub {
    switch (lang) {
      case 'ar': return 'حدد لغة واجهة التطبيق وصياغة الأحكام والتحقيقات الفقهية.';
      case 'ur': return 'ایپ کے انٹرفیس اور فقہی احکام کے لیے اپنی پسندیدہ زبان منتخب کریں۔';
      default: return 'Choose your language for the application interface and scholarly AI rulings.';
    }
  }

  // Pillar 1: Shamela
  String get welcomePillar1Title {
    switch (lang) {
      case 'ar': return 'المكتبة الشاملة والذخائر الفقهية';
      case 'ur': return 'مکتبہ شاملہ اور کلاسیکی کتب کا ذخیرہ';
      default: return 'Maktaba Shamela & Classical Corpus';
    }
  }

  String get welcomePillar1Badge {
    switch (lang) {
      case 'ar': return '٨,٥٠٠+ مجلد';
      case 'ur': return '8,500+ متون';
      default: return '8.5K+ TEXTS';
    }
  }

  String get welcomePillar1Desc {
    switch (lang) {
      case 'ar': return 'بحث دلالي فوري في أكثر من ٨,٥٠٠ مصنف تراثي وشروح أمهات الكتب في المذاهب الحنفية، المالكية، الشافعية، والحنابلة.';
      case 'ur': return 'حنفی، مالکی، شافعی اور حنبلی فقہ کے 8,500 سے زائد کلاسیکی متون اور معتمد شروحات میں فوری معنوی تلاش۔';
      default: return 'Instant semantic search across 8,500+ classical treatises and primary commentaries across the Hanafi, Maliki, Shafi\'i, and Hanbali schools of thought.';
    }
  }

  List<String> get welcomePillar1Chips {
    switch (lang) {
      case 'ar': return const ['الحنفية', 'المالكية', 'الشافعية', 'الحنابلة'];
      case 'ur': return const ['فقہ حنفی', 'فقہ مالکی', 'فقہ شافعی', 'فقہ حنبلی'];
      default: return const ['Hanafi', 'Maliki', 'Shafi\'i', 'Hanbali'];
    }
  }

  // Pillar 2: Isnad
  String get welcomePillar2Title {
    switch (lang) {
      case 'ar': return 'تخريج الأحاديث وتحقيق الأسانيد';
      case 'ur': return 'تخریجِ احادیث و تحقیقِ اسناد';
      default: return 'Isnad Lineage & Hadith Takhrij';
    }
  }

  String get welcomePillar2Badge {
    switch (lang) {
      case 'ar': return 'تحقيق معتمد';
      case 'ur': return 'معتمد اسناد';
      default: return 'AUTHENTIC ISNAD';
    }
  }

  String get welcomePillar2Desc {
    switch (lang) {
      case 'ar': return 'تحقق آلي لشبكات الرواة، أحكام الجرح والتعديل، وربط الطرق بأصول المساند والسنن والصحاح المعتمدة.';
      case 'ur': return 'راویوں کے باہمی شجرے کی جانچ، جرح و تعدیل کے ائمہ کے احکام، اور صحاح و مسانید سے براہِ راست تقابل۔';
      default: return 'Automated narrator graph verification, Jarh wa Ta\'dil scholar ratings, and cross-referenced pathways tracing directly to primary Musnads and Sahih collections.';
    }
  }

  List<String> get welcomePillar2Chips {
    switch (lang) {
      case 'ar': return const ['١٨٠,٠٠٠+ ترجمة راوٍ', 'طبقات الرواة'];
      case 'ur': return const ['180,000+ تراجمِ رجال', 'طبقاتِ روات'];
      default: return const ['180,000+ Narrator Biographies', 'Tabaqat Chronology'];
    }
  }

  // Pillar 3: BYOK
  String get welcomePillar3Title {
    switch (lang) {
      case 'ar': return 'الخزينة العلمية المشفرة والمفاتيح الخاصة';
      case 'ur': return 'محفوظ ذاتی علمی والٹ اور اے آئی کیز';
      default: return 'Private Scholarly Vault & BYOK';
    }
  }

  String get welcomePillar3Badge {
    switch (lang) {
      case 'ar': return 'تشفير AES-256';
      case 'ur': return 'AES-256 محفوظ';
      default: return 'AES-256';
    }
  }

  String get welcomePillar3Desc {
    switch (lang) {
      case 'ar': return 'خزينة محلية مشفرة بلا معرفة مسبقة لمسودات الفتاوى، مع دعم مباشر لمفاتيح الذكاء الاصطناعي الخاصة (Gemini, Groq, OpenRouter) لضمان استقلالية البحث.';
      case 'ur': return 'غیر مطبوعہ مسودات فتاویٰ کے لیے مکمل انکرپٹڈ لوکل والٹ، اور آزادانہ تحقیق کے لیے ذاتی ماڈل کیز کی مکمل سپورٹ۔';
      default: return 'Zero-knowledge cryptographic local vault for unpublished fatwa drafts, with direct support for personal LLM keys (Gemini, Groq, OpenRouter) for sovereign research.';
    }
  }

  List<String> get welcomePillar3Chips {
    switch (lang) {
      case 'ar': return const ['قاعدة متجهات محلية', 'توجيه النماذج الخاصة'];
      case 'ur': return const ['مقامی ویکٹر اسٹور', 'ذاتی ماڈل روٹنگ'];
      default: return const ['Local Vector Store', 'BYOK Model Routing'];
    }
  }

  // Manifesto
  String get welcomeManifestoTitle {
    switch (lang) {
      case 'ar': return 'دليل المنهجية الفقهية للذكاء الاصطناعي';
      case 'ur': return 'فقہی تحقیق و اے آئی کا منہجی ميثاق';
      default: return 'Scholarly AI Research Methodology';
    }
  }

  String get welcomeTenet1Title {
    switch (lang) {
      case 'ar': return '١. التوثيق المصدري الصارم:';
      case 'ur': return '۱. کتبِ معتمدہ سے سخت توثیق:';
      default: return '1. Strict Primary Source Authentication:';
    }
  }

  String get welcomeTenet1Body {
    switch (lang) {
      case 'ar': return 'عدم نسبة أي قول أو مسألة إلا بالرجوع لكتب المذهب المعتمدة والمخطوطات الموثقة.';
      case 'ur': return 'کسی بھی قول یا مسئلے کی نسبت اصل کتب اور معتمد مراجع کی تصدیق کے بغیر نہیں کی جاتی۔';
      default: return 'No ruling or attribution is synthesized without verification against verified primary classical texts and authoritative manuscripts.';
    }
  }

  String get welcomeTenet2Title {
    switch (lang) {
      case 'ar': return '٢. الالتزام بأصول المذاهب:';
      case 'ur': return '۲. اصولِ فقہ کی پاسداری:';
      default: return '2. Adherence to Foundational Principles:';
    }
  }

  String get welcomeTenet2Body {
    switch (lang) {
      case 'ar': return 'اتباع قواعد الاستنباط وضوابط التخريج المقررة عند أئمة الفقه وأصوله.';
      case 'ur': return 'ہر مسئلہ ائمہ فقہ کے وضع کردہ اصولِ استنباط اور قواعدِ تخریج کے مطابق طے کیا جاتا ہے۔';
      default: return 'Juridical deductions conform strictly to formal legal canons (Usul al-Fiqh) and authentic precedent established by the recognized schools.';
    }
  }

  String get welcomeTenet3Title {
    switch (lang) {
      case 'ar': return '٣. فحص مدارات الإسناد:';
      case 'ur': return '۳. اسناد اور علل کی جانچ:';
      default: return '3. Isnad & Transmission Verification:';
    }
  }

  String get welcomeTenet3Body {
    switch (lang) {
      case 'ar': return 'تحقيق الأحاديث النبوية سنداً ومتناً وبيان علل الروايات بحياد علمي رصين.';
      case 'ur': return 'احادیثِ مبارکہ کی اسنادی حیثیت اور متون کی علل کا دقیق علمی و روایتی جائزہ۔';
      default: return 'Rigorous critical analysis of prophetic traditions across biographical narrator evaluations and textual integrity.';
    }
  }

  String get welcomeTenet4Title {
    switch (lang) {
      case 'ar': return '٤. خصوصية التحقيقات العلمية:';
      case 'ur': return '۴. علمی ابحاث کی خود مختار رازداری:';
      default: return '4. Sovereign Research Privacy:';
    }
  }

  String get welcomeTenet4Body {
    switch (lang) {
      case 'ar': return 'تشفير كامل للأبحاث والنوازل الخاصة على جهاز الباحث دون أي مشاركة خارجية.';
      case 'ur': return 'حساس فقہی مسائل اور غیر مطبوعہ فتاویٰ کے لیے صارف کی ڈیوائس پر مکمل انکرپشن۔';
      default: return 'Zero-knowledge client-side encryption for sensitive juristic inquiries and unpublished draft fatwas.';
    }
  }

  String get welcomeEnterSanctuary {
    switch (lang) {
      case 'ar': return 'الدخول إلى منصة الشيرازي';
      case 'ur': return 'شیرازی فقہی پلیٹ فارم میں داخل ہوں';
      default: return 'ENTER SHIRAZI SANCTUARY';
    }
  }

  String get welcomeAlreadyRegistered {
    switch (lang) {
      case 'ar': return 'لديك حساب بالفعل؟ ';
      case 'ur': return 'کیا آپ کا اکاؤنٹ پہلے سے موجود ہے؟ ';
      default: return 'Already registered? ';
    }
  }

  String get welcomeSignIn {
    switch (lang) {
      case 'ar': return 'تسجيل الدخول';
      case 'ur': return 'لاگ ان کریں';
      default: return 'Sign In';
    }
  }

  String get welcomeBadge1 {
    switch (lang) {
      case 'ar': return 'تشفير طرفي شامل';
      case 'ur': return 'مکمل محفوظ انکرپشن';
      default: return 'End-to-End Encrypted';
    }
  }

  String get welcomeBadge2 {
    switch (lang) {
      case 'ar': return 'تحقيق إسنادي معتمد';
      case 'ur': return 'تصدیق شدہ اسناد';
      default: return 'Verified Isnad';
    }
  }

  String get welcomeBadge3 {
    switch (lang) {
      case 'ar': return 'انعدام تام للتعقب';
      case 'ur': return 'صفر ٹریکنگ';
      default: return 'Zero Telemetry';
    }
  }

  String get welcomeFooter {
    switch (lang) {
      case 'ar': return 'مدونة الشيرازي v2.4 • ذكاء اصطناعي متخصص في الفقه والتحقيق الإسلامي';
      case 'ur': return 'شیرازی کوڈیکس ورژن 2.4 • اسلامی فقہ و تحقیق کا علمی مصنوعی ذہانت نظام';
      default: return 'Shirazi Codex v2.4 • Scholarly Artificial Intelligence for Islamic Jurisprudence';
    }
  }

  // --- Modern AI Chat Interface Strings ---
  String get newChat {
    switch (lang) {
      case 'ar': return 'محادثة جديدة';
      case 'ur': return 'نئی تحقیق';
      default: return 'New Inquiry';
    }
  }

  String get todayGroup {
    switch (lang) {
      case 'ar': return 'اليوم';
      case 'ur': return 'آج';
      default: return 'Today';
    }
  }

  String get yesterdayGroup {
    switch (lang) {
      case 'ar': return 'أمس';
      case 'ur': return 'گزشتہ کل';
      default: return 'Yesterday';
    }
  }

  String get previous7DaysGroup {
    switch (lang) {
      case 'ar': return 'آخر ٧ أيام';
      case 'ur': return 'پچھلے 7 دن';
      default: return 'Previous 7 Days';
    }
  }

  String get olderGroup {
    switch (lang) {
      case 'ar': return 'أقدم';
      case 'ur': return 'پرانے سیشنز';
      default: return 'Older';
    }
  }

  String get searchConversations {
    switch (lang) {
      case 'ar': return 'بحث في سجل المسائل...';
      case 'ur': return 'تحقیقات تلاش کریں...';
      default: return 'Search inquiries...';
    }
  }

  String get noConversations {
    switch (lang) {
      case 'ar': return 'لا توجد استفسارات سابقة. ابدأ مسألة جديدة.';
      case 'ur': return 'ابھی تک کوئی تحقیق درج نہیں۔ نئی تحقیق شروع کریں۔';
      default: return 'No research conversations yet. Start a new inquiry.';
    }
  }

  String get askShiraziPlaceholder {
    switch (lang) {
      case 'ar': return 'استفسر من الشيرازي عن النوازل والمسائل الفقهية وتخريج الأحاديث...';
      case 'ur': return 'شیرازی سے فقہی مسائل، احادیث اور معاصر نوازل سے متعلق استفسار کریں...';
      default: return 'Ask Shirazi regarding Islamic Jurisprudence, Hadith, or contemporary ethics...';
    }
  }

  String get reasoningPipelineTitle {
    switch (lang) {
      case 'ar': return 'مسار الاستنباط والتحقيق الفقهي';
      case 'ur': return 'فقہی استنباط اور تحقیق کا مرحلہ وار عمل';
      default: return 'Scholarly Reasoning Pipeline';
    }
  }

  String get citationsTitle {
    switch (lang) {
      case 'ar': return 'المصادر والمراجع المعتمدة';
      case 'ur': return 'بنیادی مآخذ اور کتب فقہ';
      default: return 'Primary Sources & References';
    }
  }

  String get copyAction {
    switch (lang) {
      case 'ar': return 'نسخ النص';
      case 'ur': return 'کاپی کریں';
      default: return 'Copy Text';
    }
  }

  String get copiedNotification {
    switch (lang) {
      case 'ar': return 'تم نسخ النص إلى الحافظة';
      case 'ur': return 'متن کلپ بورڈ پر کاپی ہو گیا';
      default: return 'Text copied to clipboard';
    }
  }

  String get shareAction {
    switch (lang) {
      case 'ar': return 'مشاركة المسألة';
      case 'ur': return 'شیئر کریں';
      default: return 'Share Inquiry';
    }
  }

  String get saveToArchiveSuccess {
    switch (lang) {
      case 'ar': return 'تم حفظ المسألة في الأرشيف البحثي الخاص بك';
      case 'ur': return 'یہ مسئلہ آپ کے ذاتی ریسرچ آرکائیو میں محفوظ ہو گیا';
      default: return 'Inquiry saved to your private research archive';
    }
  }

  String get listenAction {
    switch (lang) {
      case 'ar': return 'استماع للفتوى';
      case 'ur': return 'آواز سنیں';
      default: return 'Listen to Ruling';
    }
  }

  String get stopGenerating {
    switch (lang) {
      case 'ar': return 'إيقاف التحقيق';
      case 'ur': return 'روک دیں';
      default: return 'Stop Generating';
    }
  }

  // --- Prompt Starters ---
  String get promptStarter1Title {
    switch (lang) {
      case 'ar': return 'العملات الرقمية المشفرة';
      case 'ur': return 'ڈیجیٹل اور کرپٹو کرنسی';
      default: return 'Cryptocurrency & DeFi';
    }
  }

  String get promptStarter1Desc {
    switch (lang) {
      case 'ar': return 'ما هو الحكم الشرعي المفصل في تداول العملات المشفرة والبيتكوين؟';
      case 'ur': return 'بٹ کوائن اور بلاک چین کرپٹو کرنسی کی تجارت کا تفصیلی شرعی حکم کیا ہے؟';
      default: return 'What is the Shariah ruling on trading cryptocurrencies like Bitcoin?';
    }
  }

  String get promptStarter2Title {
    switch (lang) {
      case 'ar': return 'زكاة الأسهم والمحافظ الاستثمارية';
      case 'ur': return 'اسٹاک مارکیٹ اور حصص کی زکوٰۃ';
      default: return 'Equity & Stock Zakat';
    }
  }

  String get promptStarter2Desc {
    switch (lang) {
      case 'ar': return 'كيف تُحسب زكاة الأسهم في المحافظ الاستثمارية طويلة الأجل؟';
      case 'ur': return 'طویل مدتی انویسٹمنٹ اور حصص پر زکوٰۃ کا مستند طریقہ کار کیا ہے؟';
      default: return 'How is Zakat calculated on long-term investment equity portfolios?';
    }
  }

  String get promptStarter3Title {
    switch (lang) {
      case 'ar': return 'التبرع بالأعضاء بعد الوفاة';
      case 'ur': return 'اعضاء کا عطیہ اور طبی اخلاقیات';
      default: return 'Organ Donation & Bioethics';
    }
  }

  String get promptStarter3Desc {
    switch (lang) {
      case 'ar': return 'تحرير الأقوال الفقهية المعاصرة في حكم التبرع بالأعضاء بعد الموت الدماغي';
      case 'ur': return 'طبی موت کے بعد انسانی اعضاء عطیہ کرنے کے متعلق معاصر فقہاء کے اقوال';
      default: return 'Comparative juristic positions on organ donation after clinical death';
    }
  }

  String get promptStarter4Title {
    switch (lang) {
      case 'ar': return 'تخريج إسناد الحديث ونقد الرواة';
      case 'ur': return 'تخریج و تصدیقِ اسناد';
      default: return 'Hadith Isnad Verification';
    }
  }

  String get promptStarter4Desc {
    switch (lang) {
      case 'ar': return 'تخريج وبيان درجة حديث "لا ضرر ولا ضرار" مع نقد رواته';
      case 'ur': return 'حدیث "لا ضرر ولا ضرار" کی تخریج اور اسناد کی صحت کا جائزہ';
      default: return 'Evaluate the transmission chain and narrator reliability of Hadith on no harm';
    }
  }

  // --- Admin Dashboard & Privacy ---
  String get adminDashboardTitle {
    switch (lang) {
      case 'ar': return 'لوحة الرقابة والبحوث للمشرف العلمي';
      case 'ur': return 'مرکزی ایڈمن ریسرچ مانیٹرنگ ڈیش بورڈ';
      default: return 'Admin Research Oversight Dashboard';
    }
  }

  String get adminAccessRestricted {
    switch (lang) {
      case 'ar': return 'الوصول مقصور على المشرفين المعتمدين فقط';
      case 'ur': return 'یہ حصہ صرف تصدیق شدہ منتظمین اور نگرانوں کے لیے ہے';
      default: return 'Access restricted to authorized administrators';
    }
  }

  String get privacyShieldBadge {
    switch (lang) {
      case 'ar': return 'عزل تام للمحادثات مشفّر عبر Firebase Security Rules';
      case 'ur': return 'مکمل انفرادی راز داری اور سیکیورٹی قوانین سے محفوظ';
      default: return 'Strict Per-User Privacy Enforced by Firestore Rules';
    }
  }

  // --- Profile screen ---
  String get scholarProfileTitle {
    switch (lang) {
      case 'ar': return 'الملف العلمي';
      case 'ur': return 'علمی پروفائل';
      default: return 'Scholar Profile';
    }
  }
  String get editProfileAction {
    switch (lang) {
      case 'ar': return 'تعديل الملف';
      case 'ur': return 'پروفائل میں ترمیم';
      default: return 'Edit profile';
    }
  }
  String get guestScholar {
    switch (lang) {
      case 'ar': return 'باحث ضيف';
      case 'ur': return 'مہمان محقق';
      default: return 'Guest Scholar';
    }
  }
  String get guestMode {
    switch (lang) {
      case 'ar': return 'وضع الضيف';
      case 'ur': return 'مہمان موڈ';
      default: return 'Guest Mode';
    }
  }
  String get guestContinueHint {
    switch (lang) {
      case 'ar': return 'أنت تتابع كضيف — سجّل الدخول لحفظ ملفك العلمي ومزامنته';
      case 'ur': return 'آپ مہمان کے طور پر جاری ہیں — پروفائل محفوظ کرنے کے لیے سائن ان کریں';
      default: return 'You are continuing as a guest — sign in to save and sync your profile';
    }
  }
  String get signInAction {
    switch (lang) {
      case 'ar': return 'تسجيل الدخول';
      case 'ur': return 'سائن ان';
      default: return 'Sign In';
    }
  }
  String get accountSectionTitle {
    switch (lang) {
      case 'ar': return 'الحساب';
      case 'ur': return 'اکاؤنٹ';
      default: return 'Account';
    }
  }
  String get nameFieldLabel {
    switch (lang) {
      case 'ar': return 'الاسم';
      case 'ur': return 'نام';
      default: return 'Name';
    }
  }
  String get fullNameFieldLabel {
    switch (lang) {
      case 'ar': return 'الاسم الكامل';
      case 'ur': return 'پورا نام';
      default: return 'Full Name';
    }
  }
  String get emailFieldLabel {
    switch (lang) {
      case 'ar': return 'البريد';
      case 'ur': return 'ای میل';
      default: return 'Email';
    }
  }
  String get roleFieldLabel {
    switch (lang) {
      case 'ar': return 'الدور';
      case 'ur': return 'کردار';
      default: return 'Role';
    }
  }
  String get scholarshipSectionTitle {
    switch (lang) {
      case 'ar': return 'التخصص العلمي';
      case 'ur': return 'علمی تخصص';
      default: return 'Scholarship';
    }
  }
  String get madhhabFieldLabel {
    switch (lang) {
      case 'ar': return 'المذهب الفقهي';
      case 'ur': return 'فقہی مسلک';
      default: return 'Jurisprudential School';
    }
  }
  String get scholarlyRankFieldLabel {
    switch (lang) {
      case 'ar': return 'الرتبة العلمية';
      case 'ur': return 'علمی رتبہ';
      default: return 'Scholarly Rank';
    }
  }
  String get researchActivityTitle {
    switch (lang) {
      case 'ar': return 'النشاط البحثي';
      case 'ur': return 'تحقیقی سرگرمی';
      default: return 'Research Activity';
    }
  }
  String get conversationsStatLabel {
    switch (lang) {
      case 'ar': return 'المحادثات';
      case 'ur': return 'گفتگوئیں';
      default: return 'Conversations';
    }
  }
  String get personalKeysStatLabel {
    switch (lang) {
      case 'ar': return 'مفاتيح شخصية';
      case 'ur': return 'ذاتی کیز';
      default: return 'Personal Keys';
    }
  }
  String get languageStatLabel {
    switch (lang) {
      case 'ar': return 'اللغة';
      case 'ur': return 'زبان';
      default: return 'Language';
    }
  }
  String get manageApiKeysAction {
    switch (lang) {
      case 'ar': return 'إدارة مفاتيح API';
      case 'ur': return 'API کیز کا انتظام';
      default: return 'Manage API Keys';
    }
  }
  String get moreSectionTitle {
    switch (lang) {
      case 'ar': return 'المزيد';
      case 'ur': return 'مزید';
      default: return 'More';
    }
  }
  String get adminOversightLabel {
    switch (lang) {
      case 'ar': return 'لوحة الإشراف البحثي';
      case 'ur': return 'ایڈمن تحقیقی نگرانی';
      default: return 'Admin Research Oversight';
    }
  }
  String get manifestoOverviewLabel {
    switch (lang) {
      case 'ar': return 'البيان العلمي ونظرة على النظام';
      case 'ur': return 'علمی منشور و نظام کا تعارف';
      default: return 'Scholarly Manifesto & Overview';
    }
  }
  String get signedOutSuccess {
    switch (lang) {
      case 'ar': return 'تم تسجيل الخروج بنجاح';
      case 'ur': return 'کامیابی سے سائن آؤٹ ہو گئے';
      default: return 'Signed out successfully';
    }
  }
  String get signOutAction {
    switch (lang) {
      case 'ar': return 'تسجيل الخروج';
      case 'ur': return 'سائن آؤٹ';
      default: return 'Sign Out';
    }
  }
  String get cancelAction {
    switch (lang) {
      case 'ar': return 'إلغاء';
      case 'ur': return 'منسوخ';
      default: return 'Cancel';
    }
  }
  String get saveChangesAction {
    switch (lang) {
      case 'ar': return 'حفظ التغييرات';
      case 'ur': return 'تبدیلیاں محفوظ کریں';
      default: return 'Save Changes';
    }
  }
  String get profileSavedSuccess {
    switch (lang) {
      case 'ar': return 'تم حفظ الملف العلمي بنجاح';
      case 'ur': return 'پروفائل کامیابی سے محفوظ ہو گیا';
      default: return 'Profile saved successfully';
    }
  }
  String get genericErrorLabel {
    switch (lang) {
      case 'ar': return 'خطأ';
      case 'ur': return 'خرابی';
      default: return 'Error';
    }
  }
  String get apiKeySavedLocal {
    switch (lang) {
      case 'ar': return 'تم حفظ مفتاح API في التخزين الآمن للجهاز';
      case 'ur': return 'API کلید ڈیوائس کے محفوظ اسٹوریج میں محفوظ ہو گئی';
      default: return 'API key saved to secure device storage';
    }
  }
  String get apiKeySavedCloud {
    switch (lang) {
      case 'ar': return 'تم حفظ مفتاح API ونسخه احتياطيًا في مخزنك السحابي الخاص';
      case 'ur': return 'API کلید محفوظ ہو گئی اور آپ کے نجی کلاؤڈ والٹ میں بیک اپ بھی ہو گیا';
      default: return 'API key saved and backed up to your private cloud vault';
    }
  }
  String get apiKeySavedLocalOnly {
    switch (lang) {
      case 'ar': return 'تم الحفظ على هذا الجهاز — تعذر النسخ الاحتياطي السحابي';
      case 'ur': return 'اس ڈیوائس پر محفوظ ہو گئی — کلاؤڈ بیک اپ دستیاب نہیں';
      default: return 'Saved on this device — cloud backup unavailable';
    }
  }
  String get saveFailedLabel {
    switch (lang) {
      case 'ar': return 'فشل الحفظ';
      case 'ur': return 'محفوظ کرنے میں ناکامی';
      default: return 'Save failed';
    }
  }
  String apiKeyRemoved(String provider) {
    switch (lang) {
      case 'ar': return 'تمت إزالة مفتاح $provider بأمان';
      case 'ur': return '$provider کی کلید محفوظ طریقے سے ہٹا دی گئی';
      default: return '$provider key removed securely';
    }
  }
  String get enterNamePrompt {
    switch (lang) {
      case 'ar': return 'يرجى إدخال الاسم';
      case 'ur': return 'براہ کرم اپنا نام درج کریں';
      default: return 'Please enter your name';
    }
  }
  String get guestRoleLabel {
    switch (lang) {
      case 'ar': return 'ضيف';
      case 'ur': return 'مہمان';
      default: return 'Guest';
    }
  }

  // --- Chat composer ---
  String get attachTooltip {
    switch (lang) {
      case 'ar': return 'إرفاق مستند';
      case 'ur': return 'دستاویز منسلک کریں';
      default: return 'Attach document';
    }
  }
  String get voiceTooltip {
    switch (lang) {
      case 'ar': return 'إدخال صوتي';
      case 'ur': return 'صوتی ان پٹ';
      default: return 'Voice input';
    }
  }
  String get sendTooltip {
    switch (lang) {
      case 'ar': return 'إرسال';
      case 'ur': return 'بھیجیں';
      default: return 'Send';
    }
  }
  String get stopTooltip {
    switch (lang) {
      case 'ar': return 'إيقاف التوليد';
      case 'ur': return 'تولید روکیں';
      default: return 'Stop generating';
    }
  }
  String get attachComingSoon {
    switch (lang) {
      case 'ar': return 'إرفاق المستندات قادم قريباً';
      case 'ur': return 'دستاویز منسلک کرنا جلد آ رہا ہے';
      default: return 'Document attachment coming soon';
    }
  }
  String get voiceComingSoon {
    switch (lang) {
      case 'ar': return 'الإدخال الصوتي قادم قريباً';
      case 'ur': return 'صوتی ان پٹ جلد آ رہا ہے';
      default: return 'Voice input coming soon';
    }
  }
  String get jurisprudentialSchoolTitle {
    switch (lang) {
      case 'ar': return 'المذهب الفقهي';
      case 'ur': return 'فقہی مسلک';
      default: return 'Jurisprudential School';
    }
  }
  String get scholarPersonaTitle {
    switch (lang) {
      case 'ar': return 'الشخصية العلمية';
      case 'ur': return 'علمی شخصیت';
      default: return 'Scholar Persona';
    }
  }
  String get answerModeTitle {
    switch (lang) {
      case 'ar': return 'نمط الإجابة';
      case 'ur': return 'جواب کا انداز';
      default: return 'Answer Mode';
    }
  }
  String get modeAuto {
    switch (lang) {
      case 'ar': return 'تلقائي';
      case 'ur': return 'خودکار';
      default: return 'Auto';
    }
  }
  String get modeQuick {
    switch (lang) {
      case 'ar': return 'سريع';
      case 'ur': return 'فوری';
      default: return 'Quick';
    }
  }
  String get modeDeep {
    switch (lang) {
      case 'ar': return 'بحث عميق';
      case 'ur': return 'گہری تحقیق';
      default: return 'Deep';
    }
  }

  // --- Chat screen / bubbles ---
  String get onlineStatus {
    switch (lang) {
      case 'ar': return 'متصل';
      case 'ur': return 'آن لائن';
      default: return 'Online';
    }
  }
  String get connectingStatus {
    switch (lang) {
      case 'ar': return 'جارٍ الاتصال…';
      case 'ur': return 'رابط ہو رہا ہے…';
      default: return 'Connecting…';
    }
  }
  String get thinkingStatus {
    switch (lang) {
      case 'ar': return 'شيرازي يفكر…';
      case 'ur': return 'شیرازی سوچ رہا ہے…';
      default: return 'Shirazi is thinking…';
    }
  }
  String get retryAction {
    switch (lang) {
      case 'ar': return 'إعادة المحاولة';
      case 'ur': return 'دوبارہ کوشش';
      default: return 'Retry';
    }
  }
  String get personalKeyLabel {
    switch (lang) {
      case 'ar': return 'مفتاح شخصي';
      case 'ur': return 'ذاتی کی';
      default: return 'Personal API Key';
    }
  }
  String get gatewayLimitLabel {
    switch (lang) {
      case 'ar': return 'حد البوابة';
      case 'ur': return 'گیٹ وے حد';
      default: return 'Gateway Limit';
    }
  }
  String get cloudInferenceLabel {
    switch (lang) {
      case 'ar': return 'استدلال سحابي';
      case 'ur': return 'کلاؤڈ انفرنس';
      default: return 'Cloud Inference';
    }
  }
  String get fallbackDiagnosticsTitle {
    switch (lang) {
      case 'ar': return 'مسار استدعاء الخوادم';
      case 'ur': return 'فال بیک انجن کی تشخیص';
      default: return 'Fallback Engine Diagnostics';
    }
  }
  String sourceLabel(int n) {
    switch (lang) {
      case 'ar': return 'المصدر $n';
      case 'ur': return 'ماخذ $n';
      default: return 'Source $n';
    }
  }

  // --- Welcome screen ---
  String get welcomeHeadline {
    switch (lang) {
      case 'ar': return 'السلام عليكم';
      case 'ur': return 'السلام علیکم';
      default: return 'As-salamu alaikum';
    }
  }
  String get welcomeSubheadline {
    switch (lang) {
      case 'ar': return 'مساعدك البحثي الإسلامي — إجابات مؤصلة بالأدلة من مكتبة شاملة';
      case 'ur': return 'آپ کا اسلامی تحقیقی معاون — شاملہ لائبریری سے دلائل کے ساتھ مستند جوابات';
      default: return 'Your Islamic research companion — evidence-grounded answers from the Shamela library';
    }
  }
  String get chipPrayerTimes {
    switch (lang) {
      case 'ar': return 'أوقات الصلاة';
      case 'ur': return 'نماز کے اوقات';
      default: return 'Prayer times';
    }
  }
  String get chipFasting {
    switch (lang) {
      case 'ar': return 'الصيام';
      case 'ur': return 'روزہ';
      default: return 'Fasting';
    }
  }
  String get chipZakat {
    switch (lang) {
      case 'ar': return 'الزكاة';
      case 'ur': return 'زکوٰۃ';
      default: return 'Zakat';
    }
  }
  String get chipHadithCheck {
    switch (lang) {
      case 'ar': return 'تخريج الحديث';
      case 'ur': return 'حدیث کی تحقیق';
      default: return 'Hadith check';
    }
  }
  String get promptPrayerTimes {
    switch (lang) {
      case 'ar': return 'ما هي أوقات الصلوات الخمس وكيف تُحسب؟';
      case 'ur': return 'پانچوں نمازوں کے اوقات کیا ہیں اور ان کا حساب کیسے لگایا جاتا ہے؟';
      default: return 'What are the five daily prayer times and how are they calculated?';
    }
  }
  String get promptFasting {
    switch (lang) {
      case 'ar': return 'اشرح فرائض الصيام وسننه';
      case 'ur': return 'روزے کے فرائض اور سنتوں کی وضاحت کریں';
      default: return 'Explain the obligations and sunnahs of fasting';
    }
  }
  String get promptZakat {
    switch (lang) {
      case 'ar': return 'ما هو نصاب الزكاة وكيف تُحسب على المدخرات؟';
      case 'ur': return 'زکوٰۃ کا نصاب کیا ہے اور بچت پر اس کا حساب کیسے لگائیں؟';
      default: return 'What is the nisab of zakat and how is it calculated on savings?';
    }
  }
  String get promptHadith {
    switch (lang) {
      case 'ar': return 'تحقق من صحة حديث: «لا ضرر ولا ضرار»';
      case 'ur': return 'حدیث "لا ضرر ولا ضرار" کی صحت کی تحقیق کریں';
      default: return 'Verify the authenticity of the hadith "la darar wa la dirar"';
    }
  }
  String get personaMuhaqqiqDesc {
    switch (lang) {
      case 'ar': return 'محقق — باحث أكاديمي';
      case 'ur': return 'محقق — علمی محقق';
      default: return 'Muhaqqiq — Academic Investigator';
    }
  }
  String get personaMuftiDesc {
    switch (lang) {
      case 'ar': return 'مفتٍ — أحكام فقهية واضحة';
      case 'ur': return 'مفتی — واضح فقہی احکام';
      default: return 'Mufti — Clear Jurisprudential Rulings';
    }
  }
  String get personaTalibDesc {
    switch (lang) {
      case 'ar': return 'طالب العلم — تأسيس تعليمي';
      case 'ur': return 'طالب علم — تعلیمی بنیادیں';
      default: return 'Talib al-Ilm — Educational Foundations';
    }
  }
  String get modeAutoDesc {
    switch (lang) {
      case 'ar': return 'تلقائي (حسب السؤال)';
      case 'ur': return 'خودکار (سوال کے مطابق)';
      default: return 'Auto (decides per question)';
    }
  }
  String get modeQuickDesc {
    switch (lang) {
      case 'ar': return 'سريع (إجابة سريعة مع مصادر)';
      case 'ur': return 'فوری (تیز جواب، حوالوں کے ساتھ)';
      default: return 'Quick (fast answer with sources)';
    }
  }
  String get modeDeepDesc {
    switch (lang) {
      case 'ar': return 'بحث عميق (تحقيق شامل)';
      case 'ur': return 'گہری تحقیق (مکمل تحقیقی عمل)';
      default: return 'Deep (full research pipeline)';
    }
  }
  String get exploreTopicsLabel {
    switch (lang) {
      case 'ar': return 'استكشف موضوعاً';
      case 'ur': return 'موضوع دریافت کریں';
      default: return 'Explore a topic';
    }
  }
}

