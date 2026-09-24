import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/inquiry.dart';
import '../models/provider_health.dart';
import 'fiqh_query_analyzer.dart';
import 'oracle_protocol.dart' as proto;

class KeyValidationResult {
  final bool isValid;
  final String message;
  final int? statusCode;

  const KeyValidationResult({
    required this.isValid,
    required this.message,
    this.statusCode,
  });
}

class ApiService {
  final String baseUrl;

  /// Parsed endpoint with transport-security helpers.
  late final proto.OracleEndpoint endpoint;

  /// Provides a Firebase ID token for Oracle authentication (socket auth +
  /// HTTP Authorization header). May be null when signed out.
  final Future<String?> Function()? authTokenProvider;

  /// Debug-only insecure-transport override. Release builds NEVER transmit
  /// user keys over plain HTTP. In debug builds, integration tests or a
  /// local dev server may opt in explicitly via [debugAllowInsecureHttp].
  /// There is intentionally no UI for this — it must never be shippable.
  static bool _debugAllowInsecureHttp = false;

  /// Test/debug hook: allow user-key transmission over plain HTTP in DEBUG
  /// builds only. Ignored in release builds. Never expose this in UI.
  @visibleForTesting
  static set debugAllowInsecureHttp(bool value) {
    _debugAllowInsecureHttp = value;
  }

  static bool get _insecureOverrideAllowed {
    if (!kDebugMode) return false;
    return _debugAllowInsecureHttp;
  }

  /// In-flight Socket.IO queries, keyed by request_id, so the UI can cancel
  /// them: emits the server's `cancel` event, then tears down the socket,
  /// the 150 s timer, and the progress stream.
  final Map<String, IO.Socket> _activeSockets = {};
  final Map<String, Completer<Map<String, dynamic>>> _activeCompleters = {};

  ApiService({
    // Production Oracle default (hardened Socket.IO server). Release builds
    // must resolve the URL from the persisted production config
    // (StorageService.serverUrl); this fallback must never point at a stale
    // dev address.
    this.baseUrl = 'https://shirazi-oracle.140-238-250-139.sslip.io',
    this.authTokenProvider,
  }) {
    endpoint = proto.OracleEndpoint.parse(baseUrl);
  }

  /// True when the configured Oracle uses HTTPS (production requirement).
  bool get isSecureTransport => endpoint.isSecure;

  /// Log-safe endpoint label — never contains credentials.
  String get redactedEndpoint => endpoint.redacted;

  /// Authenticated headers for Oracle HTTP routes. The hardened Oracle
  /// requires a Firebase ID token on every non-/api/health route and 401s
  /// without one. Returns an empty map when signed out — the call then 401s
  /// and the caller must surface an honest auth error, never fail silently.
  Future<Map<String, String>> _authHeaders() async {
    try {
      final idToken = await authTokenProvider?.call();
      if (idToken != null && idToken.isNotEmpty) {
        return {'Authorization': 'Bearer $idToken'};
      }
    } catch (e) {
      debugPrint('[ApiService] auth token fetch failed: $e');
    }
    return {};
  }

  /// True when a socket/transport error looks like an Oracle authentication
  /// rejection (missing, invalid, or expired Firebase ID token). Used to
  /// route auth failures to the sign-in nudge instead of generic errors.
  static bool _isAuthRejection(dynamic err) {
    final s = err?.toString().toLowerCase() ?? '';
    if (s.contains('401') || s.contains('unauthorized')) return true;
    final hasAuthWord = s.contains('auth') ||
        s.contains('token') ||
        s.contains('jwt') ||
        s.contains('forbidden') ||
        s.contains('403');
    final hasNegativeWord = s.contains('invalid') ||
        s.contains('expired') ||
        s.contains('reject') ||
        s.contains('denied') ||
        s.contains('missing');
    return hasAuthWord && hasNegativeWord;
  }

  /// Strips extraneous quotes, trailing spaces, newlines, and Bearer prefix
  static String sanitizeApiKey(String key) {
    return key
        .replaceAll(RegExp(r'''["'\s]'''), '')
        .replaceAll(RegExp(r'^Bearer\s*', caseSensitive: false), '')
        .trim();
  }

  /// Probes server connectivity and returns latency in milliseconds
  Future<int?> checkServerLatency() async {
    try {
      final sw = Stopwatch()..start();
      final res = await http.get(
        Uri.parse('$baseUrl/api/health'),
      ).timeout(const Duration(seconds: 4));
      sw.stop();
      if (res.statusCode == 200) {
        return sw.elapsedMilliseconds;
      }
    } catch (_) {}
    return null;
  }

  /// Fetches comprehensive server health, gateway status, and channel readiness
  Future<Map<String, dynamic>?> fetchServerHealth() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/health'),
      ).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  /// Fetches real-time fatwas and scholarly inquiries from the Shirazi core queue
  Future<List<Inquiry>> fetchRealtimeFatwas({
    String? statusFilter,
    bool fetchFullDetails = false,
  }) async {
    try {
      final queryParam = (statusFilter != null && statusFilter.isNotEmpty && statusFilter != 'All')
          ? '?status=${statusFilter.toLowerCase()}'
          : '';
      final res = await http.get(
        Uri.parse('$baseUrl/api/scholar/fatwas$queryParam'),
        headers: await _authHeaders(),
      ).timeout(const Duration(seconds: 12));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final list = (data['fatwas'] as List? ?? []);
        final fatwas = list.map((item) => Inquiry.fromBackendFatwa(item as Map<String, dynamic>)).toList();

        if (fetchFullDetails && fatwas.isNotEmpty) {
          final detailedList = await Future.wait(
            fatwas.map((f) async {
              try {
                final detail = await fetchFatwaDetail(f.id);
                return detail ?? f;
              } catch (_) {
                return f;
              }
            }),
          );
          return detailedList;
        }

        return fatwas;
      }
    } catch (e) {
      debugPrint('Error fetching real-time fatwas: $e');
    }
    return [];
  }

  /// Fetches single fatwa details including complete classical citations and audit trail
  Future<Inquiry?> fetchFatwaDetail(String id) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/scholar/fatwa/$id'),
        headers: await _authHeaders(),
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['ok'] == true && data['fatwa'] != null) {
          return Inquiry.fromBackendFatwa(data['fatwa'] as Map<String, dynamic>);
        }
      }
    } catch (e) {
      debugPrint('Error fetching fatwa detail $id: $e');
    }
    return null;
  }

  /// Sends a research query to the live Shirazi Gateway/Core via Socket.IO
  /// real-time stream. Socket.IO is the single canonical transport — there
  /// is no HTTP chat endpoint on the hardened Oracle.
  Future<Map<String, dynamic>> streamRealtimeQuery({
    required String text,
    required String persona,
    required String lang,
    String? madhhab,
    String? byokKey,
    String? byokProvider,
    Map<String, String>? fallbackKeys,
    List<String>? providerPriority,
    String? answerMode,
    void Function(String progressMessage)? onProgress,
    // Called with the generated request_id so the caller (e.g. ChatProvider)
    // can cancel this exact query via [cancelQuery].
    void Function(String requestId)? onRequestId,
  }) async {
    final completer = Completer<Map<String, dynamic>>();

    IO.Socket? socket;
    Timer? timeoutTimer;

    // Client-generated UUID v4 for end-to-end tracing (§9):
    // app -> Oracle API -> research pipeline -> AI provider -> response -> app.
    final requestId = proto.generateRequestId();
    onRequestId?.call(requestId);
    final socketStopwatch = Stopwatch()..start();

    // Canonical Oracle BYOK contract: [{provider, key}]. The server also
    // accepts the legacy {provider: key} map, but new builds send the list.
    final userKeysPayload = <Map<String, String>>[];
    void addKey(String provider, String key) {
      final p = provider.trim().toLowerCase();
      if (key.trim().isEmpty) return;
      if (proto.isSupportedByokProvider(p)) {
        userKeysPayload.add({'provider': p, 'key': key.trim()});
      } else {
        debugPrint('[ApiService] Rejected non-allowlisted BYOK provider: $p');
      }
    }
    if (byokProvider != null && byokKey != null) {
      addKey(byokProvider, byokKey);
    }
    if (fallbackKeys != null) {
      fallbackKeys.forEach((k, v) => addKey(k, v));
    }

    // ── HTTPS enforcement (§1, §5) ──────────────────────────────────────
    // User API keys must NEVER travel over plain HTTP. If the Oracle endpoint
    // is not HTTPS and the development override is off, we refuse to transmit
    // the keys at all and return an honest, localized blocked state.
    if (userKeysPayload.isNotEmpty &&
        !endpoint.isSecure &&
        !_insecureOverrideAllowed) {
      debugPrint(
          '[ApiService] BLOCKED: refusing to transmit user keys over insecure transport '
          '(${endpoint.redacted}). Enable HTTPS on the Oracle server.');
      return _oracleErrorResult(
        requestId: requestId,
        transport: 'none',
        message: proto.getInsecureTransportBlockedMessage(lang),
        failure: proto.OracleFailure.insecureTransportBlocked,
      );
    }
    if (!endpoint.isSecure) {
      debugPrint(
          '[ApiService] WARNING: Oracle transport is insecure HTTP '
          '(${endpoint.redacted}). Questions are not TLS-protected.');
    }

    try {
      // Socket.IO authentication (§11): attach the Firebase ID token when
      // signed in. The server must verify it and derive user identity from
      // it — never trust client-provided userId/role fields.
      final idToken = await authTokenProvider?.call();
      final builder = IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableForceNew()
          .setTimeout(10000);
      if (idToken != null && idToken.isNotEmpty) {
        builder.setAuth({'token': idToken});
      }
      socket = IO.io(endpoint.baseUrl, builder.build());
      // Track the in-flight query so [cancelQuery] can reach it.
      _activeSockets[requestId] = socket;
      _activeCompleters[requestId] = completer;

      socket.onConnect((_) {
        socket!.emit('chat', {
          'request_id': requestId,
          'text': text,
          'persona': persona,
          'lang': lang,
          'madhhab': madhhab,
          'answer_mode': answerMode,
          'user_keys': userKeysPayload,
          'provider_priority':
              proto.priorityListFor(userKeysPayload, providerPriority, byokProvider),
          'channel': 'mobile_app',
        });
      });

      socket.on('agent-progress', (data) {
        String msg = '';
        if (data is Map && data['message'] != null) {
          msg = data['message'].toString();
        } else if (data is String) {
          msg = data;
        }
        if (msg.isNotEmpty && onProgress != null) {
          onProgress(msg);
        }
      });

      socket.on('assistant-message', (data) async {
        if (completer.isCompleted) return;

        String answer = '';
        List<String> citations = [];
        String? echoedRequestId;
        Map<String, dynamic>? provenance;
        if (data is Map) {
          answer = data['answer']?.toString() ?? '';
          final rawCitations = data['citations'];
          if (rawCitations is List) {
            citations = rawCitations.map((c) => c.toString()).toList();
          }
          echoedRequestId = data['request_id']?.toString();
          final prov = data['provenance'];
          if (prov is Map) {
            provenance = Map<String, dynamic>.from(prov);
          }
        } else if (data is String) {
          answer = data;
        }

        // §9 (strict): the hardened Oracle always echoes request_id. A
        // message whose request_id is missing or foreign is stray/duplicate
        // and must be ignored — never treated as our answer.
        if (!proto.requestIdMatches(
            {'request_id': echoedRequestId}, requestId)) {
          debugPrint(
              '[ApiService] Ignoring assistant-message with missing/foreign request_id (stray response).');
          return;
        }

        // Pure, unit-tested outage detector (oracle_protocol).
        final isOutage =
            proto.isLimitOrOutage(data is Map ? data : null, answer);
        final isMadhhabMismatch = madhhab != null && madhhab.isNotEmpty
            ? MadhhabDetector.isMismatched(answer, madhhab)
            : false;

        if (isMadhhabMismatch) {
          debugPrint('[ApiService] Server cached answer rejected: madhhab mismatch (requested $madhhab).');
          completer.completeError('Server returned answer with madhhab mismatch (requested $madhhab)');
          return;
        }

        if (isOutage) {
          // The Oracle's research pipeline ran but its inference capacity is
          // exhausted (status:'ERROR' + QUOTA_EXHAUSTED, or the dedicated
          // 'quota-exhausted' event below). This is NOT answered by any
          // other AI: we surface a structured quota state so the UI can
          // offer an explicit, consent-based retry THROUGH the Oracle with
          // the user's key.
          completer.complete(_quotaExhaustedResult(
            requestId: requestId,
            transport: 'socket.io',
            oracleKeysUsed: userKeysPayload.isNotEmpty,
            latencyMs: socketStopwatch.elapsedMilliseconds,
            retryAfterHint:
                data is Map ? data['retry_after_hint']?.toString() : null,
            canUseByok: data is Map ? _asBool(data['can_use_byok']) : null,
          ));
          return;
        }

        if (answer.isEmpty) return; // keep waiting for the real answer

        // ── Response provenance (§2) ─────────────────────────────────
        // The hardened Oracle signs every answer with Ed25519 over
        // `${response_id}.${request_id}.${sha256hex(answer)}`. An answer
        // that fails verification — or carries no signature in a release
        // build — is untrusted: it is discarded and never displayed.
        final signature = provenance?['signature']?.toString();
        final responseId = provenance?['response_id']?.toString();
        final keyId = provenance?['key_id']?.toString();
        final signatureOk = signature != null &&
                signature.isNotEmpty &&
                responseId != null &&
                responseId.isNotEmpty
            ? await proto.verifyOracleProvenance(
                responseId: responseId,
                requestId: requestId,
                answer: answer,
                signatureBase64: signature,
                keyId: keyId,
              )
            : false;
        if (!signatureOk) {
          if (signature == null && kDebugMode) {
            // Local-dev only: unsigned Oracle responses are accepted with a
            // loud log so the UI can be exercised against a dev server.
            debugPrint(
                '[ApiService] DEBUG build: accepting unsigned assistant-message (release builds reject it).');
          } else {
            debugPrint(
                '[ApiService] REJECTED untrusted assistant-message (signature ${signature == null ? 'missing' : 'invalid'}).');
            completer.complete(_oracleErrorResult(
              requestId: requestId,
              transport: 'socket.io',
              message: proto.getUntrustedResponseMessage(lang),
              failure: proto.OracleFailure.untrustedResponse,
            ));
            return;
          }
        }

        completer.complete({
          'status': 'SUCCESS',
          // ── Server identity / provenance (§2) ──────────────────────
          // The answer's authenticity is established by the Ed25519
          // signature verified above (response_id + request_id + answer
          // digest), signed by the Oracle key shirazi-oracle-2026-09-24.
          // These fields are the client-observed transport provenance of
          // that verified answer; nothing is fabricated here.
          'source': 'shirazi-oracle',
          'request_id': requestId,
          'response_id': responseId,
          'provenance_verified': signatureOk,
          'transport': 'socket.io',
          'oracle_url': baseUrl,
          'answered_at': DateTime.now().toUtc().toIso8601String(),
          'latency_ms': socketStopwatch.elapsedMilliseconds,
          // ──────────────────────────────────────────────────────────
          'answer': answer,
          'citations': citations,
          'isRealtimeStream': true,
          'byokProvider': 'Shirazi Core Agent (Live)',
          'isByokFallback': false,
        });
      });

      // Quota exhaustion (hardened protocol): the server emits
      // 'quota-exhausted' {status:'QUOTA_EXHAUSTED', request_id,
      // retry_after_hint, can_use_byok}. Mapped to the same structured
      // result as the in-band quota shape above.
      socket.on('quota-exhausted', (data) {
        if (!completer.isCompleted) {
          String? hint;
          bool? byok;
          if (data is Map) {
            hint = data['retry_after_hint']?.toString();
            byok = _asBool(data['can_use_byok']);
          }
          debugPrint('[ApiService] Oracle quota exhausted (retry hint: $hint).');
          completer.complete(_quotaExhaustedResult(
            requestId: requestId,
            transport: 'socket.io',
            oracleKeysUsed: userKeysPayload.isNotEmpty,
            latencyMs: socketStopwatch.elapsedMilliseconds,
            retryAfterHint: hint,
            canUseByok: byok,
          ));
        }
      });

      socket.on('chat-error', (err) {
        debugPrint('Socket chat-error received: $err');
        if (!completer.isCompleted) {
          if (_isAuthRejection(err)) {
            // The Oracle rejected our authentication — surface the sign-in
            // nudge, not a generic server error or exhaustion text.
            completer.complete(_oracleErrorResult(
              requestId: requestId,
              transport: 'socket.io',
              message: _getAuthErrorMessage(lang),
              failure: proto.OracleFailure.authRejected,
            ));
          } else {
            completer.completeError('Server chat error: $err');
          }
        }
      });

      socket.on('rate-limit', (err) {
        debugPrint('Socket rate-limit received: $err');
        if (!completer.isCompleted) {
          completer.completeError('Server rate limit reached');
        }
      });

      // Server acknowledgement of our `cancel` emit (§8): the pipeline was
      // stopped. Complete with the structured CANCELLED state.
      socket.on('cancelled', (data) {
        if (!completer.isCompleted) {
          debugPrint('[ApiService] Oracle acknowledged cancellation.');
          completer.complete(_cancelledResult(requestId: requestId));
        }
      });

      socket.onConnectError((err) {
        if (!completer.isCompleted) {
          if (_isAuthRejection(err)) {
            completer.complete(_oracleErrorResult(
              requestId: requestId,
              transport: 'socket.io',
              message: _getAuthErrorMessage(lang),
              failure: proto.OracleFailure.authRejected,
            ));
          } else {
            completer.completeError(err);
          }
        }
      });

      socket.onError((err) {
        if (!completer.isCompleted) {
          if (_isAuthRejection(err)) {
            completer.complete(_oracleErrorResult(
              requestId: requestId,
              transport: 'socket.io',
              message: _getAuthErrorMessage(lang),
              failure: proto.OracleFailure.authRejected,
            ));
          } else {
            completer.completeError(err);
          }
        }
      });

      socket.connect();

      // Research-realistic timeout: the Oracle's research pipeline (retrieval
      // across Shamela sources + verification + synthesis) takes 30-90s on a
      // healthy server. Progress events keep the UI alive while we wait.
      // We do NOT time out early and we NEVER cascade to a direct client-side
      // AI call: every answer must come from the Shirazi Oracle Server.
      const maxWaitSeconds = 150;
      timeoutTimer = Timer(const Duration(seconds: maxWaitSeconds), () {
        if (!completer.isCompleted) {
          completer.completeError(TimeoutException('Shirazi Oracle response timed out after ${maxWaitSeconds}s'));
        }
      });

      final result = await completer.future;
      timeoutTimer.cancel();
      socket.disconnect();
      socket.dispose();
      return result;
    } catch (e) {
      debugPrint('[ApiService] Shirazi Oracle socket attempt failed: $e. Falling back to verified fatwa library probe...');
    } finally {
      timeoutTimer?.cancel();
      _activeSockets.remove(requestId);
      _activeCompleters.remove(requestId);
      try {
        socket?.disconnect();
        socket?.dispose();
      } catch (_) {}
    }


    // REMOVED (old Step 2): HTTP POST to `$baseUrl/api/chat` — the hardened
    // Oracle exposes NO HTTP chat route (it 404s). Socket.IO is the single
    // canonical transport; per the hardening plan the fallback is removed,
    // not redirected to an invented server endpoint.

    // REMOVED (Step 2b): _executeDirectClientByok — the old direct client-side
    // calls to Groq / Gemini / OpenRouter REST APIs. That path answered the
    // user's question with a generic AI model and a hand-written system prompt,
    // completely bypassing the Shirazi research / retrieval / verification
    // pipeline. It violated the core product requirement and has been deleted.
    // User keys are now ONLY ever sent to the Shirazi Oracle Server, which
    // runs its own pipeline with them for inference (§7).

    // Step 2: Probe server's canonical fatwa library for matching verified inquiry
    final target = FiqhQueryAnalyzer.analyze(text, lang: lang).copyWith(
      requestedMadhhab: madhhab,
    );
    final serverFatwa = await _searchServerFatwas(
      text: text,
      lang: lang,
      madhhab: madhhab,
      researchTarget: target,
    );
    if (serverFatwa != null) {
      return serverFatwa;
    }

    // Step 3: Graceful Failure Protocol (Requirement 6: Never fabricate an answer)
    // The Oracle could not answer and no verified cached fatwa matched. We
    // return an honest, localized exhaustion notice — NEVER a substituted AI
    // answer. The user's question is preserved for retry.
    final exhaustionMsg = getExhaustionMessage(lang);
    return {
      'status': 'EXHAUSTED',
      'request_id': requestId,
      'oracle_url': baseUrl,
      'answered_at': DateTime.now().toUtc().toIso8601String(),
      'error': exhaustionMsg,
      'answer': exhaustionMsg,
      'isExhausted': true,
      'canRetry': true,
      'citations': <String>[],
      'byokProvider': null,
      'isByokFallback': false,
    };
  }

  /// Cancels an in-flight Socket.IO query (§8). Emits the server's `cancel`
  /// event with the active request_id, then tears down the local socket —
  /// which also stops the 150 s research timer and the progress stream —
  /// completing the pending result with a structured CANCELLED state.
  /// Safe to call when nothing is in flight (no-op).
  Future<void> cancelQuery(String requestId) async {
    final socket = _activeSockets.remove(requestId);
    final completer = _activeCompleters.remove(requestId);
    if (socket != null) {
      try {
        socket.emit('cancel', {'request_id': requestId});
      } catch (_) {}
      try {
        socket.disconnect();
        socket.dispose();
      } catch (_) {}
      debugPrint('[ApiService] Cancelled in-flight query $requestId.');
    }
    if (completer != null && !completer.isCompleted) {
      completer.complete(_cancelledResult(requestId: requestId));
    }
  }

  /// Structured cancellation result. The user stopped the query before the
  /// Oracle answered; the question is preserved for retry — never replaced
  /// by a fabricated answer.
  Map<String, dynamic> _cancelledResult({required String requestId}) {
    return {
      'status': 'CANCELLED',
      'source': 'shirazi-oracle',
      'request_id': requestId,
      'transport': 'socket.io',
      'oracle_url': baseUrl,
      'answered_at': DateTime.now().toUtc().toIso8601String(),
      'answer': '',
      'citations': <String>[],
      'isRealtimeStream': true,
      'canRetry': true,
      'isByokFallback': false,
      'byokProvider': null,
    };
  }

  /// Builds the ordered provider-priority list for a server-side BYOK request.
  /// Delegates to the pure, unit-tested implementation in oracle_protocol.
  static List<String> priorityListFor(
    List<Map<String, String>> userKeysPayload,
    List<String>? providerPriority,
    String? byokProvider,
  ) =>
      proto.priorityListFor(userKeysPayload, providerPriority, byokProvider);

  /// Structured quota-exhaustion result. The Oracle ran but its inference
  /// capacity is spent. No answer is fabricated; the UI offers an explicit,
  /// consent-based retry through the Oracle pipeline.
  ///
  /// [retryAfterHint] and [canUseByok] come from the server's
  /// `quota-exhausted` event (or the in-band quota payload) when present.
  Map<String, dynamic> _quotaExhaustedResult({
    required String requestId,
    required String transport,
    required bool oracleKeysUsed,
    int? latencyMs,
    String? retryAfterHint,
    bool? canUseByok,
  }) {
    final canRetryWithByok = !oracleKeysUsed && (canUseByok ?? true);
    final result = <String, dynamic>{
      'status': 'QUOTA_EXHAUSTED',
      'source': 'shirazi-oracle',
      'request_id': requestId,
      'transport': transport,
      'oracle_url': baseUrl,
      'answered_at': DateTime.now().toUtc().toIso8601String(),
      'answer': '',
      'citations': <String>[],
      'isRealtimeStream': true,
      'oracle_keys_used': oracleKeysUsed,
      'canRetry': true,
      'canRetryWithByok': canRetryWithByok,
      'isByokFallback': false,
      'byokProvider': null,
    };
    if (latencyMs != null) {
      result['latency_ms'] = latencyMs;
    }
    if (retryAfterHint != null && retryAfterHint.isNotEmpty) {
      result['retry_after_hint'] = retryAfterHint;
    }
    if (canUseByok != null) {
      // Server's hint: a personal BYOK key would work for this request.
      result['can_use_byok'] = canUseByok;
    }
    return result;
  }

  /// Lenient bool coercion for server payload fields (bool or "true"/"false").
  static bool? _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) {
      final s = value.trim().toLowerCase();
      if (s == 'true') return true;
      if (s == 'false') return false;
    }
    return null;
  }

  /// Structured Oracle error result (auth rejection, server error, ...).
  Map<String, dynamic> _oracleErrorResult({
    required String requestId,
    required String transport,
    required String message,
    proto.OracleFailure? failure,
  }) {
    return {
      'status': 'EXHAUSTED',
      'source': 'shirazi-oracle',
      'request_id': requestId,
      'transport': transport,
      'oracle_url': baseUrl,
      'failure': failure?.name,
      'answered_at': DateTime.now().toUtc().toIso8601String(),
      'error': message,
      'answer': message,
      'isExhausted': true,
      'canRetry': true,
      'citations': <String>[],
      'byokProvider': null,
      'isByokFallback': false,
    };
  }

  /// Localized notice for Oracle inference-quota exhaustion.
  /// [oracleKeysUsed] tells whether the user's personal key was already routed
  /// through the Shirazi pipeline for this question.
  static String getQuotaExhaustedMessage(String lang, bool oracleKeysUsed) =>
      proto.getQuotaExhaustedMessage(lang, oracleKeysUsed);

  /// Localized notice for Oracle authentication rejection.
  static String _getAuthErrorMessage(String lang) =>
      proto.getAuthErrorMessage(lang);

  /// Localized notice for a user-cancelled query.
  static String getCancelledMessage(String lang) =>
      proto.getCancelledMessage(lang);

  /// Localized exhaustion error notice preserving question for 1-tap retry
  static String getExhaustionMessage(String lang) =>
      proto.getExhaustionMessage(lang);

  /// Searches the server's live fatwa queue using topic entity matching and strict madhhab filtering.
  /// Uses RelevanceGuard.entityMatch() and MadhhabDetector to ensure that questions
  /// asked under one madhhab (e.g. Hanafi) are NEVER answered with cached fatwas
  /// of another madhhab (e.g. Maliki).
  Future<Map<String, dynamic>?> _searchServerFatwas({
    required String text,
    required String lang,
    String? madhhab,
    ResearchTarget? researchTarget,
  }) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/scholar/fatwas'),
        headers: await _authHeaders(),
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final fatwas = data['fatwas'] as List? ?? [];
        if (fatwas.isNotEmpty) {
          final target = researchTarget ??
              FiqhQueryAnalyzer.analyze(text, lang: lang).copyWith(requestedMadhhab: madhhab);

          Map<String, dynamic>? bestMatch;

          for (final f in fatwas) {
            final q = (f['original_question'] ?? f['question_ar'] ?? '').toString();
            final fMadhhab = (f['madhhab'] ?? '').toString().trim();

            // ── Madhhab Guard: STRICT isolation ─────────────────────────
            // If the user selected Hanafi, NEVER return a Maliki/Shafi'i/Hanbali fatwa!
            if (madhhab != null && madhhab.isNotEmpty) {
              if (fMadhhab.isNotEmpty && !MadhhabDetector.isCompatible(fMadhhab, madhhab)) {
                debugPrint('[RelevanceGuard] Rejected fatwa (madhhab mismatch: expected $madhhab, got $fMadhhab)');
                continue;
              }
              if (MadhhabDetector.isMismatched(q, madhhab)) {
                debugPrint('[RelevanceGuard] Rejected fatwa (question madhhab tag mismatch for $madhhab)');
                continue;
              }
            }

            // ── Rule 13: Entity match guard ────────────────────────────────
            // A fatwa is only a candidate if its question actually discusses
            // the same named topic as the user's question. Generic word
            // overlap (حکم, حلال, etc.) is NOT sufficient.
            if (!RelevanceGuard.entityMatch(q, target)) {
              debugPrint('[RelevanceGuard] Rejected fatwa (entity mismatch): '
                  '"${q.substring(0, q.length.clamp(0, 60))}"');
              continue;
            }

            bestMatch = f as Map<String, dynamic>;
            break; // First entity-matched AND madhhab-compatible fatwa
          }

          if (bestMatch != null && bestMatch['id'] != null) {
            final detail = await fetchFatwaDetail(bestMatch['id'].toString());
            if (detail != null && detail.scholarlyAnswerArabic.trim().isNotEmpty) {
              // Final check on detail madhhab and content relevance
              if (madhhab != null && madhhab.isNotEmpty) {
                if (detail.madhhab.isNotEmpty && !MadhhabDetector.isCompatible(detail.madhhab, madhhab)) {
                  debugPrint('[RelevanceGuard] Detail rejected: madhhab mismatch (${detail.madhhab} != $madhhab)');
                  return null;
                }
                if (MadhhabDetector.isMismatched(detail.scholarlyAnswerArabic, madhhab)) {
                  debugPrint('[RelevanceGuard] Detail answer rejected: content madhhab mismatch for $madhhab');
                  return null;
                }
              }

              if (!RelevanceGuard.isRelevant(
                    detail.scholarlyAnswerArabic, target)) {
                debugPrint('[RelevanceGuard] Fatwa answer rejected (content mismatch).');
                return null;
              }
              return {
                'status': 'SUCCESS',
                'source': 'shirazi-oracle',
                'request_id': 'req_fatwa_${DateTime.now().millisecondsSinceEpoch}',
                'transport': 'http',
                'oracle_url': baseUrl,
                'answered_at': DateTime.now().toUtc().toIso8601String(),
                'answer': detail.scholarlyAnswerArabic,
                'citations': detail.citations,
                'fatwaRef': detail.dossierRef,
                'isRealtimeStream': true,
                'isByokFallback': false,
              };
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }




  /// Returns an honest "source not found" notice when no relevant verified
  /// passage could be retrieved for the user's specific topic.
  ///
  /// This replaces the old synthesizeScholarlyClassicalAnswer() which silently
  /// generated generic answers with fabricated citations regardless of topic.
  /// Rule 3 & 14: never pretend to have found a source that was not retrieved.
  Map<String, dynamic> buildGroundedFallbackNotice({
    required String lang,
    required String topicLabel,
    required String? madhhab,
  }) {
    final notice = RelevanceGuard.sourceNotFoundNotice(
      lang: lang,
      topicLabel: topicLabel,
      madhhab: madhhab,
    );
    return {
      'status': 'SOURCE_NOT_FOUND',
      'answer': notice,
      'citations': <String>[],
      'isRealtimeStream': false,
      'isSourceNotFound': true,
      'canRetry': true,
    };
  }

  // ── REMOVED: synthesizeScholarlyClassicalAnswer() ────────────────────────
  // The old method generated generic Islamic answers with static, unverified
  // citations regardless of the user's actual question topic. It was the root
  // cause of the Bitcoin/beggar mismatch. It has been removed and replaced
  // by buildGroundedFallbackNotice() which honestly discloses when no
  // relevant source was found.
  // ─────────────────────────────────────────────────────────────────────────


  /// Backward-compatible sendQuery wrapper that delegates to streamRealtimeQuery

  Future<Map<String, dynamic>> sendQuery({
    required String text,
    required String persona,
    required String lang,
    String? madhhab,
    String? byokKey,
    String? byokProvider,
  }) async {
    return streamRealtimeQuery(
      text: text,
      persona: persona,
      lang: lang,
      madhhab: madhhab,
      byokKey: byokKey,
      byokProvider: byokProvider,
    );
  }



  /// Tests a personal BYOK key against the provider's key-check endpoint.
  ///
  /// VALIDATION ONLY — never answer generation. This calls the provider's
  /// lightweight key-verification endpoints (`/models`, `/auth/key`) over
  /// HTTPS; the user's question is never sent here and no AI answer is ever
  /// produced from this path. All research answers come exclusively from the
  /// Shirazi Oracle (see [streamRealtimeQuery]). Key material is never
  /// logged: errors are reported without exception details that could echo
  /// credentials.
  Future<KeyValidationResult> testPersonalKeyDetailed({
    required String provider,
    required String apiKey,
  }) async {
    final cleanKey = sanitizeApiKey(apiKey);
    if (cleanKey.isEmpty) {
      return const KeyValidationResult(
        isValid: false,
        message: 'Please paste a valid API key',
      );
    }

    final p = provider.toLowerCase().trim();
    if (!proto.isSupportedByokProvider(p)) {
      return const KeyValidationResult(
        isValid: false,
        message: 'Unsupported Provider',
      );
    }

    try {
      if (p == 'gemini') {
        // Key sent as a header (x-goog-api-key), never as a URL query
        // parameter, so it cannot leak into proxy/access logs.
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models',
        );
        final res = await http.get(
          url,
          headers: {'x-goog-api-key': cleanKey},
        ).timeout(const Duration(seconds: 8));

        if (res.statusCode == 200) {
          return const KeyValidationResult(
            isValid: true,
            message: 'Connection Verified (200 OK)',
            statusCode: 200,
          );
        } else if (res.statusCode == 429) {
          return const KeyValidationResult(
            isValid: true,
            message: 'Key Verified (Rate Limited)',
            statusCode: 429,
          );
        } else if (res.statusCode == 400 || res.statusCode == 403) {
          if (res.body.contains('API_KEY_INVALID') || res.body.contains('API key not valid')) {
            return KeyValidationResult(
              isValid: false,
              message: 'Invalid Gemini API Key',
              statusCode: res.statusCode,
            );
          }
          return KeyValidationResult(
            isValid: false,
            message: 'Verification Failed (${res.statusCode})',
            statusCode: res.statusCode,
          );
        } else {
          return KeyValidationResult(
            isValid: false,
            message: 'Gemini Status: ${res.statusCode}',
            statusCode: res.statusCode,
          );
        }
      } else if (p == 'groq') {
        final url = Uri.parse('https://api.groq.com/openai/v1/models');
        final res = await http.get(
          url,
          headers: {'Authorization': 'Bearer $cleanKey'},
        ).timeout(const Duration(seconds: 8));

        if (res.statusCode == 200) {
          return const KeyValidationResult(
            isValid: true,
            message: 'Connection Verified (200 OK)',
            statusCode: 200,
          );
        } else if (res.statusCode == 429) {
          return const KeyValidationResult(
            isValid: true,
            message: 'Key Verified (Rate Limited)',
            statusCode: 429,
          );
        } else if (res.statusCode == 401) {
          return const KeyValidationResult(
            isValid: false,
            message: 'Invalid Groq API Key',
            statusCode: 401,
          );
        } else {
          return KeyValidationResult(
            isValid: false,
            message: 'Groq Status: ${res.statusCode}',
            statusCode: res.statusCode,
          );
        }
      } else if (p == 'openrouter') {
        final url = Uri.parse('https://openrouter.ai/api/v1/auth/key');
        final res = await http.get(
          url,
          headers: {
            'Authorization': 'Bearer $cleanKey',
            'HTTP-Referer': 'https://shirazi.ai',
            'X-Title': 'Shirazi AI',
          },
        ).timeout(const Duration(seconds: 8));

        if (res.statusCode == 200) {
          return const KeyValidationResult(
            isValid: true,
            message: 'Connection Verified (200 OK)',
            statusCode: 200,
          );
        } else if (res.statusCode == 429) {
          return const KeyValidationResult(
            isValid: true,
            message: 'Key Verified (Rate Limited)',
            statusCode: 429,
          );
        } else if (res.statusCode == 401) {
          return const KeyValidationResult(
            isValid: false,
            message: 'Invalid OpenRouter Key',
            statusCode: 401,
          );
        } else {
          return KeyValidationResult(
            isValid: false,
            message: 'OpenRouter Status: ${res.statusCode}',
            statusCode: res.statusCode,
          );
        }
      }
    } catch (_) {
      // Deliberately no exception details: they could echo key material.
      debugPrint('[ApiService] Personal key verification failed (network/timeout).');
      return const KeyValidationResult(
        isValid: false,
        message: 'Network Error / Timeout',
      );
    }

    return const KeyValidationResult(
      isValid: false,
      message: 'Unsupported Provider',
    );
  }

  /// Tests a personal BYOK key directly against provider API
  Future<bool> testPersonalKey({
    required String provider,
    required String apiKey,
  }) async {
    final res = await testPersonalKeyDetailed(
      provider: provider,
      apiKey: apiKey,
    );
    return res.isValid;
  }

  /// Fetches live AI provider diagnostics & cluster summary from /api/admin/keys/diagnostics
  Future<({ClusterMetrics metrics, List<ProviderHealth> providers})> fetchDiagnostics() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/admin/keys/diagnostics'),
        headers: await _authHeaders(),
      ).timeout(const Duration(seconds: 35));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final summary = data['summary'] as Map<String, dynamic>? ?? {};
        final list = (data['providers'] as List? ?? []);

        final providers = list.map((item) {
          final pMap = item as Map<String, dynamic>;
          final name = pMap['display_name'] ?? pMap['provider_id'] ?? pMap['provider'] ?? 'AI Provider';
          final model = pMap['model_used'] ?? pMap['model'] ?? 'default';
          final st = pMap['status'] ?? 'ONLINE';
          final lat = (pMap['latency_ms'] as num?)?.toDouble() ?? 38.0;
          final detail = pMap['actionable_advice'] ?? pMap['error_summary'] ?? pMap['detail'] ?? '';

          return ProviderHealth(
            providerName: name.toString(),
            model: model.toString(),
            status: st.toString(),
            latencyMs: lat,
            detail: detail.toString(),
            lastChecked: DateTime.now(),
          );
        }).toList();

        final avgLat = providers.isNotEmpty
            ? providers.map((p) => p.latencyMs).reduce((a, b) => a + b) / providers.length
            : 0.0;

        final metrics = ClusterMetrics.fromSummary(summary, avgLatency: avgLat);
        return (metrics: metrics, providers: providers);
      }
    } catch (e) {
      debugPrint('Error fetching live diagnostics: $e');
    }

    return (
      metrics: const ClusterMetrics(),
      providers: <ProviderHealth>[],
    );
  }

  /// Fetches live AI provider diagnostics list for backward compatibility
  Future<List<ProviderHealth>> fetchProviderDiagnostics() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/admin/keys/diagnostics'),
        headers: await _authHeaders(),
      ).timeout(const Duration(seconds: 35));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final list = (data['providers'] as List? ?? []);
        return list.map((item) {
          final pMap = item as Map<String, dynamic>;
          return ProviderHealth(
            providerName: (pMap['display_name'] ?? pMap['provider_id'] ?? pMap['provider'] ?? 'Provider').toString(),
            model: (pMap['model_used'] ?? pMap['model'] ?? 'default').toString(),
            status: (pMap['status'] ?? 'ONLINE').toString(),
            latencyMs: (pMap['latency_ms'] as num?)?.toDouble() ?? 38.0,
            detail: (pMap['actionable_advice'] ?? pMap['error_summary'] ?? pMap['detail'] ?? '').toString(),
            lastChecked: DateTime.now(),
          );
        }).toList();
      }
    } catch (_) {}

    return <ProviderHealth>[];
  }
}
