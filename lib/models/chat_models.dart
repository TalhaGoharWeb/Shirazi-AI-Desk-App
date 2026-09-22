import 'package:cloud_firestore/cloud_firestore.dart';
import 'inquiry.dart';

/// Discriminates special Shirazi message types from normal chat messages.
/// Used by the UI to render clarification chips, honest source notices, etc.
enum ShiraziMessageType {
  /// Standard chat message (fatwa answer, user question, etc.)
  normal,

  /// Shirazi is asking the user to specify their madhhab before answering.
  /// The bubble renders 4 quick-reply chips: مالکی / حنفی / شافعی / حنبلی
  madhhabClarification,

  /// No relevant verified source was found — honest disclosure, no fabrication.
  sourceNotFound,

  /// Retrieved evidence topic did not match the user's question topic — rejected.
  topicMismatch,
}

class ShiraziConversation {
  final String id;
  final String ownerUid;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String language;
  final String madhhab;
  final String persona;
  final String lastMessagePreview;
  final int messageCount;
  final bool isPinned;
  final String? ownerEmail;
  final String? ownerName;

  const ShiraziConversation({
    required this.id,
    required this.ownerUid,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.language = 'en',
    this.madhhab = 'Hanafi',
    this.persona = 'muhaqqiq',
    this.lastMessagePreview = '',
    this.messageCount = 0,
    this.isPinned = false,
    this.ownerEmail,
    this.ownerName,
  });

  ShiraziConversation copyWith({
    String? id,
    String? ownerUid,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? language,
    String? madhhab,
    String? persona,
    String? lastMessagePreview,
    int? messageCount,
    bool? isPinned,
    String? ownerEmail,
    String? ownerName,
  }) {
    return ShiraziConversation(
      id: id ?? this.id,
      ownerUid: ownerUid ?? this.ownerUid,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      language: language ?? this.language,
      madhhab: madhhab ?? this.madhhab,
      persona: persona ?? this.persona,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      messageCount: messageCount ?? this.messageCount,
      isPinned: isPinned ?? this.isPinned,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      ownerName: ownerName ?? this.ownerName,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ownerUid': ownerUid,
      'title': title,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'language': language,
      'madhhab': madhhab,
      'persona': persona,
      'lastMessagePreview': lastMessagePreview,
      'messageCount': messageCount,
      'isPinned': isPinned,
      if (ownerEmail != null) 'ownerEmail': ownerEmail,
      if (ownerName != null) 'ownerName': ownerName,
    };
  }

  factory ShiraziConversation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ShiraziConversation.fromMap(doc.id, data);
  }

  factory ShiraziConversation.fromMap(String id, Map<String, dynamic> data) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

    return ShiraziConversation(
      id: id,
      ownerUid: data['ownerUid'] ?? '',
      title: data['title'] ?? 'New Inquiry',
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
      language: data['language'] ?? 'en',
      madhhab: data['madhhab'] ?? 'Hanafi',
      persona: data['persona'] ?? 'muhaqqiq',
      lastMessagePreview: data['lastMessagePreview'] ?? '',
      messageCount: data['messageCount'] ?? 0,
      isPinned: data['isPinned'] ?? false,
      ownerEmail: data['ownerEmail'],
      ownerName: data['ownerName'],
    );
  }
}

class ShiraziChatMessage {
  final String id;
  final String conversationId;
  final String sender; // 'user' | 'assistant'
  final String content;
  final List<String> citations;
  final List<ReasoningStep> reasoningSteps;
  final String? urduAnnotation;
  final DateTime timestamp;
  final int? latencyMs;
  final String? byokProvider;
  final bool? _isByokFallback;
  bool get isByokFallback => _isByokFallback ?? false;

  final bool? _isError;
  bool get isError => _isError ?? false;

  final bool? _canRetry;
  bool get canRetry => _canRetry ?? false;

  final String? failedQuery;

  /// Specifies the message type for UI rendering.
  final ShiraziMessageType? _messageType;
  ShiraziMessageType get messageType => _messageType ?? ShiraziMessageType.normal;

  /// The pending query text, preserved for madhhab clarification flow.
  final String? pendingQuery;

  const ShiraziChatMessage({
    required this.id,
    required this.conversationId,
    required this.sender,
    required this.content,
    this.citations = const [],
    this.reasoningSteps = const [],
    this.urduAnnotation,
    required this.timestamp,
    this.latencyMs,
    this.byokProvider,
    bool? isByokFallback = false,
    bool? isError = false,
    bool? canRetry = false,
    this.failedQuery,
    ShiraziMessageType? messageType = ShiraziMessageType.normal,
    this.pendingQuery,
  })  : _isByokFallback = isByokFallback ?? false,
        _isError = isError ?? false,
        _canRetry = canRetry ?? false,
        _messageType = messageType ?? ShiraziMessageType.normal;

  bool get isUser => sender == 'user';
  bool get isAssistant => sender == 'assistant';

  ShiraziChatMessage copyWith({
    String? id,
    String? conversationId,
    String? sender,
    String? content,
    List<String>? citations,
    List<ReasoningStep>? reasoningSteps,
    String? urduAnnotation,
    DateTime? timestamp,
    int? latencyMs,
    String? byokProvider,
    bool? isByokFallback,
    bool? isError,
    bool? canRetry,
    String? failedQuery,
    ShiraziMessageType? messageType,
    String? pendingQuery,
  }) {
    return ShiraziChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      sender: sender ?? this.sender,
      content: content ?? this.content,
      citations: citations ?? this.citations,
      reasoningSteps: reasoningSteps ?? this.reasoningSteps,
      urduAnnotation: urduAnnotation ?? this.urduAnnotation,
      timestamp: timestamp ?? this.timestamp,
      latencyMs: latencyMs ?? this.latencyMs,
      byokProvider: byokProvider ?? this.byokProvider,
      isByokFallback: isByokFallback ?? this.isByokFallback,
      isError: isError ?? this.isError,
      canRetry: canRetry ?? this.canRetry,
      failedQuery: failedQuery ?? this.failedQuery,
      messageType: messageType ?? this.messageType,
      pendingQuery: pendingQuery ?? this.pendingQuery,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'conversationId': conversationId,
      'sender': sender,
      'content': content,
      'citations': citations,
      'reasoningSteps': reasoningSteps.map((s) => s.toJson()).toList(),
      if (urduAnnotation != null) 'urduAnnotation': urduAnnotation,
      'timestamp': Timestamp.fromDate(timestamp),
      if (latencyMs != null) 'latencyMs': latencyMs,
      if (byokProvider != null) 'byokProvider': byokProvider,
      'isByokFallback': isByokFallback,
      'isError': isError,
      'canRetry': canRetry,
      if (failedQuery != null) 'failedQuery': failedQuery,
      'messageType': messageType.name,
      if (pendingQuery != null) 'pendingQuery': pendingQuery,
    };
  }

  factory ShiraziChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ShiraziChatMessage.fromMap(doc.id, data);
  }

  factory ShiraziChatMessage.fromMap(String id, Map<String, dynamic> data) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

    final rawCitations = data['citations'];
    List<String> parsedCitations = [];
    if (rawCitations is List) {
      parsedCitations = rawCitations.map((c) => c.toString()).toList();
    }

    final rawSteps = data['reasoningSteps'];
    List<ReasoningStep> parsedSteps = [];
    if (rawSteps is List) {
      parsedSteps = rawSteps
          .map((s) => s is Map<String, dynamic> ? ReasoningStep.fromJson(s) : null)
          .whereType<ReasoningStep>()
          .toList();
    }

    ShiraziMessageType parsedType = ShiraziMessageType.normal;
    final rawType = data['messageType'] as String?;
    if (rawType != null) {
      parsedType = ShiraziMessageType.values.firstWhere(
        (t) => t.name == rawType,
        orElse: () => ShiraziMessageType.normal,
      );
    }

    return ShiraziChatMessage(
      id: id,
      conversationId: data['conversationId'] ?? '',
      sender: data['sender'] ?? 'assistant',
      content: data['content'] ?? '',
      citations: parsedCitations,
      reasoningSteps: parsedSteps,
      urduAnnotation: data['urduAnnotation'],
      timestamp: parseDate(data['timestamp']),
      latencyMs: data['latencyMs'],
      byokProvider: data['byokProvider'],
      isByokFallback: data['isByokFallback'] ?? false,
      isError: data['isError'] ?? false,
      canRetry: data['canRetry'] ?? false,
      failedQuery: data['failedQuery'],
      messageType: parsedType,
      pendingQuery: data['pendingQuery'],
    );
  }
}
