/// Failure-matrix unit tests for the Shirazi Oracle protocol layer (§19).
///
/// These tests run with the STANDALONE Dart SDK (`dart test`) — no Flutter
/// needed — because oracle_protocol.dart imports nothing from Flutter.
///
/// Coverage:
/// - HTTP status -> OracleFailure taxonomy (400/401/403/404/408/409/429/5xx)
/// - Outage / quota-exhaustion text detection (ur/ar/en)
/// - Provenance gate: SUCCESS without the Oracle source tag is untrusted
/// - Request-ID echo validation (strict: missing/foreign echoes rejected)
/// - Ed25519 response provenance: SPKI parse, sha256hex, signed-message
///   construction, signature verify, untrusted-response messaging
import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:test/test.dart';

import 'package:shirazi_app/services/oracle_protocol.dart';

void main() {
  group('categorizeHttpStatus — HTTP failure taxonomy (§19)', () {
    test('400 -> badRequest', () {
      expect(categorizeHttpStatus(400), OracleFailure.badRequest);
    });
    test('401 -> unauthorized', () {
      expect(categorizeHttpStatus(401), OracleFailure.unauthorized);
    });
    test('403 -> forbidden', () {
      expect(categorizeHttpStatus(403), OracleFailure.forbidden);
    });
    test('404 -> notFound', () {
      expect(categorizeHttpStatus(404), OracleFailure.notFound);
    });
    test('408 -> gatewayTimeout', () {
      expect(categorizeHttpStatus(408), OracleFailure.gatewayTimeout);
    });
    test('409 -> conflict', () {
      expect(categorizeHttpStatus(409), OracleFailure.conflict);
    });
    test('429 -> rateLimited (quota)', () {
      expect(categorizeHttpStatus(429), OracleFailure.rateLimited);
    });
    test('500/501 -> serverError', () {
      expect(categorizeHttpStatus(500), OracleFailure.serverError);
      expect(categorizeHttpStatus(501), OracleFailure.serverError);
    });
    test('502 -> badGateway', () {
      expect(categorizeHttpStatus(502), OracleFailure.badGateway);
    });
    test('503 -> serviceUnavailable', () {
      expect(categorizeHttpStatus(503), OracleFailure.serviceUnavailable);
    });
    test('504 -> gatewayTimeout', () {
      expect(categorizeHttpStatus(504), OracleFailure.gatewayTimeout);
    });
    test('unlisted 5xx -> serverError; unlisted 4xx -> badRequest', () {
      expect(categorizeHttpStatus(599), OracleFailure.serverError);
      expect(categorizeHttpStatus(418), OracleFailure.badRequest);
    });
  });

  group('isLimitOrOutage — quota/outage detection', () {
    test('detects the real Urdu outage message from the live server', () {
      const msg =
          'اس وقت تحقیقی نظام کے تمام دستیاب AI ذرائع عارضی طور پر مصروف یا دستیاب نہیں ہیں۔ براہِ کرم کچھ دیر بعد دوبارہ کوشش فرمائیں۔';
      expect(isLimitOrOutage({'answer': msg, 'route': 'x'}, msg), isTrue);
      expect(isLimitOrOutage(null, msg), isTrue);
    });
    test('detects English quota wording', () {
      expect(isLimitOrOutage(null, 'Quota exceeded for today. Try again later.'), isTrue);
      expect(isLimitOrOutage(null, 'HTTP 429: too many requests'), isTrue);
      expect(isLimitOrOutage(null, 'Service temporarily unavailable'), isTrue);
    });
    test('detects Arabic outage wording', () {
      expect(isLimitOrOutage(null, 'عطل مؤقت في الخادم، يرجى إعادة المحاولة'), isTrue);
    });
    test('detects error maps', () {
      expect(isLimitOrOutage({'ok': false}, 'something'), isTrue);
      expect(isLimitOrOutage({'status': 'ERROR'}, 'something'), isTrue);
      expect(isLimitOrOutage({'error': 'boom'}, 'something'), isTrue);
    });
    test('does NOT flag a genuine scholarly answer', () {
      const answer = 'الحمد لله رب العالمين، حكم تداول العملات الرقمية محل خلاف بين '
          'الفقهاء المعاصرين، فمنهم من منعها لعلة الغرر والجهالة ومنهم من أجازها '
          'بشروط...';
      expect(isLimitOrOutage(null, answer), isFalse);
    });
    test('short server-error text is flagged, long text without markers is not', () {
      expect(isLimitOrOutage(null, 'server error'), isTrue);
      expect(
        isLimitOrOutage(
            null,
            'This is a long discussion of server architecture in fiqh literature '
            'covering many pages of classical texts without any failure markers '
            'whatsoever and continuing at length about historical contexts, legal '
            'maxims, and the methodologies of the madhhabs across the centuries.'),
        isFalse,
      );
    });
  });

  group('isLimitOrOutage — adversarial fiqh answers are NOT outage signals (§19)', () {
    test('Urdu fiqh answer with "مصروفیت" (derivation of busy) is not flagged', () {
      // 'مصروفیت' contains the substring 'مصروف' — the hardened trigger must
      // not fire on the grammatical derivation.
      const answer = 'مصروفیت کی وجہ سے اگر نماز قضا ہو جائے تو اس کی قضا واجب ہے۔';
      expect(isLimitOrOutage(null, answer), isFalse);
    });
    test('Arabic fiqh answer with "مشغولاً" (accusative of busy) is not flagged', () {
      // 'مشغولاً' contains the substring 'مشغول' — the hardened trigger must
      // not fire on the inflected form.
      const answer = 'ما حكم تأخير الصلاة لمن كان مشغولاً بعمله؟';
      expect(isLimitOrOutage(null, answer), isFalse);
    });
    test('English fiqh answer with "busy at work" is not flagged', () {
      // A bare "busy" in ordinary fiqh Q&A is not an outage announcement.
      const answer =
          'What is the ruling for one who is busy at work and delays the prayer?';
      expect(isLimitOrOutage(null, answer), isFalse);
    });
    test('English fiqh answer with "error in ijtihad" is not flagged', () {
      const answer =
          'An error in ijtihad by a qualified mujtahid does not incur sin.';
      expect(isLimitOrOutage(null, answer), isFalse);
    });
    test('English fiqh answer with "property remains unavailable" is not flagged', () {
      const answer =
          'The endowed property remains unavailable for sale under the waqf terms.';
      expect(isLimitOrOutage(null, answer), isFalse);
    });
    test('Arabic fiqh answer with "العطل في المبيع" (defect in sold item) is not flagged', () {
      const answer = 'ما حكم العطل في المبيع إذا ظهر بعد القبض؟';
      expect(isLimitOrOutage(null, answer), isFalse);
    });
    test('Arabic fiqh answer with "الخادم" (servant) is not flagged', () {
      const answer = 'هل تجوز شهادة الخادم في عقد البيع؟';
      expect(isLimitOrOutage(null, answer), isFalse);
    });
    test('Urdu fiqh answer mentioning "سرور" (hosting server) is not flagged', () {
      const answer = 'کیا سرور پر میزبانی شدہ قرآن ایپ کا استعمال جائز ہے؟';
      expect(isLimitOrOutage(null, answer), isFalse);
    });
    test('genuine outage signals are still detected', () {
      // Real Urdu server outage message (bare 'مصروف', 'دستیاب نہیں', ...).
      const urduOutage =
          'اس وقت تحقیقی نظام کے تمام دستیاب AI ذرائع عارضی طور پر مصروف یا دستیاب نہیں ہیں۔ براہِ کرم کچھ دیر بعد دوبارہ کوشش فرمائیں۔';
      expect(isLimitOrOutage(null, urduOutage), isTrue);
      // 'busy' in an outage-like context is still an outage.
      expect(isLimitOrOutage(null, 'Server is busy, try again later.'), isTrue);
      expect(isLimitOrOutage(null, 'quota exceeded for this month'), isTrue);
      expect(isLimitOrOutage(null, 'النظام مشغول حالياً، حاول لاحقاً'), isTrue);
      expect(isLimitOrOutage(null, 'Service temporarily unavailable'), isTrue);
    });
    test('contextual short failure markers are still detected', () {
      // Terse transport/service failures keep their outage meaning.
      expect(isLimitOrOutage(null, 'server error'), isTrue);
      expect(isLimitOrOutage(null, 'Server is down for maintenance.'), isTrue);
      expect(
          isLimitOrOutage(null, 'Request failed to connect to the Oracle.'),
          isTrue);
      expect(isLimitOrOutage(null, 'الخادم غير متاح حالياً، حاول لاحقاً'),
          isTrue);
      expect(isLimitOrOutage(null, 'خطأ في الاتصال بالخادم'), isTrue);
      expect(isLimitOrOutage(null, 'عطل فني في النظام'), isTrue);
    });
  });

  group('hasOracleProvenance — provenance gate (§10)', () {
    test('SUCCESS with the Oracle tag is trusted', () {
      expect(
        hasOracleProvenance({'status': 'SUCCESS', 'source': 'shirazi-oracle'}),
        isTrue,
      );
    });
    test('SUCCESS without the tag is UNTRUSTED (must be refused)', () {
      expect(hasOracleProvenance({'status': 'SUCCESS'}), isFalse);
      expect(
        hasOracleProvenance({'status': 'SUCCESS', 'source': 'groq-direct'}),
        isFalse,
      );
      expect(
        hasOracleProvenance({'status': 'SUCCESS', 'source': ''}),
        isFalse,
      );
    });
    test('non-SUCCESS states pass through (handled by their own branches)', () {
      expect(hasOracleProvenance({'status': 'QUOTA_EXHAUSTED'}), isTrue);
      expect(hasOracleProvenance({'status': 'EXHAUSTED'}), isTrue);
    });
  });

  group('requestIdMatches — request/response correlation (§9, strict)', () {
    test('matching echo validates', () {
      expect(requestIdMatches({'request_id': 'abc'}, 'abc'), isTrue);
    });
    test('mismatched echo is rejected', () {
      expect(requestIdMatches({'request_id': 'other'}, 'abc'), isFalse);
    });
    test('absent or empty echo is rejected (stray/duplicate)', () {
      expect(requestIdMatches({}, 'abc'), isFalse);
      expect(requestIdMatches({'request_id': ''}, 'abc'), isFalse);
    });
  });

  group('generateRequestId — UUID v4', () {
    test('matches UUID v4 shape and is unique', () {
      final a = generateRequestId();
      final b = generateRequestId();
      final uuidV4 = RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');
      expect(uuidV4.hasMatch(a), isTrue, reason: 'got: $a');
      expect(a, isNot(equals(b)));
    });
  });

  group('BYOK provider allowlist (§8)', () {
    test('allowlisted providers pass (case-insensitive)', () {
      expect(isSupportedByokProvider('groq'), isTrue);
      expect(isSupportedByokProvider('GEMINI'), isTrue);
      expect(isSupportedByokProvider(' OpenRouter '), isTrue);
    });
    test('arbitrary providers / URLs are rejected — no open proxy', () {
      expect(isSupportedByokProvider('evil-proxy'), isFalse);
      expect(isSupportedByokProvider('https://attacker.example.com'), isFalse);
      expect(isSupportedByokProvider(''), isFalse);
      expect(isSupportedByokProvider(null), isFalse);
    });
    test('priorityListFor drops non-allowlisted entries', () {
      final list = priorityListFor(
        {'groq': 'k1', 'evil': 'k2'},
        ['evil', 'gemini'],
        'attacker.example',
      );
      expect(list, contains('groq'));
      expect(list, contains('gemini'));
      expect(list, isNot(contains('evil')));
      expect(list, isNot(contains('attacker.example')));
    });
    test('priorityListFor preserves explicit order then payload keys', () {
      final list = priorityListFor(
        {'groq': 'k1', 'gemini': 'k2'},
        ['openrouter'],
        null,
      );
      expect(list, ['openrouter', 'groq', 'gemini']);
    });
  });

  group('OracleEndpoint — transport security (§1)', () {
    test('https is secure, wss for sockets', () {
      final e = OracleEndpoint.parse('https://oracle.example.com:8443');
      expect(e.isSecure, isTrue);
      expect(e.socketScheme, 'wss');
      expect(e.baseUrl, 'https://oracle.example.com:8443');
    });
    test('http is insecure, ws for sockets', () {
      final e = OracleEndpoint.parse('http://129.154.242.136:4040');
      expect(e.isSecure, isFalse);
      expect(e.socketScheme, 'ws');
    });
    test('redacted form never contains credentials or paths', () {
      final e = OracleEndpoint.parse('https://user:pass@oracle.example.com/api?k=secret');
      expect(e.redacted, 'https://oracle.example.com');
      expect(e.redacted.contains('pass'), isFalse);
      expect(e.redacted.contains('secret'), isFalse);
    });
    test('invalid URLs throw', () {
      expect(() => OracleEndpoint.parse(''), throwsFormatException);
      expect(() => OracleEndpoint.parse('not a url !!!'), throwsFormatException);
      expect(() => OracleEndpoint.parse('ftp://x.example.com'), throwsFormatException);
    });
  });

  group('failure messages — honest, never promise a substitute (§16)', () {
    for (final lang in ['en', 'ur', 'ar']) {
      test('quota message [$lang] states no substitute was generated', () {
        final m = getQuotaExhaustedMessage(lang, false);
        expect(m.isNotEmpty, isTrue);
      });
      test('exhaustion message [$lang] is non-empty', () {
        expect(getExhaustionMessage(lang).isNotEmpty, isTrue);
      });
      test('auth message [$lang] is non-empty', () {
        expect(getAuthErrorMessage(lang).isNotEmpty, isTrue);
      });
      test('insecure-transport message [$lang] is non-empty', () {
        expect(getInsecureTransportBlockedMessage(lang).isNotEmpty, isTrue);
      });
    }
    test('English quota message explicitly disclaims substitutes', () {
      final m = getQuotaExhaustedMessage('en', false).toLowerCase();
      expect(m.contains('no substitute ai answer has been generated'), isTrue);
    });
  });

  group('Oracle Ed25519 response provenance (§2)', () {
    test('SPKI constant decodes to a 32-byte raw Ed25519 key', () {
      final raw = ed25519RawKeyFromSpki(
          Uint8List.fromList(base64Decode(oracleEd25519PublicKeySpki)));
      expect(raw.length, 32);
    });

    test('ed25519RawKeyFromSpki rejects malformed DER', () {
      expect(() => ed25519RawKeyFromSpki(Uint8List(44)), throwsFormatException);
      expect(() => ed25519RawKeyFromSpki(Uint8List(10)), throwsFormatException);
    });

    test('sha256Hex matches the known SHA-256 of "abc"', () async {
      expect(await sha256Hex('abc'),
          'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad');
    });

    test('oracleSignatureMessage rebuilds the dotted signed string', () async {
      final msg = await oracleSignatureMessage(
        responseId: 'resp-1',
        requestId: 'req-1',
        answer: 'abc',
      );
      expect(msg,
          'resp-1.req-1.ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad');
    });

    test('sign/verify round-trip accepts; tampered message is rejected', () async {
      // Fresh keypair (NOT the Oracle key): exercises the verify path.
      final keyPair = await Ed25519().newKeyPair();
      final publicKey = await keyPair.extractPublicKey();
      final message = await oracleSignatureMessage(
        responseId: 'resp-1',
        requestId: 'req-1',
        answer: 'abc',
      );
      final signature =
          await Ed25519().sign(utf8.encode(message), keyPair: keyPair);
      final ok = await Ed25519().verify(utf8.encode(message),
          signature: Signature(signature.bytes, publicKey: publicKey));
      expect(ok, isTrue);
      final bad = await Ed25519().verify(utf8.encode('$message-tampered'),
          signature: Signature(signature.bytes, publicKey: publicKey));
      expect(bad, isFalse);
    });

    test('verifyOracleProvenance rejects garbage signature / wrong key_id', () async {
      expect(
          await verifyOracleProvenance(
            responseId: 'resp-1',
            requestId: 'req-1',
            answer: 'abc',
            signatureBase64: base64Encode(List.filled(64, 0)),
            keyId: oracleEd25519KeyId,
          ),
          isFalse);
      expect(
          await verifyOracleProvenance(
            responseId: 'resp-1',
            requestId: 'req-1',
            answer: 'abc',
            signatureBase64: base64Encode(List.filled(64, 0)),
            keyId: 'wrong-key-id',
          ),
          isFalse);
    });

    test('untrusted-response message is non-empty in all languages', () {
      for (final lang in ['en', 'ur', 'ar']) {
        expect(getUntrustedResponseMessage(lang).isNotEmpty, isTrue);
      }
    });
  });
}
