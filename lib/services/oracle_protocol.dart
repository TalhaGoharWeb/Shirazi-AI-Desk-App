/// Pure-Dart Shirazi Oracle protocol helpers.
///
/// This file intentionally imports NOTHING from Flutter or Firebase so that
/// every function in it can be unit-tested with the standalone Dart SDK.
///
/// Contents:
/// - [OracleEndpoint]: parses/validates the Oracle base URL, exposes whether
///   the transport is secure, and renders a log-safe (credential-free) form.
/// - [SUPPORTED_BYOK_PROVIDERS]: allowlist — the Oracle must reject any
///   provider not on this list. The client must never turn the Oracle into a
///   proxy for arbitrary endpoints.
/// - [OracleFailure]: failure taxonomy for HTTP / network / provider errors.
/// - [categorizeHttpStatus]: pure mapping from HTTP status code to failure.
/// - [generateRequestId]: UUID v4 for request tracing.
/// - [hasOracleProvenance]: the client-side provenance gate.
/// - Localised user-facing messages (exhaustion / quota / auth / insecure
///   transport) and the outage-text detector [isLimitOrOutage].
library oracle_protocol;

import 'dart:math';

/// Allowlisted AI providers the Oracle may use for server-side BYOK
/// inference. Anything not on this list must be rejected server-side.
const List<String> SUPPORTED_BYOK_PROVIDERS = <String>[
  'groq',
  'gemini',
  'openrouter',
];

/// Returns true when [provider] is on the allowlist (case-insensitive).
bool isSupportedByokProvider(String? provider) {
  if (provider == null) return false;
  return SUPPORTED_BYOK_PROVIDERS.contains(provider.trim().toLowerCase());
}

/// Parsed Oracle server endpoint with transport-security helpers.
class OracleEndpoint {
  final Uri uri;

  OracleEndpoint._(this.uri);

  /// Parses [raw]; throws [FormatException] when the URL is unusable.
  /// A missing scheme is assumed to be http (and therefore insecure).
  factory OracleEndpoint.parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Oracle URL is empty');
    }
    var uri = Uri.tryParse(trimmed);
    if (uri == null || uri.host.isEmpty) {
      // Try again with an explicit http:// prefix.
      uri = Uri.tryParse('http://$trimmed');
    }
    if (uri == null || uri.host.isEmpty) {
      throw FormatException('Invalid Oracle URL: $raw');
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      throw FormatException('Oracle URL must use http or https: $raw');
    }
    // Reject hosts that only parsed because Uri percent-encoded garbage
    // (e.g. "not a url !!!" -> host "not%20a%20url%20!!!").
    final host = uri.host;
    final hostOk = RegExp(
      r'^([A-Za-z0-9]([A-Za-z0-9\-.]*[A-Za-z0-9])?|\d{1,3}(\.\d{1,3}){3})$',
    ).hasMatch(host);
    if (!hostOk) {
      throw FormatException('Invalid Oracle host: $raw');
    }
    return OracleEndpoint._(uri);
  }

  /// True only for https:// — the only acceptable production transport.
  bool get isSecure => uri.scheme == 'https';

  /// Socket.IO transport scheme matching the HTTP scheme.
  String get socketScheme => isSecure ? 'wss' : 'ws';

  /// Base URL string used for requests.
  String get baseUrl {
    final port = uri.hasPort ? ':${uri.port}' : '';
    return '${uri.scheme}://${uri.host}$port';
  }

  /// Log-safe representation. Never includes userinfo, paths, or query
  /// parameters, so credentials can never leak through it into logs.
  String get redacted {
    final port = uri.hasPort ? ':${uri.port}' : '';
    return '${uri.scheme}://${uri.host}$port';
  }

  @override
  String toString() => redacted;
}

/// Failure taxonomy for Oracle interactions. Used to map raw transport,
/// HTTP, and provider errors onto stable, testable states.
enum OracleFailure {
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  rateLimited,
  serverError,
  badGateway,
  serviceUnavailable,
  gatewayTimeout,
  timeout,
  transport,
  tls,
  dns,
  quotaExhausted,
  authRejected,
  insecureTransportBlocked,
  unknown,
}

/// Pure mapping from HTTP status code to [OracleFailure].
OracleFailure categorizeHttpStatus(int code) {
  switch (code) {
    case 400:
      return OracleFailure.badRequest;
    case 401:
      return OracleFailure.unauthorized;
    case 403:
      return OracleFailure.forbidden;
    case 404:
      return OracleFailure.notFound;
    case 408:
      return OracleFailure.gatewayTimeout;
    case 409:
      return OracleFailure.conflict;
    case 429:
      return OracleFailure.rateLimited;
    case 500:
    case 501:
      return OracleFailure.serverError;
    case 502:
      return OracleFailure.badGateway;
    case 503:
      return OracleFailure.serviceUnavailable;
    case 504:
      return OracleFailure.gatewayTimeout;
    default:
      if (code >= 500) return OracleFailure.serverError;
      if (code >= 400) return OracleFailure.badRequest;
      return OracleFailure.unknown;
  }
}

/// Generates a UUID v4 request ID for end-to-end tracing:
/// app -> Oracle API -> research pipeline -> AI provider -> response -> app.
String generateRequestId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant 10
  final hex =
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

/// Client-side provenance gate (§10).
///
/// A result with status SUCCESS is trusted only when it carries the
/// Oracle source tag. Anything else claiming success is untrusted and must
/// be refused — never displayed as a Shirazi answer.
bool hasOracleProvenance(Map<String, dynamic> result) {
  if (result['status'] == 'SUCCESS') {
    return result['source'] == 'shirazi-oracle';
  }
  return true;
}

/// Validates that an echoed request ID matches the one we sent.
/// A mismatch means the response does not belong to our request.
bool requestIdMatches(Map<String, dynamic> result, String requestId) {
  final echoed = result['request_id']?.toString();
  if (echoed == null || echoed.isEmpty) return true; // server may not echo yet
  return echoed == requestId;
}

/// Builds the ordered provider-priority list for a server-side BYOK request.
/// Only allowlisted providers are kept — anything else is dropped so the
/// Oracle can never be steered toward an arbitrary endpoint.
List<String> priorityListFor(
  Map<String, String> userKeysPayload,
  List<String>? providerPriority,
  String? byokProvider,
) {
  final priorityList = <String>[];
  void add(String? p) {
    if (p == null) return;
    final norm = p.trim().toLowerCase();
    if (norm.isNotEmpty &&
        isSupportedByokProvider(norm) &&
        !priorityList.contains(norm)) {
      priorityList.add(norm);
    }
  }

  if (providerPriority != null) {
    for (final p in providerPriority) {
      add(p);
    }
  } else {
    add(byokProvider);
  }
  for (final k in userKeysPayload.keys) {
    add(k);
  }
  return priorityList;
}

/// Detects Oracle outage / quota-exhaustion wording in a response answer
/// across Urdu, Arabic, and English.
bool isLimitOrOutage(Map? data, String answer) {
  if (data is Map) {
    if (data['ok'] == false ||
        data['status'] == 'ERROR' ||
        data['error'] != null) {
      return true;
    }
  }
  final a = answer.trim();
  final lower = a.toLowerCase();

  if (a.contains('دستیاب نہیں') ||
      a.contains('عارضی طور پر') ||
      a.contains('مصروف') ||
      a.contains('تمام دستیاب') ||
      a.contains('دوبارہ کوشش') ||
      a.contains('عطل مؤقت') ||
      a.contains('غير متاحة') ||
      a.contains('مشغولة') ||
      a.contains('مشغول') ||
      a.contains('الحد المسموح') ||
      a.contains('تم الوصول للحد') ||
      a.contains('تجاوزت الحد') ||
      a.contains('الرصيد') ||
      a.contains('تعذر استلام الرد') ||
      a.contains('إعادة المحاولة') ||
      lower.contains('rate limit') ||
      lower.contains('quota exceeded') ||
      lower.contains('limit reached') ||
      lower.contains('too many requests') ||
      lower.contains('free tier exhausted') ||
      lower.contains('busy') ||
      lower.contains('unavailable') ||
      lower.contains('try again later')) {
    return true;
  }

  if (a.length < 220 &&
      (a.contains('عطل') ||
          a.contains('خطأ') ||
          a.contains('خادم') ||
          a.contains('سرور') ||
          a.contains('server') ||
          a.contains('error') ||
          a.contains('failed'))) {
    return true;
  }

  return false;
}

/// Localized exhaustion notice: the Oracle could not answer; the question is
/// preserved for retry. Never a substituted answer.
String getExhaustionMessage(String lang) {
  switch (lang) {
    case 'ur':
      return 'شیرازی تحقیقی سرور اور تمام متبادل ذرائع اس وقت مصروف یا دستیاب نہیں ہیں۔\n\n'
          'کوئی متبادل AI جواب تیار نہیں کیا گیا۔ آپ کا سوال محفوظ ہے؛ "دوبارہ کوشش" دبائیں یا ترتیبات میں اپنی ذاتی API Key شامل کریں (جو صرف شیرازی تحقیقی پائپ لائن کے ذریعے استعمال ہوگی)۔';
    case 'ar':
      return 'خادم الشيرازي البحثي وجميع المصادر البديلة مشغولة أو غير متاحة حالياً.\n\n'
          'لم يتم إنشاء أي إجابة بديلة. سؤالك محفوظ؛ اضغط "إعادة المحاولة" أو أضف مفتاح API شخصي في الإعدادات (سيُستخدم عبر خط أنابيب الشيرازي البحثي فقط).';
    default:
      return 'The Shirazi research network and all fallback sources are currently busy or unavailable.\n\n'
          'No substitute AI answer has been generated. Your question has been preserved — tap "Retry Query" or add a personal API key in Settings (used only through the Shirazi research pipeline).';
  }
}

/// Localized notice for Oracle inference-quota exhaustion.
/// [oracleKeysUsed] tells whether the user's personal key was already routed
/// through the Shirazi pipeline for this question.
String getQuotaExhaustedMessage(String lang, bool oracleKeysUsed) {
  switch (lang) {
    case 'ur':
      return oracleKeysUsed
          ? 'شیرازی تحقیقی سرور کی موجودہ استعدادی گنجائش ختم ہو چکی ہے — آپ کی ذاتی API Key شیرازی تحقیقی پائپ لائن کے ذریعے پہلے ہی استعمال ہو چکی ہے۔\n\n'
              'کوئی متبادل AI جواب نہیں دیا گیا۔ آپ کا سوال محفوظ ہے؛ کچھ دیر بعد "دوبارہ کوشش" دبائیں۔'
          : 'شیرازی تحقیقی سرور کی موجودہ استعدادی گنجائش ختم ہو چکی ہے۔\n\n'
              'کوئی متبادل AI جواب نہیں دیا گیا۔ آپ ترتیبات میں اپنی ذاتی API Key شامل کر سکتے ہیں — وہ صرف شیرازی تحقیقی پائپ لائن کے ذریعے استعمال ہوگی، براہِ راست جواب کے لیے کبھی نہیں۔';
    case 'ar':
      return oracleKeysUsed
          ? 'بلغت السعة الاستدلالية لخادم الشيرازي البحثي حدها — وقد تم بالفعل استخدام مفتاح API الشخصي الخاص بك عبر خط أنابيب الشيرازي البحثي.\n\n'
              'لم يتم توليد أي إجابة بديلة. سؤالك محفوظ؛ اضغط "إعادة المحاولة" بعد قليل.'
          : 'بلغت السعة الاستدلالية لخادم الشيرازي البحثي حدها الحالي.\n\n'
              'لم يتم توليد أي إجابة بديلة. يمكنك إضافة مفتاح API شخصي في الإعدادات — سيُستخدم عبر خط أنابيب الشيرازي البحثي فقط، وليس للإجابة المباشرة أبداً.';
    default:
      return oracleKeysUsed
          ? 'The Shirazi Research Server has reached its current inference capacity — your personal API key was already routed through the Shirazi research pipeline for this question.\n\n'
              'No substitute AI answer has been generated. Your question is preserved; tap "Retry Query" shortly.'
          : 'The Shirazi Research Server has reached its current inference capacity.\n\n'
              'No substitute AI answer has been generated. You may add a personal API key in Settings — it will only ever be used through the Shirazi research pipeline, never for direct answers.';
  }
}

/// Localized notice for Oracle authentication rejection.
String getAuthErrorMessage(String lang) {
  switch (lang) {
    case 'ur':
      return 'شیرازی سرور نے درخواست کی توثیق مسترد کر دی ہے۔\n\nکوئی جواب تیار نہیں کیا گیا۔ براہِ کرم دوبارہ سائن ان کریں یا کچھ دیر بعد دوبارہ کوشش کریں۔';
    case 'ar':
      return 'رفض خادم الشيرازي مصادقة هذا الطلب.\n\nلم يتم إنشاء أي إجابة. يرجى تسجيل الدخول مرة أخرى أو إعادة المحاولة لاحقاً.';
    default:
      return 'The Shirazi server rejected this request\u2019s authentication.\n\nNo answer has been generated. Please sign in again or retry shortly.';
  }
}

/// Localized notice shown when credential transmission is blocked because the
/// Oracle endpoint does not use HTTPS.
String getInsecureTransportBlockedMessage(String lang) {
  switch (lang) {
    case 'ur':
      return 'حفاظتی پابندی: آپ کی API Key غیر محفوظ (HTTP) کنکشن پر نہیں بھیجی جا سکتی۔\n\n'
          'براہِ کرم شیرازی سرور کا HTTPS ایڈریس استعمال کریں۔ آپ کا سوال محفوظ ہے۔';
    case 'ar':
      return 'قيد أمني: لا يمكن إرسال مفتاح API الخاص بك عبر اتصال غير آمن (HTTP).\n\n'
          'يرجى استخدام عنوان HTTPS لخادم الشيرازي. سؤالك محفوظ.';
    default:
      return 'Security policy: your API key cannot be sent over an insecure (HTTP) connection.\n\n'
          'Please use the HTTPS address of your Shirazi Oracle server. Your question is preserved.';
  }
}
