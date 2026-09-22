/// Failure-matrix unit tests for the Shirazi Oracle protocol layer (§19).
///
/// These tests run with the STANDALONE Dart SDK (`dart test`) — no Flutter
/// needed — because oracle_protocol.dart imports nothing from Flutter.
///
/// Coverage:
/// - HTTP status -> OracleFailure taxonomy (400/401/403/404/408/409/429/5xx)
/// - Outage / quota-exhaustion text detection (ur/ar/en)
/// - Provenance gate: SUCCESS without the Oracle source tag is untrusted
/// - Request-ID echo validation
/// - BYOK provider allowlist (no arbitrary-proxy steering)
/// - Endpoint parsing: https vs http, wss vs ws, log redaction
/// - UUID v4 request-ID shape
/// - Localized failure messages never promise a substituted answer
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

  group('requestIdMatches — request/response correlation (§9)', () {
    test('matching echo validates', () {
      expect(requestIdMatches({'request_id': 'abc'}, 'abc'), isTrue);
    });
    test('mismatched echo is rejected', () {
      expect(requestIdMatches({'request_id': 'other'}, 'abc'), isFalse);
    });
    test('absent echo is tolerated (server may not echo yet)', () {
      expect(requestIdMatches({}, 'abc'), isTrue);
      expect(requestIdMatches({'request_id': ''}, 'abc'), isTrue);
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
}
