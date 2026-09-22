library fiqh_query_analyzer;

/// fiqh_query_analyzer.dart
/// ─────────────────────────────────────────────────────────────────────────────
/// Pure-Dart pre-query analysis pipeline for Shirazi AI.
///
/// Pipeline:
///   User Query
///     → TopicExtractor.classify()      → FiqhTopicCategory
///     → MadhhabDetector.detect()       → String? madhhab
///     → ResearchTarget.build()         → ResearchTarget
///     → RelevanceGuard.isRelevant()    → bool (accepts/rejects retrieved text)
///     → RelevanceGuard.entityMatch()   → bool (server fatwa queue guard)
///
/// This service has ZERO network calls — it is deterministic static logic.
/// It enforces the 16-point strict research & source-grounding protocol.
/// ─────────────────────────────────────────────────────────────────────────────

// ── Topic categories ──────────────────────────────────────────────────────────

enum FiqhTopicCategory {
  cryptocurrency,
  banking,
  insurance,
  stocks,
  trade,
  zakat,
  salat,
  sawm,
  hajj,
  nikah,
  talaq,
  inheritance,
  food,
  taharah,
  jihad,
  siyasah,
  aqidah,
  quranTafsir,
  hadithScience,
  general,
  unknown,
}

// ── ResearchTarget ────────────────────────────────────────────────────────────

/// Structured research target — passed through every layer of the pipeline to
/// constrain retrieval, generation, and relevance checking.
class ResearchTarget {
  final FiqhTopicCategory category;
  final String topicLabel;        // human-readable label used in prompts & UI
  final String? requestedMadhhab; // null = not yet specified by the user
  final String transactionType;   // e.g. 'buying', 'selling', 'trading', 'mining'
  final String requiredLanguage;  // 'ur' | 'ar' | 'en'
  final List<String> keyTerms;    // canonical key terms for relevance enforcement

  const ResearchTarget({
    required this.category,
    required this.topicLabel,
    this.requestedMadhhab,
    this.transactionType = '',
    this.requiredLanguage = 'ur',
    this.keyTerms = const [],
  });

  bool get hasMadhhab =>
      requestedMadhhab != null && requestedMadhhab!.trim().isNotEmpty;

  ResearchTarget copyWith({
    FiqhTopicCategory? category,
    String? topicLabel,
    String? requestedMadhhab,
    String? transactionType,
    String? requiredLanguage,
    List<String>? keyTerms,
  }) {
    return ResearchTarget(
      category: category ?? this.category,
      topicLabel: topicLabel ?? this.topicLabel,
      requestedMadhhab: requestedMadhhab ?? this.requestedMadhhab,
      transactionType: transactionType ?? this.transactionType,
      requiredLanguage: requiredLanguage ?? this.requiredLanguage,
      keyTerms: keyTerms ?? this.keyTerms,
    );
  }
}

// ── FiqhQueryAnalyzer ─────────────────────────────────────────────────────────

/// Main entry point.  Call [analyze] to obtain a [ResearchTarget] from raw text.
class FiqhQueryAnalyzer {
  FiqhQueryAnalyzer._();

  /// Analyzes [query] and returns a fully structured [ResearchTarget].
  static ResearchTarget analyze(String query, {required String lang}) {
    final madhhab = MadhhabDetector.detect(query);
    final category = TopicExtractor.classify(query);
    final topicLabel = TopicExtractor.labelFor(category);
    final transactionType = TopicExtractor.detectTransactionType(query);
    final keyTerms = TopicExtractor.keyTermsFor(category, query);

    return ResearchTarget(
      category: category,
      topicLabel: topicLabel,
      requestedMadhhab: madhhab,
      transactionType: transactionType,
      requiredLanguage: lang,
      keyTerms: keyTerms,
    );
  }

  /// Returns true when the question type requires a madhhab specification.
  static bool requiresMadhhab(FiqhTopicCategory category) {
    const noMadhhabNeeded = {
      FiqhTopicCategory.unknown,
      FiqhTopicCategory.aqidah,
      FiqhTopicCategory.quranTafsir,
      FiqhTopicCategory.hadithScience,
    };
    return !noMadhhabNeeded.contains(category);
  }
}

// ── TopicExtractor ────────────────────────────────────────────────────────────

/// Classifies a user query into a [FiqhTopicCategory] using multilingual
/// keyword matching (Urdu, Arabic, English).
class TopicExtractor {
  TopicExtractor._();

  // ── Keyword tables (Urdu / Arabic / English) ───────────────────────────────

  static const _cryptoTerms = [
    'بٹ کوائن','بٹکوائن','کرپٹو','کرپٹوکرنسی','کرپٹو کرنسی',
    'بلاک چین','بلاکچین','ڈیجیٹل کرنسی','ڈیجیٹل اثاثے',
    'این ایف ٹی','ڈی فائی','اسٹیبل کوائن','ماینگ','اسٹیکنگ',
    'ٹوکن','الٹ کوائن','ایتھیریم','ریپل','لائٹ کوائن',
    'بيتكوين','بتكوين','عملة رقمية','عملات رقمية','العملات المشفرة',
    'بلوكشين','بلوك تشين','الأصول الرقمية','رمز رقمي','عملة مشفرة',
    'تشفير','استخراج العملات','تعدين','الإيثيريوم','رموز',
    'bitcoin','cryptocurrency','crypto','blockchain','nft','defi',
    'stablecoin','mining','staking','token','altcoin','ethereum',
    'digital asset','digital currency',
  ];

  static const _bankingTerms = [
    'سود','بینک','لون','قرض','رہن','بنک',
    'ربا','ربوا','فائدہ','سود خوری',
    'بنك','ربا','فائدة',
    'interest','riba','bank','loan','mortgage','usury',
  ];

  static const _insuranceTerms = [
    'انشورنس','بیمہ','تأمين','تامین','انشورینس',
    'insurance','takaful','تكافل',
  ];

  static const _stocksTerms = [
    'شیئر','حصص','سٹاک','بورس','اسٹاک مارکیٹ',
    'أسهم','بورصة','سوق الأوراق المالية',
    'shares','stocks','stock market','equity','dividend',
  ];

  static const _tradeTerms = [
    'تجارت','خرید','فروخت','بیع','شراء','خریدنا','بیچنا',
    'تجارة','معاملة',
    'trade','buy','sell','transaction','commerce','business',
  ];

  static const _zakatTerms = [
    'زکوٰۃ','زکات','عشر','صدقۃ','صدقہ','فطرانہ',
    'زكاة','زكاة الفطر','عشر',
    'zakat','sadaqah','fitrana',
  ];

  static const _salatTerms = [
    'نماز','صلوٰۃ','صلاۃ','اذان','اقامت','رکعت',
    'صلاة','صلوات','أذان','إقامة','ركعة',
    'prayer','salah','salat','rakat','adhan',
  ];

  static const _nikahTerms = [
    'نکاح','شادی','مہر','حق مہر',
    'نكاح','زواج','مهر',
    'nikah','marriage','mahr',
  ];

  static const _talaqTerms = [
    'طلاق','خلع','عدت','رجعت','بائن','مغلظ',
    'طلاق','خلع','عدة','رجعة','بائن',
    'divorce','talaq','khul','iddah',
  ];

  static const _foodTerms = [
    'کھانا','کھانے','ذبح','گوشت','حلال','حرام',
    'طعام','أكل','ذبح','لحم',
    'food','halal','haram','slaughter','meat',
  ];

  static const _taharahTerms = [
    'وضو','غسل','طہارت','پاکی','ناپاکی','جنابت',
    'وضوء','غسل','طهارة','نجاسة','جنابة',
    'wudu','ghusl','purity','taharah','najasah',
  ];

  static const _aqidahTerms = [
    'عقیدہ','ایمان','توحید','شرک','کفر',
    'عقيدة','إيمان','توحيد','شرك','كفر',
    'aqidah','faith','tawhid','shirk','kufr',
  ];

  // ── Classification ──────────────────────────────────────────────────────────

  static FiqhTopicCategory classify(String query) {
    final q = query.toLowerCase();
    if (_match(q, _cryptoTerms))    return FiqhTopicCategory.cryptocurrency;
    if (_match(q, _bankingTerms))   return FiqhTopicCategory.banking;
    if (_match(q, _insuranceTerms)) return FiqhTopicCategory.insurance;
    if (_match(q, _stocksTerms))    return FiqhTopicCategory.stocks;
    if (_match(q, _nikahTerms))     return FiqhTopicCategory.nikah;
    if (_match(q, _talaqTerms))     return FiqhTopicCategory.talaq;
    if (_match(q, _zakatTerms))     return FiqhTopicCategory.zakat;
    if (_match(q, _salatTerms))     return FiqhTopicCategory.salat;
    if (_match(q, _taharahTerms))   return FiqhTopicCategory.taharah;
    if (_match(q, _aqidahTerms))    return FiqhTopicCategory.aqidah;
    if (_match(q, _foodTerms))      return FiqhTopicCategory.food;
    if (_match(q, _tradeTerms))     return FiqhTopicCategory.trade;
    return FiqhTopicCategory.general;
  }

  static bool _match(String query, List<String> terms) {
    for (final t in terms) {
      if (query.contains(t.toLowerCase())) return true;
    }
    return false;
  }

  static String labelFor(FiqhTopicCategory cat) {
    switch (cat) {
      case FiqhTopicCategory.cryptocurrency:
        return 'Bitcoin / Cryptocurrency / Blockchain Trading';
      case FiqhTopicCategory.banking:
        return 'Banking / Interest / Riba';
      case FiqhTopicCategory.insurance:
        return 'Insurance / Takaful';
      case FiqhTopicCategory.stocks:
        return 'Stock Market / Shares / Equity';
      case FiqhTopicCategory.trade:
        return 'Trade / Commerce / Buying & Selling';
      case FiqhTopicCategory.zakat:
        return 'Zakat / Sadaqah / Charity';
      case FiqhTopicCategory.salat:
        return 'Salat / Prayer';
      case FiqhTopicCategory.sawm:
        return 'Sawm / Fasting / Ramadan';
      case FiqhTopicCategory.hajj:
        return 'Hajj / Umrah / Pilgrimage';
      case FiqhTopicCategory.nikah:
        return 'Nikah / Marriage / Mahr';
      case FiqhTopicCategory.talaq:
        return "Talaq / Divorce / Khul'";
      case FiqhTopicCategory.inheritance:
        return 'Inheritance / Faraid / Wasiyyah';
      case FiqhTopicCategory.food:
        return 'Halal / Haram Food & Slaughter';
      case FiqhTopicCategory.taharah:
        return 'Taharah / Purity / Ghusl';
      case FiqhTopicCategory.jihad:
        return 'Jihad / Qital / Siyar';
      case FiqhTopicCategory.siyasah:
        return "Siyasah Shar'iyyah / Islamic Governance";
      case FiqhTopicCategory.aqidah:
        return 'Aqidah / Creed / Theology';
      case FiqhTopicCategory.quranTafsir:
        return "Qur'an / Tafsir";
      case FiqhTopicCategory.hadithScience:
        return 'Hadith Science / Usul al-Hadith';
      case FiqhTopicCategory.general:
        return 'General Islamic Question';
      case FiqhTopicCategory.unknown:
        return 'Unknown / Unclassified';
    }
  }

  static List<String> keyTermsFor(FiqhTopicCategory cat, String originalQuery) {
    List<String> terms;
    switch (cat) {
      case FiqhTopicCategory.cryptocurrency:
        terms = [
          'بٹ کوائن','بٹکوائن','کرپٹو','بلاک چین',
          'bitcoin','crypto','blockchain','بيتكوين','عملة رقمية','عملات مشفرة',
        ];
      case FiqhTopicCategory.banking:
        terms = ['سود','ربا','بینک','riba','interest','bank'];
      case FiqhTopicCategory.insurance:
        terms = ['انشورنس','بیمہ','تأمين','insurance','takaful'];
      case FiqhTopicCategory.stocks:
        terms = ['شیئر','حصص','سٹاک','shares','stocks','أسهم'];
      case FiqhTopicCategory.zakat:
        terms = ['زکوٰۃ','زکات','زكاة','zakat'];
      case FiqhTopicCategory.salat:
        terms = ['نماز','صلاة','صلوٰۃ','prayer','salat'];
      case FiqhTopicCategory.nikah:
        terms = ['نکاح','نكاح','nikah','marriage'];
      case FiqhTopicCategory.talaq:
        terms = ['طلاق','خلع','talaq','divorce'];
      case FiqhTopicCategory.taharah:
        terms = ['وضو','غسل','طہارت','طهارة','wudu','ghusl'];
      case FiqhTopicCategory.food:
        terms = ['حلال','حرام','ذبح','halal','haram','slaughter'];
      default:
        terms = [];
    }
    // Supplement with distinctive words from the original query
    final queryWords = originalQuery
        .split(RegExp(r'\s+'))
        .where((w) => w.length >= 4)
        .take(8)
        .toList();
    return [...terms, ...queryWords];
  }

  static String detectTransactionType(String query) {
    final q = query.toLowerCase();
    if (q.contains('ماینگ') || q.contains('mining') || q.contains('تعدين')) {
      return 'mining';
    }
    if (q.contains('اسٹیکنگ') || q.contains('staking')) return 'staking';
    if (q.contains('خرید') || q.contains('buy') || q.contains('شراء')) {
      return 'buying';
    }
    if (q.contains('فروخت') || q.contains('sell') || q.contains('بيع')) {
      return 'selling';
    }
    if (q.contains('تجارت') || q.contains('trade') || q.contains('تجارة')) {
      return 'trading';
    }
    if (q.contains('سرمایہ') || q.contains('invest') || q.contains('استثمار')) {
      return 'investment';
    }
    return '';
  }
}

// ── MadhhabDetector ───────────────────────────────────────────────────────────

/// Detects an explicitly mentioned madhhab from user query text.
/// Returns null if none detected — caller must then prompt the user.
class MadhhabDetector {
  MadhhabDetector._();

  static const _hanafiTerms = [
    'حنفی','حنفي','hanafi','ابو حنیفہ','أبو حنيفة','مذہب حنفی','المذهب الحنفي',
  ];
  static const _malikiTerms = [
    'مالکی','مالكي','maliki','مالک','مالك','مذہب مالکی','المذهب المالكي',
  ];
  static const _shafiTerms = [
    'شافعی','شافعي','shafi','shafii','مذہب شافعی','المذهب الشافعي',
  ];
  static const _hanbaliTerms = [
    'حنبلی','حنبلي','hanbali','احمد بن حنبل','أحمد بن حنبل',
    'مذہب حنبلی','المذهب الحنبلي',
  ];
  static const _comparativeTerms = [
    'مقارن','فقه مقارن','مذاہب اربعہ','المذاهب الأربعة','تمام مذاہب','چاروں مذاہب','اربعہ مذاہب','موازنہ','comparative',
  ];

  /// Returns canonical madhhab name or null if not found.
  static String? detect(String query) {
    final q = query.toLowerCase();
    if (_match(q, _comparativeTerms)) return 'Comparative';
    if (_match(q, _hanafiTerms))  return 'Hanafi';
    if (_match(q, _malikiTerms))  return 'Maliki';
    if (_match(q, _shafiTerms))   return "Shafi'i";
    if (_match(q, _hanbaliTerms)) return 'Hanbali';
    return null;
  }

  static bool _match(String query, List<String> terms) {
    for (final t in terms) {
      if (query.contains(t.toLowerCase())) return true;
    }
    return false;
  }

  /// Checks if [itemMadhhab] matches [expectedMadhhab]
  static bool isCompatible(String? itemMadhhab, String expectedMadhhab) {
    if (itemMadhhab == null || itemMadhhab.trim().isEmpty) return true;
    final cleanItem = itemMadhhab.trim().toLowerCase();
    final cleanExp = expectedMadhhab.trim().toLowerCase();
    if (cleanExp == 'comparative' || cleanItem == 'comparative') return true;
    if (cleanItem == cleanExp) return true;
    if (cleanItem.contains('shafi') && cleanExp.contains('shafi')) return true;
    return false;
  }

  /// Returns true if [content] explicitly indicates a different madhhab than [expectedMadhhab].
  ///
  /// For example, if [expectedMadhhab] is 'Hanafi', but [content] explicitly specifies
  /// '[التركيز المذهبي المعتمد: المذهب المالكي]' or focuses exclusively on Maliki
  /// rulings without Hanafi usul/verdict, this returns true.
  static bool isMismatched(String content, String expectedMadhhab) {
    if (content.trim().isEmpty || expectedMadhhab.trim().isEmpty) return false;

    final c = content.toLowerCase();
    final exp = expectedMadhhab.toLowerCase().trim();
    if (exp == 'comparative') return false;

    if (exp == 'hanafi') {
      if (content.contains('المذهب المالكي') && !content.contains('المذهب الحنفي') && !content.contains('حنفي')) return true;
      if (content.contains('المذهب الشافعي') && !content.contains('المذهب الحنفي') && !content.contains('حنفي')) return true;
      if (content.contains('المذهب الحنبلي') && !content.contains('المذهب الحنفي') && !content.contains('حنفي')) return true;
      if (c.contains('maliki') && !c.contains('hanafi')) return true;
    } else if (exp == 'maliki') {
      if (content.contains('المذهب الحنفي') && !content.contains('المذهب المالكي') && !content.contains('مالكي')) return true;
      if (content.contains('المذهب الشافعي') && !content.contains('المذهب المالكي') && !content.contains('مالكي')) return true;
      if (content.contains('المذهب الحنبلي') && !content.contains('المذهب المالكي') && !content.contains('مالكي')) return true;
      if (c.contains('hanafi') && !c.contains('maliki')) return true;
    } else if (exp.contains('shafi')) {
      if (content.contains('المذهب الحنفي') && !content.contains('المذهب الشافعي') && !content.contains('شافعي')) return true;
      if (content.contains('المذهب المالكي') && !content.contains('المذهب الشافعي') && !content.contains('شافعي')) return true;
      if (content.contains('المذهب الحنبلي') && !content.contains('المذهب الشافعي') && !content.contains('شافعي')) return true;
    } else if (exp == 'hanbali') {
      if (content.contains('المذهب الحنفي') && !content.contains('المذهب الحنبلي') && !content.contains('حنبلي')) return true;
      if (content.contains('المذهب المالكي') && !content.contains('المذهب الحنبلي') && !content.contains('حنبلي')) return true;
      if (content.contains('المذهب الشافعي') && !content.contains('المذهب الحنبلي') && !content.contains('حنبلي')) return true;
    }

    return false;
  }

  /// Localized prompt to show the user when no madhhab was detected.
  static String clarificationPrompt(String lang) {
    switch (lang) {
      case 'ur':
        return 'آپ اس مسئلے کا جواب کس فقہی مذہب کے مطابق چاہتے ہیں؟\n\n'
            'براہ کرم ذیل میں سے ایک مذہب منتخب فرمائیں:';
      case 'ar':
        return 'وفقَ أيِّ مذهب فقهي تودُّ الحصولَ على الجواب؟\n\n'
            'يرجى اختيار مذهب من الخيارات أدناه:';
      default:
        return 'Which jurisprudential school (Madhhab) would you like '
            'the answer according to?\n\nPlease select one:';
    }
  }
}

// ── RelevanceGuard ────────────────────────────────────────────────────────────

/// Enforces Rules 1, 4, 13: retrieved content must actually relate to the
/// user's question.
///
/// Hard safety check — if question topic ≠ retrieved evidence topic → REJECT.
class RelevanceGuard {
  RelevanceGuard._();

  /// Returns true only when [retrievedContent] is relevant to [target].
  ///
  /// For crypto topics: requires at least one crypto-specific named entity
  /// in the content, NOT just a generic fiqh word like حکم or حلال.
  static bool isRelevant(String retrievedContent, ResearchTarget target) {
    if (retrievedContent.trim().isEmpty) return false;

    final content = retrievedContent.toLowerCase();

    // Positive match: at least one key term must appear
    bool positiveMatch = false;
    for (final term in target.keyTerms) {
      if (term.length >= 3 && content.contains(term.toLowerCase())) {
        positiveMatch = true;
        break;
      }
    }
    if (!positiveMatch) return false;

    // For high-specificity topics, also require a named-entity match
    if (target.category == FiqhTopicCategory.cryptocurrency) {
      const cryptoMarkers = [
        'بٹ کوائن','بٹکوائن','کرپٹو','بلاک چین',
        'bitcoin','crypto','blockchain','بيتكوين','عملة رقمية',
      ];
      bool hasCryptoMarker = false;
      for (final m in cryptoMarkers) {
        if (content.contains(m.toLowerCase())) {
          hasCryptoMarker = true;
          break;
        }
      }
      if (!hasCryptoMarker) return false;
    }

    return true;
  }

  /// Checks a server fatwa by named-entity matching rather than word overlap.
  ///
  /// Prevents the exact bug: "Bitcoin حکم" matching "beggar حکم" because
  /// they share the word حکم.
  static bool entityMatch(String fatwaQuestion, ResearchTarget target) {
    if (fatwaQuestion.trim().isEmpty) return false;

    final fq = fatwaQuestion.toLowerCase();
    final highValue = _highValueTermsFor(target.category);

    // One high-value named entity is sufficient
    for (final term in highValue) {
      if (fq.contains(term.toLowerCase())) return true;
    }

    // Otherwise require 2+ key-term hits
    int hits = 0;
    for (final term in target.keyTerms) {
      if (term.length >= 4 && fq.contains(term.toLowerCase())) hits++;
    }
    return hits >= 2;
  }

  static List<String> _highValueTermsFor(FiqhTopicCategory cat) {
    switch (cat) {
      case FiqhTopicCategory.cryptocurrency:
        return [
          'بٹ کوائن','بٹکوائن','کرپٹو','بلاک چین',
          'bitcoin','cryptocurrency','blockchain',
          'بيتكوين','عملة رقمية','عملات مشفرة',
        ];
      case FiqhTopicCategory.banking:
        return ['سود','ربا','riba','interest'];
      case FiqhTopicCategory.insurance:
        return ['انشورنس','بیمہ','insurance','takaful','تأمين'];
      case FiqhTopicCategory.stocks:
        return ['شیئر','حصص','سٹاک','shares','أسهم'];
      case FiqhTopicCategory.zakat:
        return ['زکوٰۃ','زکات','زكاة','عشر','صدقہ','fitrana','zakat'];
      case FiqhTopicCategory.salat:
        return ['نماز','صلوٰۃ','صلاۃ','صلاة','اذان','أذان','prayer','salah','salat'];
      case FiqhTopicCategory.taharah:
        return ['وضو','غسل','طہارت','طهارة','wudu','ghusl'];
      case FiqhTopicCategory.nikah:
        return ['نکاح','نكاح','nikah'];
      case FiqhTopicCategory.talaq:
        return ['طلاق','خلع','talaq'];
      case FiqhTopicCategory.food:
        return ['کھانا','طعام','ذبح','لحم','meat','food'];
      case FiqhTopicCategory.trade:
        return ['تجارت','بیع','شراء','تجارة','trade'];
      default:
        return [];
    }
  }

  /// Honest "source not found" notice — never fabricates a citation.
  /// Implements Rules 3 and 14.
  static String sourceNotFoundNotice({
    required String lang,
    required String topicLabel,
    required String? madhhab,
  }) {
    final school = madhhab ?? '';
    switch (lang) {
      case 'ur':
        return '### مصادر نہیں ملے\n\n'
            'دستیاب شیرازی/شمیلہ مصادر میں **$topicLabel** کے بارے میں '
            '${school.isNotEmpty ? "($school مذہب کے مطابق) " : ""}'
            'قابلِ اعتماد اور متعلقہ نص تلاش نہیں ہو سکی۔\n\n'
            '> مجھے دستیاب مصادر میں اس دعوے کے لیے قابلِ اعتماد متعلقہ نص نہیں ملی، '
            'اس لیے میں اسے حتمی نسبت کے ساتھ پیش نہیں کر رہا۔\n\n'
            'آپ اپنا سوال دوبارہ مخصوص الفاظ کے ساتھ کر سکتے ہیں، '
            'یا ترتیبات میں اپنی ذاتی API Key شامل کر کے براہِ راست استفسار کر سکتے ہیں۔';
      case 'ar':
        return '### المصادر غير متوفرة\n\n'
            'لم يُعثر في المصادر المتاحة (شيرازي/شاملة) على نص موثوق ومتعلق '
            'بموضوع **$topicLabel** '
            '${school.isNotEmpty ? "وفق المذهب $school" : ""}.\n\n'
            '> لم تتوفر في المصادر المتاحة نصوص ذات صلة بهذا الموضوع، '
            'لذا لا يمكنني تقديمه بنسبة قاطعة.\n\n'
            'يمكنك إعادة صياغة سؤالك بكلمات أكثر تحديداً، '
            'أو إضافة مفتاح API شخصي في الإعدادات للاستفسار المباشر.';
      default:
        return '### Sources Not Found\n\n'
            'No reliable and relevant text was found in the available '
            'Shirazi/Shamela corpus for: **$topicLabel** '
            '${school.isNotEmpty ? "(according to the $school school)" : ""}.\n\n'
            '> No reliable passage was found for this claim in the available sources. '
            'It is therefore not being presented with definitive attribution.\n\n'
            'You may rephrase your question with more specific terms, '
            'or configure a personal API key in Settings to query directly.';
    }
  }
}
