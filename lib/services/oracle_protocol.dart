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

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

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
  untrustedResponse,
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
/// A missing, empty, or mismatched echo means the response does not belong
/// to our request — it must be ignored (stray/duplicate). The hardened
/// Oracle always echoes request_id, so the old tolerance for a missing
/// echo has been dropped.
bool requestIdMatches(Map<String, dynamic> result, String requestId) {
  final echoed = result['request_id']?.toString();
  if (echoed == null || echoed.isEmpty) return false;
  return echoed == requestId;
}

/// ── Oracle response provenance (§2) ──────────────────────────────────
/// The hardened Oracle signs every assistant answer with Ed25519. The
/// signed message is the UTF-8 string:
///   `${response_id}.${request_id}.${sha256hex(answer)}`
/// where response_id is a per-answer UUID in provenance.response_id,
/// request_id is the echoed client request ID, and sha256hex(answer) is the
/// hex digest of SHA-256 over the UTF-8 bytes of the exact answer string.
///
/// The public key below is PUBLIC (SPKI DER, base64) — safe to embed and
/// ship. Signatures arrive base64-encoded in provenance.signature.

/// Expected key_id for the current Oracle signing key.
const String oracleEd25519KeyId = 'shirazi-oracle-2026-09-24';

/// SPKI DER (base64) of the Oracle's Ed25519 public key. PUBLIC — safe to embed.
const String oracleEd25519PublicKeySpki =
    'MCowBQYDK2VwAyEAXRz7qS3HddEhEUGnOplA8KzUd8ULHSgIKXS78QLnCZ0=';

/// Extracts the raw 32-byte Ed25519 public key from an RFC 8410 SPKI DER.
///
/// An Ed25519 SPKI is exactly 44 bytes:
///   SEQUENCE { SEQUENCE { OID 1.3.101.112 }, BIT STRING { 32-byte key } }
Uint8List ed25519RawKeyFromSpki(Uint8List spki) {
  const prefix = <int>[
    0x30, 0x2a, // SEQUENCE, length 42
    0x30, 0x05, // SEQUENCE, length 5
    0x06, 0x03, 0x2b, 0x65, 0x70, // OID 1.3.101.112 (Ed25519)
    0x03, 0x21, 0x00, // BIT STRING, length 33, 0 unused bits
  ];
  if (spki.length != prefix.length + 32) {
    throw FormatException('Invalid Ed25519 SPKI length: ${spki.length}');
  }
  for (var i = 0; i < prefix.length; i++) {
    if (spki[i] != prefix[i]) {
      throw FormatException('Not an Ed25519 SPKI (prefix mismatch at byte $i)');
    }
  }
  return Uint8List.fromList(spki.sublist(prefix.length));
}

/// Hex digest of SHA-256 over the UTF-8 bytes of [input].
Future<String> sha256Hex(String input) async {
  final digest = await Sha256().hash(utf8.encode(input));
  return digest.bytes
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join();
}

/// Rebuilds the exact signed message for an Oracle answer:
/// `${response_id}.${request_id}.${sha256hex(answer)}`.
Future<String> oracleSignatureMessage({
  required String responseId,
  required String requestId,
  required String answer,
}) async {
  final answerDigestHex = await sha256Hex(answer);
  return '$responseId.$requestId.$answerDigestHex';
}

/// Verifies an Oracle assistant answer's Ed25519 provenance.
///
/// Recomputes sha256hex(answer), rebuilds the dotted signed message from
/// the received response_id + request_id, and verifies [signatureBase64]
/// against the embedded Oracle public key. A [keyId] that does not match
/// the current signing key also fails. Any parse/verify error returns false
/// (never throws) — the caller must treat false as untrusted.
Future<bool> verifyOracleProvenance({
  required String responseId,
  required String requestId,
  required String answer,
  required String signatureBase64,
  String? keyId,
}) async {
  try {
    if (keyId != null && keyId.isNotEmpty && keyId != oracleEd25519KeyId) {
      return false;
    }
    if (responseId.isEmpty || requestId.isEmpty) return false;
    final message = await oracleSignatureMessage(
      responseId: responseId,
      requestId: requestId,
      answer: answer,
    );
    final spki = base64Decode(oracleEd25519PublicKeySpki);
    final rawKey = ed25519RawKeyFromSpki(Uint8List.fromList(spki));
    final publicKey = SimplePublicKey(rawKey, type: KeyPairType.ed25519);
    final signature =
        Signature(base64Decode(signatureBase64), publicKey: publicKey);
    return await Ed25519().verify(utf8.encode(message), signature: signature);
  } catch (_) {
    return false;
  }
}
/// ─────────────────────────────────────────────────────────────────────────

/// Builds the ordered provider-priority list for a server-side BYOK request.
/// Only allowlisted providers are kept — anything else is dropped so the
/// Oracle can never be steered toward an arbitrary endpoint.
List<String> priorityListFor(
  List<Map<String, String>> userKeysPayload,
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
  for (final e in userKeysPayload) {
    add(e['provider']);
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

  // ── Hardened single-word triggers (§19) ──────────────────────────────
  // Bare substring matching on these misfired on legitimate fiqh prose:
  // Urdu 'مصروفیت' contains 'مصروف'; Arabic 'مشغولاً' contains 'مشغول';
  // English "busy at work" contains 'busy'. Each is now matched so that
  // grammatical derivations of ordinary fiqh vocabulary do not trip it,
  // while the server's real outage phrasing still matches.
  final urduBusyOutage = RegExp(r'مصروف(?!ی)').hasMatch(a);
  final arabicBusyOutage = RegExp(r'مشغول(?![اة])').hasMatch(a);
  final englishBusyOutage = RegExp(r'\bbusy\b').hasMatch(lower) &&
      (lower.contains('server') ||
          lower.contains('try again') ||
          lower.contains('unavailable') ||
          lower.contains('temporarily'));

  // ── Contextual failure markers (§19) ─────────────────────────────────
  // Bare words like 'unavailable', 'error', 'failed', 'server', 'عطل',
  // 'خطأ', 'خادم', 'سرور' all occur in legitimate fiqh prose ("an error in
  // ijtihad", "the property remains unavailable", "a defect (عطل) in a sold
  // item", "a servant (خادم)"), so each one needs transport/service failure
  // context before it counts as an outage signal.
  final unavailableOutage = RegExp(
    r'\b(service|server|system)\b.{0,24}\bunavailable\b'
    r'|\btemporarily unavailable\b',
  ).hasMatch(lower);
  final serverFailureOutage = RegExp(
    r'\b(server|service|system)\b.{0,20}\b(error|unavailable|busy|down|failed|failure|timeout)\b'
    r'|(connection|network|request|chat|socket)[\s_-]*\berror\b'
    r'|\berror\s*[:：]'
    r'|\bfailed to (connect|fetch|load|reach|send)\b'
    r'|(connection|request|chat|socket)\s+failed\b',
  ).hasMatch(lower);
  final arabicOutageFault = RegExp(r'عطل\s+(مؤقت|فني)').hasMatch(a) ||
      a.contains('عطل في الخادم') ||
      a.contains('عطل في النظام') ||
      a.contains('عطل في الاتصال');
  final arabicErrorFault = a.contains('خطأ في الخادم') ||
      a.contains('خطأ في الاتصال') ||
      a.contains('خطأ في النظام') ||
      RegExp(r'خطأ\s*[:：]').hasMatch(a) ||
      RegExp(r'خطأ\s+رقم\s*\d').hasMatch(a);
  final arabicServerFault = RegExp(r'(عطل|خطأ)\s+في\s+الخادم').hasMatch(a) ||
      RegExp(r'الخادم\s+(غير متاح|مشغول|متوقف|لا يستجيب|معطل)').hasMatch(a);
  final urduServerFault = RegExp(r'سرور\s+(خراب|بند|ڈاؤن|مصروف)').hasMatch(a) ||
      RegExp(r'سرور\s+میں\s+(خرابی|عطل)').hasMatch(a) ||
      a.contains('سرور دستیاب نہیں');

  if (a.contains('دستیاب نہیں') ||
      a.contains('عارضی طور پر') ||
      urduBusyOutage ||
      a.contains('تمام دستیاب') ||
      a.contains('دوبارہ کوشش') ||
      a.contains('عطل مؤقت') ||
      a.contains('غير متاحة') ||
      a.contains('مشغولة') ||
      arabicBusyOutage ||
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
      englishBusyOutage ||
      unavailableOutage ||
      lower.contains('try again later')) {
    return true;
  }

  // Short terse texts (<220 chars): only contextual transport/service
  // failure markers count — never the bare words on their own.
  if (a.length < 220 &&
      (serverFailureOutage ||
          arabicOutageFault ||
          arabicErrorFault ||
          arabicServerFault ||
          urduServerFault)) {
    return true;
  }

  return false;
}

/// Localized notice shown when an Oracle answer fails authenticity
/// verification (bad/missing signature). The answer is discarded and never
/// displayed.
String getUntrustedResponseMessage(String lang) {
  switch (lang) {
    case 'ur':
      return 'شیرازی سرور کا جواب تصدیقی جانچ میں ناکام رہا ہے؛ کوئی غیر تصدیق شدہ جواب دکھایا نہیں گیا۔\n\n'
          'آپ کا سوال محفوظ ہے — "دوبارہ کوشش" دبائیں۔';
    case 'ar':
      return 'تعذّر التحقق من أصالة رد خادم الشيرازي؛ لن يُعرض أي رد غير موثّق.\n\n'
          'سؤالك محفوظ — اضغط "إعادة المحاولة".';
    default:
      return 'The Shirazi Oracle returned a response that failed authenticity verification — no unverified answer is shown.\n\n'
          'Your question is preserved; tap "Retry Query".';
  }
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

/// Localized notice for a user-cancelled query. The Oracle pipeline was
/// stopped before producing an answer; the question is preserved for retry.
String getCancelledMessage(String lang) {
  switch (lang) {
    case 'ur':
      return 'آپ نے یہ سوال منسوخ کر دیا ہے۔ کوئی جواب تیار نہیں کیا گیا۔\n\n'
          'آپ کا سوال محفوظ ہے؛ "دوبارہ کوشش" دبائیں۔';
    case 'ar':
      return 'لقد ألغيت هذا السؤال. لم يتم إنشاء أي إجابة.\n\n'
          'سؤالك محفوظ؛ اضغط "إعادة المحاولة".';
    default:
      return 'You cancelled this question. No answer was generated.\n\n'
          'Your question is preserved; tap "Retry Query".';
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
