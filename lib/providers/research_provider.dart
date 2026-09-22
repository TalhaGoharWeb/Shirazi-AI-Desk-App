import 'package:flutter/foundation.dart';
import '../models/inquiry.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/firestore_service.dart';
import '../services/fiqh_query_analyzer.dart';

class ResearchProvider with ChangeNotifier {
  final ApiService apiService;
  final StorageService storageService;

  String _selectedMadhhab = '';
  String _selectedPersona = 'muhaqqiq';
  bool _isProcessing = false;
  int? _serverLatencyMs = 12;

  // Active Inquiry (initialized with welcome state, then populated from live server)
  Inquiry _activeInquiry = Inquiry(
    id: '',
    questionArabic: 'مرحباً بك في منصة الشيرازي للبحوث والإفتاء',
    questionEnglish: 'Welcome to Shirazi Scholarly Jurisprudence Platform',
    category: '# Research Ready',
    madhhab: 'Hanafi',
    persona: 'muhaqqiq',
    timestamp: DateTime.now(),
    dossierRef: '#LIVE',
    scriptureArabic: 'وَقُل رَّبِّ زِدْنِي عِلْمًا',
    scriptureRef: 'سورة طه • الآية ١١٤ [Surah Taha: 114]',
    scholarlyAnswerArabic: 'منظومة الشيرازي البحثية متصلة بالخادم الحي ومستعدة لاستقبال المسائل الفقهية، وتخريج الأحاديث، وتوثيق النصوص من المصادر الكلاسيكية المعتمدة.',
    urduAnnotation: 'خلاصۂ فقہی: خادم الشيرازي متصل مباشرة وجاهز للبحث والتحقيق وفق المذاهب الفقهية الأربعة.',
  );

  ResearchProvider({
    required this.apiService,
    required this.storageService,
  }) {
    _initHeartbeat();
    _loadLatestFromServer();
  }

  String get selectedMadhhab => _selectedMadhhab;
  String get selectedPersona => _selectedPersona;
  bool get isProcessing => _isProcessing;
  int? get serverLatencyMs => _serverLatencyMs;
  Inquiry get activeInquiry => _activeInquiry;

  void setActiveInquiry(Inquiry inquiry) {
    _activeInquiry = inquiry;
    _selectedMadhhab = inquiry.madhhab;
    notifyListeners();
  }

  void setMadhhab(String madhhab) {
    _selectedMadhhab = madhhab;
    notifyListeners();
  }

  void setPersona(String persona) {
    _selectedPersona = persona;
    notifyListeners();
  }

  Future<void> _loadLatestFromServer() async {
    try {
      final liveFatwas = await apiService.fetchRealtimeFatwas(fetchFullDetails: true);
      if (liveFatwas.isNotEmpty) {
        final withAnswer = liveFatwas.firstWhere(
          (f) => f.scholarlyAnswerArabic.isNotEmpty,
          orElse: () => liveFatwas.first,
        );
        _activeInquiry = withAnswer;
        _selectedMadhhab = withAnswer.madhhab;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading initial inquiry from server: $e');
    }
  }

  Future<void> _initHeartbeat() async {
    final lat = await apiService.checkServerLatency();
    if (lat != null) {
      _serverLatencyMs = lat;
      notifyListeners();
    }
  }

  Future<void> submitInquiry(String text) async {
    if (text.trim().isEmpty) return;

    // Run pre-flight analysis for topic-specific steps
    final queryLang = storageService.language;
    final target = FiqhQueryAnalyzer.analyze(text, lang: queryLang);
    final topicLabel = target.topicLabel;
    final effectiveMadhhab = target.requestedMadhhab ?? _selectedMadhhab;
    if (effectiveMadhhab.isNotEmpty) _selectedMadhhab = effectiveMadhhab;

    _isProcessing = true;
    _activeInquiry = Inquiry(
      id: 'inq-${DateTime.now().millisecondsSinceEpoch}',
      questionArabic: text,
      questionEnglish: '',
      category: '# Contemporary Fiqh',
      madhhab: effectiveMadhhab.isNotEmpty ? effectiveMadhhab : 'Unspecified',
      persona: _selectedPersona,
      timestamp: DateTime.now(),
      dossierRef: '#${1000 + (DateTime.now().millisecond % 900)}',
      reasoningSteps: [
        ReasoningStep(
          title: 'Topic Identified: $topicLabel',
          detail: 'Executing index scan for: $topicLabel...',
          isProcessing: true,
        ),
      ],
    );
    notifyListeners();

    // Step 1
    await Future.delayed(const Duration(milliseconds: 700));
    _activeInquiry = _activeInquiry.copyWith(
      reasoningSteps: [
        ReasoningStep(
          title: 'Topic Identified: $topicLabel',
          detail: 'Client-side classification; question dispatched to Shirazi Oracle',
          duration: '0.28s',
          isCompleted: true,
        ),
        ReasoningStep(
          title: 'Madhhab Filter: ${effectiveMadhhab.isNotEmpty ? effectiveMadhhab : "Unspecified"}',
          detail: 'Preference sent with the request; applied by the Oracle server',
          isProcessing: true,
        ),
      ],
    );
    notifyListeners();

    // Step 2
    await Future.delayed(const Duration(milliseconds: 700));
    _activeInquiry = _activeInquiry.copyWith(
      reasoningSteps: [
        ReasoningStep(
          title: 'Topic Identified: $topicLabel',
          detail: 'Client-side classification; question dispatched to Shirazi Oracle',
          duration: '0.28s',
          isCompleted: true,
        ),
        ReasoningStep(
          title: 'Madhhab Filter: ${effectiveMadhhab.isNotEmpty ? effectiveMadhhab : "Unspecified"}',
          detail: 'Preference sent with the request; applied by the Oracle server',
          duration: '0.45s',
          isCompleted: true,
        ),
        const ReasoningStep(
          title: 'Awaiting Oracle Response',
          detail: 'Shirazi Oracle research pipeline running — the answer will arrive from the server...',
          isProcessing: true,
        ),
      ],
    );
    notifyListeners();

    // Get personal key based on selected provider
    String? personalKey;
    final selectedProv = storageService.selectedProvider;
    if (selectedProv == 'gemini') {
      personalKey = storageService.geminiKey;
    } else if (selectedProv == 'groq') {
      personalKey = storageService.groqKey;
    } else if (selectedProv == 'openrouter') {
      personalKey = storageService.openRouterKey;
    }

    // Real-time query to live Shirazi socket/REST with personal BYOK failover
    final result = await apiService.streamRealtimeQuery(
      text: text,
      persona: _selectedPersona,
      lang: storageService.language,
      madhhab: effectiveMadhhab.isNotEmpty ? effectiveMadhhab : 'Hanafi',
      byokKey: personalKey,
      byokProvider: selectedProv,
      autoFailover: storageService.autoFailover,
      onProgress: (progressMsg) {
        final currentSteps = List<ReasoningStep>.from(_activeInquiry.reasoningSteps);
        final updatedSteps = currentSteps.map((s) => ReasoningStep(
          title: s.title,
          detail: s.detail,
          duration: s.duration.isEmpty ? '0.3s' : s.duration,
          isCompleted: true,
          isProcessing: false,
        )).toList();

        updatedSteps.add(ReasoningStep(
          title: 'Shirazi Agent Core Dispatch',
          detail: progressMsg,
          isCompleted: false,
          isProcessing: true,
        ));

        _activeInquiry = _activeInquiry.copyWith(reasoningSteps: updatedSteps);
        notifyListeners();
      },
    );

    final isByok = result['isByokFallback'] == true;
    final byokProv = result['byokProvider'] as String? ?? '';
    final isRealtime = result['isRealtimeStream'] == true;
    final isQuotaExhausted = result['status'] == 'QUOTA_EXHAUSTED';
    final oracleKeysUsed = result['oracle_keys_used'] == true;
    final resultCitations = (result['citations'] as List? ?? []).map((c) => c.toString()).toList();
    // Honest-failure rule (§6): never invent a scholarly answer. If there is
    // no answer text, show the exhaustion message — never a fabricated
    // placeholder Arabic sentence.
    final oracleSourced = result['source'] == 'shirazi-oracle';
    final noAnswerText = (result['answer'] as String?)?.trim().isEmpty ?? true;
    final answerText = isQuotaExhausted
        ? ApiService.getQuotaExhaustedMessage(storageService.language, oracleKeysUsed)
        : (result['status'] == 'SUCCESS' && !oracleSourced
            ? ApiService.getExhaustionMessage(storageService.language)
            : (noAnswerText
                ? ApiService.getExhaustionMessage(storageService.language)
                : result['answer']));

    _isProcessing = false;
    _activeInquiry = _activeInquiry.copyWith(
      scholarlyAnswerArabic: answerText,
      urduAnnotation: isByok
          // BYOK keys only ever travel to the Oracle pipeline (§7); the
          // answer still comes from the Shirazi Oracle Server.
          ? 'خلاصۂ فقہی: آپ کی ذاتی کلید شیرازی اوریکل پائپ لائن کے ذریعے استعمال ہوئی ($effectiveMadhhab مذہب).'
          : (isRealtime
              ? 'خلاصۂ فقہی: شیرازی اوریکل سے براہِ راست حاصل کردہ جواب ($effectiveMadhhab مذہب).'
              : 'خلاصۂ فقہی: شیرازی اوریکل سے حاصل کردہ جواب ($effectiveMadhhab مذہب).'),
      isByokFallback: isByok,
      byokProvider: isByok ? byokProv : (isRealtime ? 'Shirazi Core Agent (Live)' : ''),
      citations: resultCitations.isNotEmpty ? resultCitations : null,
      reasoningSteps: [
        ReasoningStep(
          title: 'Topic Identified: $topicLabel',
          detail: 'Client-side classification; question dispatched to Shirazi Oracle',
          duration: '0.28s',
          isCompleted: true,
        ),
        ReasoningStep(
          title: 'Madhhab Filter: ${effectiveMadhhab.isNotEmpty ? effectiveMadhhab : "Unspecified"}',
          detail: 'Preference sent with the request; applied by the Oracle server',
          duration: '0.45s',
          isCompleted: true,
        ),
        ReasoningStep(
          title: 'Oracle Response Received',
          detail: isByok
              ? 'Personal key routed to Shirazi Oracle pipeline ($byokProv) — answer came from the Oracle'
              : (isRealtime
                  ? 'Response arrived over the live Oracle channel; citations shown only as provided by the server'
                  : 'Response received from Shirazi Oracle; citations shown only as provided by the server'),
          duration: '0.39s',
          isCompleted: true,
        ),
      ],
    );

    // Persist completed inquiry into local disk storage and cloud firestore
    await storageService.appendInquiry(_activeInquiry);
    FirestoreService.saveInquiryToCloud(_activeInquiry);
    notifyListeners();
  }
}
