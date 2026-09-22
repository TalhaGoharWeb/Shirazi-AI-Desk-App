import 'dart:convert';

class ReasoningStep {
  final String title;
  final String detail;
  final String duration;
  final bool isCompleted;
  final bool isProcessing;

  const ReasoningStep({
    required this.title,
    required this.detail,
    this.duration = '',
    this.isCompleted = false,
    this.isProcessing = false,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'detail': detail,
    'duration': duration,
    'isCompleted': isCompleted,
    'isProcessing': isProcessing,
  };

  factory ReasoningStep.fromJson(Map<String, dynamic> json) => ReasoningStep(
    title: json['title'] ?? '',
    detail: json['detail'] ?? '',
    duration: json['duration'] ?? '',
    isCompleted: json['isCompleted'] ?? false,
    isProcessing: json['isProcessing'] ?? false,
  );
}

class ScholarlyPrinciple {
  final String titleArabic;
  final String titleEnglish;
  final String categoryArabic;
  final String descriptionArabic;
  final bool isPrimary;

  const ScholarlyPrinciple({
    required this.titleArabic,
    required this.titleEnglish,
    required this.categoryArabic,
    required this.descriptionArabic,
    this.isPrimary = true,
  });

  Map<String, dynamic> toJson() => {
    'titleArabic': titleArabic,
    'titleEnglish': titleEnglish,
    'categoryArabic': categoryArabic,
    'descriptionArabic': descriptionArabic,
    'isPrimary': isPrimary,
  };

  factory ScholarlyPrinciple.fromJson(Map<String, dynamic> json) => ScholarlyPrinciple(
    titleArabic: json['titleArabic'] ?? '',
    titleEnglish: json['titleEnglish'] ?? '',
    categoryArabic: json['categoryArabic'] ?? '',
    descriptionArabic: json['descriptionArabic'] ?? '',
    isPrimary: json['isPrimary'] ?? true,
  );
}

class Inquiry {
  final String id;
  final String questionArabic;
  final String questionEnglish;
  final String category;
  final String madhhab;
  final String persona;
  final DateTime timestamp;
  final bool isPinned;
  final bool isVerified;
  final String dossierRef;

  final String scriptureArabic;
  final String scriptureRef;
  final String scholarlyAnswerArabic;
  final String urduAnnotation;
  final List<ScholarlyPrinciple> principles;
  final List<String> citations;
  final List<ReasoningStep> reasoningSteps;
  final bool isByokFallback;
  final String byokProvider;

  const Inquiry({
    required this.id,
    required this.questionArabic,
    this.questionEnglish = '',
    required this.category,
    required this.madhhab,
    this.persona = 'muhaqqiq',
    required this.timestamp,
    this.isPinned = false,
    this.isVerified = true,
    this.dossierRef = '#892',
    this.scriptureArabic = '',
    this.scriptureRef = '',
    this.scholarlyAnswerArabic = '',
    this.urduAnnotation = '',
    this.principles = const [],
    this.citations = const [],
    this.reasoningSteps = const [],
    this.isByokFallback = false,
    this.byokProvider = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'questionArabic': questionArabic,
    'questionEnglish': questionEnglish,
    'category': category,
    'madhhab': madhhab,
    'persona': persona,
    'timestamp': timestamp.toIso8601String(),
    'isPinned': isPinned,
    'isVerified': isVerified,
    'dossierRef': dossierRef,
    'scriptureArabic': scriptureArabic,
    'scriptureRef': scriptureRef,
    'scholarlyAnswerArabic': scholarlyAnswerArabic,
    'urduAnnotation': urduAnnotation,
    'principles': principles.map((p) => p.toJson()).toList(),
    'citations': citations,
    'reasoningSteps': reasoningSteps.map((r) => r.toJson()).toList(),
    'isByokFallback': isByokFallback,
    'byokProvider': byokProvider,
  };

  factory Inquiry.fromJson(Map<String, dynamic> json) => Inquiry(
    id: json['id'] ?? '',
    questionArabic: json['questionArabic'] ?? '',
    questionEnglish: json['questionEnglish'] ?? '',
    category: json['category'] ?? '',
    madhhab: json['madhhab'] ?? 'Hanafi',
    persona: json['persona'] ?? 'muhaqqiq',
    timestamp: json['timestamp'] != null ? (DateTime.tryParse(json['timestamp']) ?? DateTime.now()) : DateTime.now(),
    isPinned: json['isPinned'] ?? false,
    isVerified: json['isVerified'] ?? true,
    dossierRef: json['dossierRef'] ?? '#892',
    scriptureArabic: json['scriptureArabic'] ?? '',
    scriptureRef: json['scriptureRef'] ?? '',
    scholarlyAnswerArabic: json['scholarlyAnswerArabic'] ?? '',
    urduAnnotation: json['urduAnnotation'] ?? '',
    principles: (json['principles'] as List? ?? []).map((p) => ScholarlyPrinciple.fromJson(p)).toList(),
    citations: List<String>.from(json['citations'] ?? []),
    reasoningSteps: (json['reasoningSteps'] as List? ?? []).map((r) => ReasoningStep.fromJson(r)).toList(),
    isByokFallback: json['isByokFallback'] ?? false,
    byokProvider: json['byokProvider'] ?? '',
  );

  factory Inquiry.fromBackendFatwa(Map<String, dynamic> json) {
    final List<String> citationsList = [];
    final rawCitations = json['citations'];
    if (rawCitations is List) {
      for (final c in rawCitations) {
        if (c is String && c.trim().isNotEmpty) {
          citationsList.add(c.trim());
        } else if (c is Map) {
          final book = c['book'] ?? '';
          final author = c['author'] != null && c['author'].toString().isNotEmpty ? ' (${c['author']})' : '';
          final vol = c['volume'] != null && c['volume'].toString().isNotEmpty ? ' ج ${c['volume']}' : '';
          final page = c['page'] != null && c['page'].toString().isNotEmpty ? ' ص ${c['page']}' : '';
          final str = '$book$author$vol$page'.trim();
          if (str.isNotEmpty) citationsList.add(str);
        }
      }
    }

    if (citationsList.isEmpty && json['citations_json'] != null) {
      try {
        final dynamic raw = json['citations_json'] is String
            ? jsonDecode(json['citations_json'])
            : json['citations_json'];
        if (raw is List) {
          for (final c in raw) {
            if (c is String && c.trim().isNotEmpty) {
              citationsList.add(c.trim());
            } else if (c is Map) {
              final book = c['book'] ?? '';
              final author = c['author'] != null ? ' (${c['author']})' : '';
              final vol = c['volume'] != null ? ' ج ${c['volume']}' : '';
              final page = c['page'] != null ? ' ص ${c['page']}' : '';
              final str = '$book$author$vol$page'.trim();
              if (str.isNotEmpty) citationsList.add(str);
            }
          }
        }
      } catch (_) {}
    }

    // Extract principles from evidence matrix
    final List<ScholarlyPrinciple> principlesList = [];
    final rawEvidence = json['evidence_matrix'];
    dynamic evidenceData = rawEvidence;
    if (evidenceData == null && json['evidence_matrix_json'] != null) {
      try {
        evidenceData = json['evidence_matrix_json'] is String
            ? jsonDecode(json['evidence_matrix_json'])
            : json['evidence_matrix_json'];
      } catch (_) {}
    }
    if (evidenceData is List) {
      for (final e in evidenceData) {
        if (e is Map<String, dynamic>) {
          principlesList.add(ScholarlyPrinciple(
            titleArabic: e['title_ar'] ?? e['titleArabic'] ?? e['rule'] ?? '',
            titleEnglish: e['title_en'] ?? e['titleEnglish'] ?? '',
            categoryArabic: e['category_ar'] ?? e['categoryArabic'] ?? 'أصل فقهي',
            descriptionArabic: e['description_ar'] ?? e['descriptionArabic'] ?? e['detail'] ?? '',
            isPrimary: e['is_primary'] ?? e['isPrimary'] ?? false,
          ));
        }
      }
    }

    final status = json['status'] as String? ?? 'draft';
    final madhhab = (json['madhhab'] as String? ?? 'Hanafi').trim();
    final capMadhhab = madhhab.isNotEmpty
        ? (madhhab[0].toUpperCase() + madhhab.substring(1).toLowerCase())
        : 'Hanafi';
    final q = json['original_question'] as String? ?? json['questionArabic'] ?? '';
    final ans = json['answer'] as String? ?? json['scholarlyAnswerArabic'] ?? '';
    final reviewerNotes = json['reviewer_notes'] as String?;
    final reviewerName = json['reviewer_name'] as String?;

    String annotation = json['urduAnnotation'] ?? '';
    if (annotation.isEmpty) {
      if (reviewerNotes != null && reviewerNotes.isNotEmpty) {
        annotation = 'ملاحظة المحقق ($reviewerName): $reviewerNotes';
      } else {
        annotation = 'خلاصۂ تحقيق: فتوى معتمدة ومستخرجة من خزانة نظام الشيرازي السحابية.';
      }
    }

    return Inquiry(
      id: json['id']?.toString() ?? '',
      questionArabic: q,
      questionEnglish: json['questionEnglish'] ?? '',
      category: json['discipline'] != null ? '# ${json['discipline']}' : '# Fiqh & Research',
      madhhab: capMadhhab,
      persona: 'muhaqqiq',
      timestamp: json['created_at'] != null ? (DateTime.tryParse(json['created_at']) ?? DateTime.now()) : DateTime.now(),
      isPinned: false,
      isVerified: status == 'verified',
      dossierRef: json['fatwa_ref'] ?? '#${json['id']?.toString().substring(0, 6) ?? 'SHZ'}',
      scholarlyAnswerArabic: ans,
      urduAnnotation: annotation,
      principles: principlesList,
      citations: citationsList,
    );
  }

  Inquiry copyWith({
    bool? isPinned,
    bool? isVerified,
    List<ReasoningStep>? reasoningSteps,
    String? scholarlyAnswerArabic,
    String? urduAnnotation,
    bool? isByokFallback,
    String? byokProvider,
    List<String>? citations,
  }) {
    return Inquiry(
      id: id,
      questionArabic: questionArabic,
      questionEnglish: questionEnglish,
      category: category,
      madhhab: madhhab,
      persona: persona,
      timestamp: timestamp,
      isPinned: isPinned ?? this.isPinned,
      isVerified: isVerified ?? this.isVerified,
      dossierRef: dossierRef,
      scriptureArabic: scriptureArabic,
      scriptureRef: scriptureRef,
      scholarlyAnswerArabic: scholarlyAnswerArabic ?? this.scholarlyAnswerArabic,
      urduAnnotation: urduAnnotation ?? this.urduAnnotation,
      principles: principles,
      citations: citations ?? this.citations,
      reasoningSteps: reasoningSteps ?? this.reasoningSteps,
      isByokFallback: isByokFallback ?? this.isByokFallback,
      byokProvider: byokProvider ?? this.byokProvider,
    );
  }
}
