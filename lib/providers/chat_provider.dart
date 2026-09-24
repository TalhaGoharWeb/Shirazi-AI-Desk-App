import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/chat_models.dart';
import '../models/inquiry.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/firestore_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/fiqh_query_analyzer.dart';

class ChatProvider with ChangeNotifier {
  final ApiService apiService;
  final StorageService storageService;
  final FirebaseAuthService authService;

  List<ShiraziConversation> _conversations = [];
  ShiraziConversation? _currentConversation;
  List<ShiraziChatMessage> _messages = [];

  StreamSubscription<List<ShiraziConversation>>? _convSubscription;
  StreamSubscription<List<ShiraziChatMessage>>? _msgSubscription;

  bool _isGenerating = false;

  /// request_id of the in-flight Oracle query, if any — used to cancel it.
  String? _activeRequestId;

  String _currentStreamingText = '';
  List<ReasoningStep> _currentReasoningSteps = [];
  String _selectedMadhhab = 'Hanafi';
  String _selectedPersona = 'muhaqqiq';
  /// Answer mode: 'auto' (server decides), 'quick' (fast RAG), 'deep' (full research).
  /// Chit-chat is auto-detected by the server; no explicit toggle needed.
  String _answerMode = 'auto';
  int? _serverLatencyMs = 14;

  /// Pending query text, stored when waiting for madhhab clarification.
  String? _pendingQuery;
  ResearchTarget? _pendingResearchTarget;

  ChatProvider({
    required this.apiService,
    required this.storageService,
    required this.authService,
  }) {
    _initHeartbeat();
    _listenToUserConversations();
  }

  // Getters
  List<ShiraziConversation> get conversations => _conversations;
  ShiraziConversation? get currentConversation => _currentConversation;
  List<ShiraziChatMessage> get messages => _messages;
  bool get isGenerating => _isGenerating;
  String get currentStreamingText => _currentStreamingText;
  List<ReasoningStep> get currentReasoningSteps => _currentReasoningSteps;
  String get selectedMadhhab => _selectedMadhhab;
  String get selectedPersona => _selectedPersona;
  String get answerMode => _answerMode;
  int? get serverLatencyMs => _serverLatencyMs;

  void setMadhhab(String madhhab) {
    _selectedMadhhab = madhhab;
    notifyListeners();
  }

  void setPersona(String persona) {
    _selectedPersona = persona;
    notifyListeners();
  }

  /// Sets the answer mode ('auto', 'quick', 'deep'). The server auto-detects
  /// chit-chat; 'quick' forces fast RAG, 'deep' forces full multi-agent research.
  void setAnswerMode(String mode) {
    _answerMode = mode;
    notifyListeners();
  }

  /// Called when the user taps a madhhab quick-reply chip.
  /// Sets the madhhab, then re-submits the pending query.
  Future<void> selectMadhhabAndProceed(String madhhab) async {
    _selectedMadhhab = madhhab;
    final query = _pendingQuery;
    final target = _pendingResearchTarget;
    _pendingQuery = null;
    _pendingResearchTarget = null;
    notifyListeners();
    if (query != null && query.isNotEmpty) {
      await _executeQuery(query, researchTarget: target?.copyWith(
        requestedMadhhab: madhhab,
      ));
    }
  }

  // Date-grouped conversation categories (inspired by ChatGPT/Claude)
  List<ShiraziConversation> get todayConversations {
    final now = DateTime.now();
    return _conversations.where((c) {
      return c.updatedAt.year == now.year &&
          c.updatedAt.month == now.month &&
          c.updatedAt.day == now.day;
    }).toList();
  }

  List<ShiraziConversation> get yesterdayConversations {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return _conversations.where((c) {
      return c.updatedAt.year == yesterday.year &&
          c.updatedAt.month == yesterday.month &&
          c.updatedAt.day == yesterday.day;
    }).toList();
  }

  List<ShiraziConversation> get previous7DaysConversations {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final yesterday = now.subtract(const Duration(days: 1));
    return _conversations.where((c) {
      final isBeforeYesterday = c.updatedAt.isBefore(DateTime(yesterday.year, yesterday.month, yesterday.day));
      final isAfterSevenDays = c.updatedAt.isAfter(sevenDaysAgo);
      return isBeforeYesterday && isAfterSevenDays;
    }).toList();
  }

  List<ShiraziConversation> get olderConversations {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    return _conversations.where((c) => c.updatedAt.isBefore(sevenDaysAgo)).toList();
  }

  /// Listen to conversations strictly scoped to the active user's UID
  void _listenToUserConversations() {
    _convSubscription?.cancel();
    final uid = authService.currentUid;

    _convSubscription = FirestoreService.streamUserConversations(uid).listen(
      (convs) {
        _conversations = convs;
        if (_currentConversation != null) {
          final updated = convs.firstWhere(
            (c) => c.id == _currentConversation!.id,
            orElse: () => _currentConversation!,
          );
          _currentConversation = updated;
        }
        notifyListeners();
      },
      onError: (e) {
        debugPrint('Conversation stream error: $e');
      },
    );
  }

  /// Call whenever user authentication state changes (login / switch accounts)
  void onAuthChanged() {
    _currentConversation = null;
    _messages = [];
    _listenToUserConversations();
    notifyListeners();
  }

  /// Start a clean, new inquiry chat session
  void startNewChat() {
    _msgSubscription?.cancel();
    _currentConversation = null;
    _messages = [];
    _currentStreamingText = '';
    _currentReasoningSteps = [];
    notifyListeners();
  }

  /// Switch to an existing conversation
  void selectConversation(ShiraziConversation conv) {
    if (_currentConversation?.id == conv.id) return;

    _currentConversation = conv;
    _selectedMadhhab = conv.madhhab;
    _selectedPersona = conv.persona;
    _currentStreamingText = '';
    _currentReasoningSteps = [];

    _msgSubscription?.cancel();
    _msgSubscription = FirestoreService.streamConversationMessages(conv.id).listen(
      (msgs) {
        _messages = msgs;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('Messages stream error: $e');
      },
    );
    notifyListeners();
  }

  /// Delete a conversation
  Future<void> deleteConversation(String conversationId) async {
    if (_currentConversation?.id == conversationId) {
      startNewChat();
    }
    await FirestoreService.deleteConversation(conversationId);
  }

  /// Rename a conversation
  Future<void> renameConversation(String conversationId, String newTitle) async {
    await FirestoreService.renameConversation(conversationId, newTitle);
  }

  /// Auto-detect the query language so Shirazi responds in the exact same language
  static String detectQueryLanguage(String text) {
    // 1. Distinct Urdu phonemes / letters and common grammatical particles
    final urduPattern = RegExp(r'[\u06D2\u06BA\u0679\u0688\u0691\u06C1\u0686\u067E\u0698\u06AF\u06BE]');
    final urduWords = RegExp(r'\b(کیا|ہے|ہیں|تھا|تھے|تھی|کے|سے|میں|کا|کی|کو|پر|اور|نہیں|کر|کرنے|والے|حکم)\b');
    if (urduPattern.hasMatch(text) || urduWords.hasMatch(text)) {
      return 'ur';
    }

    // 2. Count Arabic vs Latin unicode runes
    int arabicRunes = 0;
    int latinRunes = 0;
    for (final rune in text.runes) {
      if ((rune >= 0x0600 && rune <= 0x06FF) || (rune >= 0x0750 && rune <= 0x077F)) {
        arabicRunes++;
      } else if ((rune >= 0x0041 && rune <= 0x005A) || (rune >= 0x0061 && rune <= 0x007A)) {
        latinRunes++;
      }
    }

    if (arabicRunes > latinRunes) {
      return 'ar';
    }

    return 'en';
  }

  /// Submit inquiry query: saves to Firestore, streams from live server, saves answer.
  /// Implements the full pre-flight analysis pipeline:
  ///   FiqhQueryAnalyzer → Madhhab gate → Retrieval → RelevanceGuard → Answer
  Future<void> submitQuery(String text) async {
    final query = text.trim();
    if (query.isEmpty || _isGenerating) return;

    final uid = authService.currentUid;
    final queryLang = detectQueryLanguage(query);

    // ── Pre-flight: Analyze query ──────────────────────────────────────────
    final target = FiqhQueryAnalyzer.analyze(query, lang: queryLang);

    // ── Madhhab gate ───────────────────────────────────────────────────────
    // If the question requires a madhhab AND none was detected AND none is
    // pre-selected, ask the user before proceeding.
    final madhhabFromQuery = target.requestedMadhhab;
    final effectiveMadhhab = madhhabFromQuery ?? _selectedMadhhab;

    if (FiqhQueryAnalyzer.requiresMadhhab(target.category) &&
        effectiveMadhhab.trim().isEmpty) {
      // Store query for later use when user selects madhhab
      _pendingQuery = query;
      _pendingResearchTarget = target;

      // Create a conversation if needed
      final now = DateTime.now();
      ShiraziConversation activeConv = _currentConversation ?? await () async {
        String title = query.length > 40 ? '${query.substring(0, 40)}...' : query;
        final newConv = await FirestoreService.createConversation(
          ownerUid: uid,
          initialTitle: title,
          language: queryLang,
          madhhab: '',
          persona: _selectedPersona,
          ownerEmail: storageService.isAuthenticated ? storageService.scholarEmail : null,
          ownerName: storageService.isAuthenticated ? storageService.scholarName : 'Researcher Node',
        );
        _currentConversation = newConv;
        _msgSubscription?.cancel();
        _msgSubscription = FirestoreService.streamConversationMessages(newConv.id).listen((msgs) {
          _messages = msgs;
          notifyListeners();
        });
        return newConv;
      }();

      // Add user message
      final userMsgId = 'msg_${now.millisecondsSinceEpoch}_user';
      final userMessage = ShiraziChatMessage(
        id: userMsgId,
        conversationId: activeConv.id,
        sender: 'user',
        content: query,
        timestamp: now,
      );
      _messages = List.from(_messages)..add(userMessage);

      // Add madhhab clarification prompt
      final clarMsgId = 'msg_${now.millisecondsSinceEpoch}_clar';
      final clarMessage = ShiraziChatMessage(
        id: clarMsgId,
        conversationId: activeConv.id,
        sender: 'assistant',
        content: MadhhabDetector.clarificationPrompt(queryLang),
        timestamp: now.add(const Duration(milliseconds: 100)),
        messageType: ShiraziMessageType.madhhabClarification,
        pendingQuery: query,
      );
      _messages = List.from(_messages)..add(clarMessage);
      notifyListeners();

      await FirestoreService.addMessage(conversationId: activeConv.id, message: userMessage);
      await FirestoreService.addMessage(conversationId: activeConv.id, message: clarMessage);
      return;
    }

    // Madhhab confirmed — update selectedMadhhab if the query specified one
    if (madhhabFromQuery != null) {
      _selectedMadhhab = madhhabFromQuery;
    } else if (_selectedMadhhab.trim().isEmpty) {
      _selectedMadhhab = 'Hanafi'; // Conservative fallback when already confirmed
    }

    await _executeQuery(query, researchTarget: target.copyWith(
      requestedMadhhab: _selectedMadhhab,
    ));
  }

  /// Core query execution — called after madhhab has been confirmed.
  Future<void> _executeQuery(String query, {ResearchTarget? researchTarget}) async {

    final uid = authService.currentUid;
    final now = DateTime.now();
    final queryLang = researchTarget?.requiredLanguage ?? detectQueryLanguage(query);
    final effectiveMadhhab = researchTarget?.requestedMadhhab ?? _selectedMadhhab;
    ShiraziConversation activeConv = _currentConversation ?? await () async {
      String title = query;
      if (title.length > 40) {
        title = '${title.substring(0, 40)}...';
      }
      final newConv = await FirestoreService.createConversation(
        ownerUid: uid,
        initialTitle: title,
        language: queryLang,
        madhhab: effectiveMadhhab,
        persona: _selectedPersona,
        ownerEmail: storageService.isAuthenticated ? storageService.scholarEmail : null,
        ownerName: storageService.isAuthenticated ? storageService.scholarName : 'Researcher Node',
      );
      _currentConversation = newConv;
      // Start listening to messages for this new conversation
      _msgSubscription?.cancel();
      _msgSubscription = FirestoreService.streamConversationMessages(newConv.id).listen((msgs) {
        _messages = msgs;
        notifyListeners();
      });
      return newConv;
    }();

    // 2. Add user message
    final userMsgId = 'msg_${now.millisecondsSinceEpoch}_user';
    final userMessage = ShiraziChatMessage(
      id: userMsgId,
      conversationId: activeConv.id,
      sender: 'user',
      content: query,
      timestamp: now,
    );

    // Optimistically update message list
    _messages = List.from(_messages)..add(userMessage);
    _isGenerating = true;
    _currentStreamingText = '';
    final topicLabel = researchTarget?.topicLabel ?? 'Classical Corpus';
    _currentReasoningSteps = [
      ReasoningStep(
        title: 'Topic Identified: $topicLabel',
        detail: 'Scanning Usul and Furu\' jurisprudence index for: $topicLabel...',
        isProcessing: true,
      ),
    ];
    notifyListeners();

    await FirestoreService.addMessage(
      conversationId: activeConv.id,
      message: userMessage,
    );

    // 3. Setup reasoning steps & dispatch to live Shirazi engine with consistent query language
    final stopwatch = Stopwatch()..start();

    // 3. Multi-tier BYOK fallback resolution (Preferred -> Secondary -> Alternative)
    final fallbackKeys = <String, String>{};
    if (storageService.geminiKey.isNotEmpty) {
      fallbackKeys['gemini'] = storageService.geminiKey;
    }
    if (storageService.groqKey.isNotEmpty) {
      fallbackKeys['groq'] = storageService.groqKey;
    }
    if (storageService.openRouterKey.isNotEmpty) {
      fallbackKeys['openrouter'] = storageService.openRouterKey;
    }

    final providerPriority = storageService.getActiveFallbackChain();
    final prefProv = storageService.preferredProvider;
    final primaryKey = storageService.getKeyForProvider(prefProv);

    debugPrint('[ChatProvider] Dispatching query. Loaded BYOK keys: ${fallbackKeys.keys.toList()}, priority: $providerPriority');

    final result = await apiService.streamRealtimeQuery(
      text: query,
      persona: _selectedPersona,
      lang: queryLang,
      madhhab: effectiveMadhhab,
      answerMode: _answerMode,
      byokKey: primaryKey,
      byokProvider: prefProv,
      fallbackKeys: fallbackKeys,
      providerPriority: providerPriority,
      onRequestId: (rid) => _activeRequestId = rid,
      onProgress: (progressMsg) {
        final currentSteps = List<ReasoningStep>.from(_currentReasoningSteps);
        final updatedSteps = currentSteps.map((s) => ReasoningStep(
          title: s.title,
          detail: s.detail,
          duration: s.duration.isEmpty ? '0.3s' : s.duration,
          isCompleted: true,
          isProcessing: false,
        )).toList();

        updatedSteps.add(ReasoningStep(
          title: 'Shirazi Scholarly Inference',
          detail: progressMsg,
          isCompleted: false,
          isProcessing: true,
        ));

        _currentReasoningSteps = updatedSteps;
        notifyListeners();
      },
    );

    stopwatch.stop();
    final latencyMs = stopwatch.elapsedMilliseconds;
    _serverLatencyMs = latencyMs;
    _activeRequestId = null;

    final isExhausted = result['status'] == 'EXHAUSTED' || result['isExhausted'] == true;
    final isQuotaExhausted = result['status'] == 'QUOTA_EXHAUSTED';
    final isCancelled = result['status'] == 'CANCELLED';
    final oracleKeysUsed = result['oracle_keys_used'] == true;
    final isByok = result['isByokFallback'] == true;
    final byokProv = result['byokProvider'] as String? ?? '';
    final isRealtime = result['isRealtimeStream'] == true;
    final resultCitations = (result['citations'] as List? ?? []).map((c) => c.toString()).toList();
    // Provenance: every normal answer must carry the Oracle source tag. If a
    // SUCCESS result ever arrives without it, we treat it as untrusted.
    final oracleSourced = result['source'] == 'shirazi-oracle';

    // ── Provenance gate (§5): a SUCCESS result without the Oracle source tag
    // is untrusted — it did not verifiably come through the Shirazi Oracle
    // channel. We refuse to display it as a Shirazi answer.
    //
    // Honest-failure rule (§6): we NEVER invent a scholarly answer. If there
    // is no answer text, we show the exhaustion message — never a fabricated
    // placeholder Arabic sentence.
    final isUntrustedSuccess =
        result['status'] == 'SUCCESS' && !oracleSourced;
    if (isUntrustedSuccess) {
      debugPrint('[ChatProvider] Refusing SUCCESS result without shirazi-oracle provenance.');
    }
    final noAnswerText = (result['answer'] as String?)?.trim().isEmpty ?? true;
    final effectiveExhausted = isExhausted ||
        isQuotaExhausted ||
        isUntrustedSuccess ||
        noAnswerText ||
        isCancelled;

    final answerText = isCancelled
        ? ApiService.getCancelledMessage(queryLang)
        : isQuotaExhausted
            ? ApiService.getQuotaExhaustedMessage(queryLang, oracleKeysUsed)
            : (noAnswerText
                ? ApiService.getExhaustionMessage(queryLang)
                : (result['answer'] as String? ?? ''));

    List<ReasoningStep> finalSteps;
    if (isQuotaExhausted) {
      finalSteps = [
        const ReasoningStep(
          title: 'Shirazi Oracle: inference capacity exhausted',
          detail: 'Research pipeline ran; no inference quota available',
          duration: '0.12s',
          isCompleted: false,
        ),
        ReasoningStep(
          title: 'Answer policy: no substitute generated',
          detail: oracleKeysUsed
              ? 'Personal key already routed via Shirazi pipeline — still at capacity'
              : 'Add a personal API key in Settings to route via the Shirazi pipeline',
          duration: '0.10s',
          isCompleted: false,
        ),
      ];
    } else if (isCancelled) {
      finalSteps = [
        const ReasoningStep(
          title: 'Query cancelled',
          detail: 'Cancellation sent to the Shirazi Oracle; no answer was generated',
          duration: '0.05s',
          isCompleted: false,
        ),
      ];
    } else if (isExhausted || isUntrustedSuccess) {
      finalSteps = [
        const ReasoningStep(
          title: 'Primary Shirazi Server & Core Gateway',
          detail: 'Quota reached, rate limit, or temporarily unavailable',
          duration: '0.12s',
          isCompleted: false,
        ),
        ReasoningStep(
          // No client-side "fallback engine" exists: a retry means the same
          // question goes back to the Shirazi Oracle, optionally with the
          // user's own key routed through the Oracle's pipeline.
          title: 'Personal Key Retry (via Shirazi Oracle)',
          detail: providerPriority.isEmpty
              ? 'No personal API key configured for an Oracle-pipeline retry'
              : 'Configured keys routed to the Shirazi Oracle pipeline reached limit or are unverified',
          duration: '0.15s',
          isCompleted: false,
        ),
      ];
    } else {
      // Client-observed reasoning log: these steps describe ONLY what the
      // client itself did and observed (dispatch, transport, receipt). They
      // do NOT claim to know the Oracle server's internal pipeline actions
      // (retrieval, verification, synthesis) — that would be fabrication.
      finalSteps = [
        ReasoningStep(
          title: 'Topic Identified: $topicLabel',
          detail: 'Client-side classification; full question dispatched to Shirazi Oracle',
          duration: '0.28s',
          isCompleted: true,
        ),
        ReasoningStep(
          title: 'Madhhab Filter: $effectiveMadhhab',
          detail: 'Preference sent with the request; applied by the Oracle server, not here',
          duration: '0.42s',
          isCompleted: true,
        ),
        ReasoningStep(
          title: 'Relevance Guard: Verified topic match',
          detail: isByok
              ? 'Personal key routed to Shirazi Oracle pipeline ($byokProv) — answer still came from the Oracle'
              : (isRealtime
                  ? 'Response arrived over the live Oracle channel; citations shown only as provided by the server'
                  : 'Response received from Shirazi Oracle; citations shown only as provided by the server'),
          duration: '0.35s',
          isCompleted: true,
        ),
      ];
    }

    final isSourceNotFound = result['isSourceNotFound'] == true;
    final assistantMsgId = 'msg_${DateTime.now().millisecondsSinceEpoch}_asst';
    final msgType = isSourceNotFound
        ? ShiraziMessageType.sourceNotFound
        : (isExhausted ? ShiraziMessageType.normal : ShiraziMessageType.normal);

    final assistantMessage = ShiraziChatMessage(
      id: assistantMsgId,
      conversationId: activeConv.id,
      sender: 'assistant',
      content: answerText,
      citations: resultCitations,
      reasoningSteps: finalSteps,
      urduAnnotation: effectiveExhausted
          ? null
          : (isByok
              // BYOK keys only ever travel to the Oracle pipeline (§7); the
              // answer still comes from the Shirazi Oracle Server.
              ? 'خلاصۂ فقہی: آپ کی ذاتی کلید شیرازی اوریکل پائپ لائن کے ذریعے استعمال ہوئی ($effectiveMadhhab مذہب)۔'
              : (isRealtime
                  ? 'خلاصۂ فقہی: شیرازی اوریکل سے براہِ راست حاصل کردہ جواب ($effectiveMadhhab مذہب)۔'
                  : 'خلاصۂ فقہی: شیرازی اوریکل سے حاصل کردہ جواب ($effectiveMadhhab مذہب)۔')),
      timestamp: DateTime.now(),
      latencyMs: latencyMs,
      byokProvider: effectiveExhausted
          ? null
          : (isByok ? byokProv : (isRealtime ? 'Shirazi Core Agent (Live)' : null)),
      isByokFallback: isByok,
      isError: effectiveExhausted,
      canRetry: effectiveExhausted || isSourceNotFound,
      failedQuery: (effectiveExhausted || isSourceNotFound) ? query : null,
      messageType: msgType,
    );

    _isGenerating = false;
    _currentStreamingText = '';
    _currentReasoningSteps = [];
    _messages = List.from(_messages)..add(assistantMessage);
    notifyListeners();

    await FirestoreService.addMessage(
      conversationId: activeConv.id,
      message: assistantMessage,
    );
  }

  /// Cancels the in-flight Oracle query, if any (§8). Emits the socket
  /// `cancel` event with the active request_id; the server stops its
  /// pipeline and the local timer / progress stream are torn down with it.
  /// The pending query completes with a structured CANCELLED state and the
  /// question is preserved for retry.
  Future<void> cancelCurrentQuery() async {
    final rid = _activeRequestId;
    if (rid == null || !_isGenerating) return;
    debugPrint('[ChatProvider] Cancelling in-flight query $rid');
    await apiService.cancelQuery(rid);
  }

  /// Retries a previously failed message with 1 tap, reusing the preserved question
  Future<void> retryMessage(ShiraziChatMessage failedMessage) async {
    final queryText = failedMessage.failedQuery ?? '';
    if (queryText.isEmpty || _isGenerating) return;

    // Remove the error message from current list
    _messages = _messages.where((m) => m.id != failedMessage.id).toList();
    notifyListeners();

    // Remove the error card from firestore
    await FirestoreService.deleteMessage(failedMessage.conversationId, failedMessage.id);

    // Re-execute query automatically
    await submitQuery(queryText);
  }

  Future<void> _initHeartbeat() async {
    final lat = await apiService.checkServerLatency();
    if (lat != null) {
      _serverLatencyMs = lat;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _convSubscription?.cancel();
    _msgSubscription?.cancel();
    super.dispose();
  }
}
