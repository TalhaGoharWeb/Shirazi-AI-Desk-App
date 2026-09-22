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
  /// future HTTP Authorization header). May be null when signed out.
  final Future<String?> Function()? authTokenProvider;

  /// When true, user keys may be transmitted over plain HTTP. Default false.
  /// This is a development-only override; production must use HTTPS.
  final bool allowInsecureHttp;

  ApiService({
    this.baseUrl = 'http://129.154.242.136:4040',
    this.authTokenProvider,
    this.allowInsecureHttp = false,
  }) {
    endpoint = proto.OracleEndpoint.parse(baseUrl);
  }

  /// True when the configured Oracle uses HTTPS (production requirement).
  bool get isSecureTransport => endpoint.isSecure;

  /// Log-safe endpoint label — never contains credentials.
  String get redactedEndpoint => endpoint.redacted;

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

  /// Sends a research query to the live Shirazi Gateway/Core via Socket.IO real-time stream
  /// with automated multi-tier personal BYOK failover (Primary -> Preferred -> Secondary -> Error)
  Future<Map<String, dynamic>> streamRealtimeQuery({
    required String text,
    required String persona,
    required String lang,
    String? madhhab,
    String? byokKey,
    String? byokProvider,
    Map<String, String>? fallbackKeys,
    List<String>? providerPriority,
    bool autoFailover = true,
    void Function(String progressMessage)? onProgress,
  }) async {
    final completer = Completer<Map<String, dynamic>>();

    IO.Socket? socket;
    Timer? timeoutTimer;

    // Client-generated UUID v4 for end-to-end tracing (§9):
    // app -> Oracle API -> research pipeline -> AI provider -> response -> app.
    final requestId = proto.generateRequestId();
    final socketStopwatch = Stopwatch()..start();

    // Tracks whether the question was actually delivered to the Oracle over
    // the socket channel. Used to avoid accidental duplicate submissions.
    bool socketDelivered = false;

    final userKeysPayload = <String, String>{};
    if (byokProvider != null && byokKey != null && byokKey.trim().isNotEmpty) {
      final p = byokProvider.trim().toLowerCase();
      if (proto.isSupportedByokProvider(p)) {
        userKeysPayload[p] = byokKey.trim();
      } else {
        debugPrint('[ApiService] Rejected non-allowlisted BYOK provider: $p');
      }
    }
    if (fallbackKeys != null) {
      fallbackKeys.forEach((k, v) {
        final p = k.trim().toLowerCase();
        if (v.trim().isNotEmpty && proto.isSupportedByokProvider(p)) {
          userKeysPayload[p] = v.trim();
        }
      });
    }

    // ── HTTPS enforcement (§1, §5) ──────────────────────────────────────
    // User API keys must NEVER travel over plain HTTP. If the Oracle endpoint
    // is not HTTPS and the development override is off, we refuse to transmit
    // the keys at all and return an honest, localized blocked state.
    if (userKeysPayload.isNotEmpty &&
        !endpoint.isSecure &&
        !allowInsecureHttp) {
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

      socket.onConnect((_) {
        socket!.emit('chat', {
          'request_id': requestId,
          'text': text,
          'persona': persona,
          'lang': lang,
          'madhhab': madhhab,
          'user_keys': userKeysPayload,
          'provider_priority':
              proto.priorityListFor(userKeysPayload, providerPriority, byokProvider),
          'channel': 'mobile_app',
        });
        socketDelivered = true;
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

      // Pure, unit-tested outage detector (oracle_protocol).
      bool isLimitOrOutage(dynamic data, String answer) =>
          proto.isLimitOrOutage(data is Map ? data : null, answer);

      socket.on('assistant-message', (data) {
        if (!completer.isCompleted) {
          String answer = '';
          List<String> citations = [];
          if (data is Map) {
            answer = data['answer']?.toString() ?? '';
            final rawCitations = data['citations'];
            if (rawCitations is List) {
              citations = rawCitations.map((c) => c.toString()).toList();
            }
          } else if (data is String) {
            answer = data;
          }

          final isOutage = isLimitOrOutage(data, answer);
          final isMadhhabMismatch = madhhab != null && madhhab.isNotEmpty
              ? MadhhabDetector.isMismatched(answer, madhhab)
              : false;
          // §9: if the server echoes a request ID, it must match ours —
          // otherwise this response does not belong to our request.
          final requestIdOk = data is Map
              ? proto.requestIdMatches(data, requestId)
              : true;

          if (answer.isNotEmpty &&
              !isOutage &&
              !isMadhhabMismatch &&
              requestIdOk) {
            completer.complete({
              'status': 'SUCCESS',
              // ── Server identity / provenance (§5) ──────────────────────
              // These fields are CLIENT-OBSERVED transport provenance: they
              // prove this answer arrived over the Oracle channel. The server
              // does not currently issue request/response IDs, so none are
              // fabricated here.
              'source': 'shirazi-oracle',
              'request_id': requestId,
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
          } else if (isMadhhabMismatch) {
            debugPrint('[ApiService] Server cached answer rejected: madhhab mismatch (requested $madhhab).');
            completer.completeError('Server returned answer with madhhab mismatch (requested $madhhab)');
          } else if (isOutage) {
            // The Oracle's research pipeline ran but its inference capacity is
            // exhausted. This is NOT answered by any other AI: we surface a
            // structured quota state so the UI can offer an explicit,
            // consent-based retry THROUGH the Oracle with the user's key.
            completer.complete({
              'status': 'QUOTA_EXHAUSTED',
              'source': 'shirazi-oracle',
              'request_id': requestId,
              'transport': 'socket.io',
              'oracle_url': baseUrl,
              'answered_at': DateTime.now().toUtc().toIso8601String(),
              'latency_ms': socketStopwatch.elapsedMilliseconds,
              'answer': '',
              'citations': <String>[],
              'isRealtimeStream': true,
              'oracle_keys_used': userKeysPayload.isNotEmpty,
              'canRetry': true,
              'canRetryWithByok': userKeysPayload.isEmpty,
              'isByokFallback': false,
              'byokProvider': null,
            });
          }
        }
      });

      socket.on('chat-error', (err) {
        debugPrint('Socket chat-error received: $err');
        if (!completer.isCompleted) {
          completer.completeError('Server chat error: $err');
        }
      });

      socket.on('rate-limit', (err) {
        debugPrint('Socket rate-limit received: $err');
        if (!completer.isCompleted) {
          completer.completeError('Server rate limit reached');
        }
      });

      socket.onConnectError((err) {
        if (!completer.isCompleted) {
          completer.completeError(err);
        }
      });

      socket.onError((err) {
        if (!completer.isCompleted) {
          completer.completeError(err);
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
      debugPrint('Primary Shirazi socket attempt yielded: $e. Checking HTTP transport alternative...');
    } finally {
      timeoutTimer?.cancel();
      try {
        socket?.disconnect();
        socket?.dispose();
      } catch (_) {}
    }

    // Step 2: HTTP transport alternative — SAME Oracle, SAME pipeline.
    // Reached only when the socket.io transport itself failed (connect error),
    // i.e. the question was never delivered. The user's keys travel to the
    // Shirazi Oracle Server, which runs its full Shamela research / retrieval /
    // verification pipeline using them for inference. The app NEVER calls a
    // provider API directly.
    // NOTE: this step is skipped after a delivered-but-unanswered socket
    // attempt (timeout) to avoid accidentally submitting the same research
    // question twice — the user retries explicitly instead (§13).
    if (socketDelivered == false && autoFailover) {
      if (onProgress != null) {
        onProgress('Socket channel unavailable — trying Shirazi Oracle over HTTP...');
      }

      try {
        final httpRes = await http.post(
          Uri.parse('$baseUrl/api/chat'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'request_id': requestId,
            'text': text,
            'persona': persona,
            'lang': lang,
            'madhhab': madhhab,
            'user_keys': userKeysPayload,
            'provider_priority':
                proto.priorityListFor(userKeysPayload, providerPriority, byokProvider),
            'channel': 'mobile_app',
          }),
        ).timeout(const Duration(seconds: 90));

        if (httpRes.statusCode == 200) {
          final data = jsonDecode(httpRes.body) as Map<String, dynamic>;
          if (data['status'] == 'SUCCESS' && data['answer'] != null) {
            final answer = data['answer'].toString();
            if (answer.isNotEmpty && !isLimitOrOutage(data, answer)) {
              return {
                'status': 'SUCCESS',
                'source': 'shirazi-oracle',
                'request_id': requestId,
                'transport': 'http',
                'oracle_url': baseUrl,
                'answered_at': DateTime.now().toUtc().toIso8601String(),
                'answer': answer,
                'citations': data['citations'] ?? <String>[],
                'madhhab': data['madhhab'],
                'requires_madhhab_selection': data['requires_madhhab_selection'] ?? false,
                'isRealtimeStream': false,
                'isByokFallback': false,
                'byokProvider': userKeysPayload.isNotEmpty
                    ? 'Shirazi Oracle (personal key via pipeline)'
                    : 'Shirazi Oracle (HTTP)',
              };
            }
            // Oracle answered but its inference capacity is exhausted.
            return _quotaExhaustedResult(
              requestId: requestId,
              transport: 'http',
              oracleKeysUsed: userKeysPayload.isNotEmpty,
            );
          }
        } else if (httpRes.statusCode == 429) {
          debugPrint('[ApiService] Oracle HTTP 429: inference quota exhausted.');
          return _quotaExhaustedResult(
            requestId: requestId,
            transport: 'http',
            oracleKeysUsed: userKeysPayload.isNotEmpty,
          );
        } else if (httpRes.statusCode == 401 || httpRes.statusCode == 403) {
          debugPrint('[ApiService] Oracle HTTP ${httpRes.statusCode}: auth rejected.');
          return _oracleErrorResult(
            requestId: requestId,
            transport: 'http',
            message: _getAuthErrorMessage(lang),
          );
        } else if (httpRes.statusCode >= 500) {
          debugPrint('[ApiService] Oracle HTTP ${httpRes.statusCode}: server error.');
        }
      } on TimeoutException {
        debugPrint('[ApiService] Oracle HTTP /api/chat timed out.');
      } catch (e) {
        debugPrint('[ApiService] Oracle HTTP fallback failed: $e');
      }
    }

    // REMOVED (Step 2b): _executeDirectClientByok — the old direct client-side
    // calls to Groq / Gemini / OpenRouter REST APIs. That path answered the
    // user's question with a generic AI model and a hand-written system prompt,
    // completely bypassing the Shirazi research / retrieval / verification
    // pipeline. It violated the core product requirement and has been deleted.
    // User keys are now ONLY ever sent to the Shirazi Oracle Server, which
    // runs its own pipeline with them for inference (§7).

    // Step 3: Probe server's canonical fatwa library for matching verified inquiry
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

    // Step 4: Graceful Failure Protocol (Requirement 6: Never fabricate an answer)
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

  /// Builds the ordered provider-priority list for a server-side BYOK request.
  /// Delegates to the pure, unit-tested implementation in oracle_protocol.
  static List<String> priorityListFor(
    Map<String, String> userKeysPayload,
    List<String>? providerPriority,
    String? byokProvider,
  ) =>
      proto.priorityListFor(userKeysPayload, providerPriority, byokProvider);

  /// Structured quota-exhaustion result. The Oracle ran but its inference
  /// capacity is spent. No answer is fabricated; the UI offers an explicit,
  /// consent-based retry through the Oracle pipeline.
  Map<String, dynamic> _quotaExhaustedResult({
    required String requestId,
    required String transport,
    required bool oracleKeysUsed,
  }) {
    return {
      'status': 'QUOTA_EXHAUSTED',
      'source': 'shirazi-oracle',
      'request_id': requestId,
      'transport': transport,
      'oracle_url': baseUrl,
      'answered_at': DateTime.now().toUtc().toIso8601String(),
      'answer': '',
      'citations': <String>[],
      'oracle_keys_used': oracleKeysUsed,
      'canRetry': true,
      'canRetryWithByok': !oracleKeysUsed,
      'isByokFallback': false,
      'byokProvider': null,
    };
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
    bool autoFailover = true,
  }) async {
    return streamRealtimeQuery(
      text: text,
      persona: persona,
      lang: lang,
      madhhab: madhhab,
      byokKey: byokKey,
      byokProvider: byokProvider,
      autoFailover: autoFailover,
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
