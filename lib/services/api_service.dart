import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/inquiry.dart';
import '../models/provider_health.dart';
import 'fiqh_query_analyzer.dart';

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

  ApiService({this.baseUrl = 'http://129.154.242.136:4040'});

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

    final userKeysPayload = <String, String>{};
    if (byokProvider != null && byokKey != null && byokKey.trim().isNotEmpty) {
      userKeysPayload[byokProvider.toLowerCase()] = byokKey.trim();
    }
    if (fallbackKeys != null) {
      fallbackKeys.forEach((k, v) {
        if (v.trim().isNotEmpty) {
          userKeysPayload[k.toLowerCase()] = v.trim();
        }
      });
    }

    try {
      socket = IO.io(baseUrl, IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableForceNew()
          .setTimeout(10000)
          .build());

      socket.onConnect((_) {
        socket!.emit('chat', {
          'text': text,
          'persona': persona,
          'lang': lang,
          'madhhab': madhhab,
          'user_keys': userKeysPayload,
          'provider_priority': providerPriority,
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

      bool isLimitOrOutage(dynamic data, String answer) {
        if (data is Map) {
          if (data['ok'] == false || data['status'] == 'ERROR' || data['error'] != null) {
            return true;
          }
        }
        final a = answer.trim();
        final lower = a.toLowerCase();

        // 1. Explicit limit, busy, & outage indicators across Urdu, Arabic, and English
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

        // 2. Short non-scholarly answers (< 220 chars) that indicate failure or server trouble
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

          if (answer.isNotEmpty && !isOutage && !isMadhhabMismatch) {
            completer.complete({
              'status': 'SUCCESS',
              'answer': answer,
              'citations': citations,
              'isRealtimeStream': true,
              'byokProvider': 'Shirazi Core Agent (Live)',
            });
          } else if (isMadhhabMismatch) {
            debugPrint('[ApiService] Server cached answer rejected: madhhab mismatch (requested $madhhab). Cascading to BYOK...');
            completer.completeError('Server returned answer with madhhab mismatch (requested $madhhab)');
          } else if (isOutage) {
            completer.completeError('Server limit reached or upstream outage');
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

      // Responsive timeout: 5s if fallback keys exist, else 8s
      final hasAnyFallbackKey = userKeysPayload.isNotEmpty;
      final maxWaitSeconds = hasAnyFallbackKey ? 5 : 8;
      timeoutTimer = Timer(Duration(seconds: maxWaitSeconds), () {
        if (!completer.isCompleted) {
          completer.completeError(TimeoutException('Socket response timed out after ${maxWaitSeconds}s'));
        }
      });

      final result = await completer.future;
      timeoutTimer.cancel();
      socket.disconnect();
      socket.dispose();
      return result;
    } catch (e) {
      debugPrint('Primary Shirazi socket attempt yielded: $e. Initiating multi-tier fallback cascade...');
    } finally {
      timeoutTimer?.cancel();
      try {
        socket?.disconnect();
        socket?.dispose();
      } catch (_) {}
    }

    // Step 2: Multi-Tier Server-Side BYOK Failover (Sections 16, 17, 18, 19: No RAG Bypass)
    // Send user's configured BYOK keys to Shirazi Oracle Server to run full Shamela research pipeline
    if (autoFailover && userKeysPayload.isNotEmpty) {
      final priorityList = <String>[];
      if (providerPriority != null && providerPriority.isNotEmpty) {
        priorityList.addAll(providerPriority);
      } else if (byokProvider != null && byokProvider.isNotEmpty) {
        priorityList.add(byokProvider);
      }
      for (final k in userKeysPayload.keys) {
        if (!priorityList.contains(k)) {
          priorityList.add(k);
        }
      }

      if (onProgress != null) {
        onProgress('Connecting to Shirazi Research Oracle with BYOK failover...');
      }

      try {
        final httpRes = await http.post(
          Uri.parse('$baseUrl/api/chat'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'text': text,
            'persona': persona,
            'lang': lang,
            'madhhab': madhhab,
            'user_keys': userKeysPayload,
            'provider_priority': priorityList,
            'channel': 'mobile_app',
          }),
        ).timeout(const Duration(seconds: 45));

        if (httpRes.statusCode == 200) {
          final data = jsonDecode(httpRes.body) as Map<String, dynamic>;
          if (data['status'] == 'SUCCESS' && data['answer'] != null) {
            return {
              'status': 'SUCCESS',
              'answer': data['answer'],
              'citations': data['citations'] ?? <String>[],
              'madhhab': data['madhhab'],
              'requires_madhhab_selection': data['requires_madhhab_selection'] ?? false,
              'isRealtimeStream': false,
              'byokProvider': data['provider'] ?? 'Shirazi Oracle (BYOK)',
            };
          }
        }
      } catch (e) {
        debugPrint('[ApiService] Server-side BYOK fallback request failed: $e');
      }
    }

    // Step 2b: Direct Client-Side BYOK Failover (when server is offline / unreachable)
    if (userKeysPayload.isNotEmpty) {
      final directClientResult = await _executeDirectClientByok(
        text: text,
        persona: persona,
        lang: lang,
        madhhab: madhhab,
        userKeysPayload: userKeysPayload,
        providerPriority: providerPriority,
        onProgress: onProgress,
      );
      if (directClientResult != null) {
        return directClientResult;
      }
    }

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
    final exhaustionMsg = _getExhaustionMessage(lang);
    return {
      'status': 'EXHAUSTED',
      'error': exhaustionMsg,
      'answer': exhaustionMsg,
      'isExhausted': true,
      'canRetry': true,
      'citations': <String>[],
      'byokProvider': null,
      'isByokFallback': false,
    };
  }

  /// Localized exhaustion error notice preserving question for 1-tap retry
  static String _getExhaustionMessage(String lang) {
    switch (lang) {
      case 'ur':
        return 'اس وقت شیرازی تحقیقی سرور اور تمام دستیاب فال بیک ذرائع عارضی طور پر مصروف یا دستیاب نہیں ہیں۔\n\n'
            'آپ کا سوال محفوظ کر لیا گیا ہے۔ آپ کچھ دیر بعد نیچے دیا گیا "دوبارہ کوشش" کا بٹن دبا سکتے ہیں یا ترتیبات میں اپنی ذاتی API Key شامل فرما سکتے ہیں۔';
      case 'ar':
        return 'تعذر معالجة الطلب حالياً نظراً لاكتمال سعة شبكة الشيرازي البحثية ومزودات الذكاء الاصطناعي الاحتياطية.\n\n'
            'تم حفظ سؤالك. يمكنك الضغط على "إعادة المحاولة" بعد قليل أو إضافة مفتاح API شخصي في الإعدادات.';
      default:
        return 'The Shirazi research network and configured fallback providers are currently at capacity or temporarily unavailable.\n\n'
            'Your question has been preserved. You can tap "Retry Query" or configure a personal API key in Settings.';
    }
  }

  /// Direct client-side BYOK execution when Shirazi backend server is unreachable.
  /// Calls Groq / Gemini / OpenRouter REST APIs directly using the user's personal key.
  Future<Map<String, dynamic>?> _executeDirectClientByok({
    required String text,
    required String persona,
    required String lang,
    String? madhhab,
    required Map<String, String> userKeysPayload,
    List<String>? providerPriority,
    Function(String)? onProgress,
  }) async {
    if (userKeysPayload.isEmpty) return null;

    final priorityList = <String>[];
    if (providerPriority != null && providerPriority.isNotEmpty) {
      for (final p in providerPriority) {
        final pNorm = p.toLowerCase().trim();
        if (pNorm.isNotEmpty && !priorityList.contains(pNorm)) {
          priorityList.add(pNorm);
        }
      }
    }
    for (final k in userKeysPayload.keys) {
      final kNorm = k.toLowerCase().trim();
      if (kNorm.isNotEmpty && !priorityList.contains(kNorm)) {
        priorityList.add(kNorm);
      }
    }

    final String langName = lang == 'ur'
        ? 'Urdu (اردو)'
        : (lang == 'ar' ? 'Arabic (العربية)' : 'English');
    final String selectedMadhhab = madhhab ?? 'Hanafi';

    final systemPrompt = '''
You are an authoritative, highly respectful Islamic Jurisprudence Scholar (Muhaqqiq / Faqih) in the $selectedMadhhab Madhhab.
Task: Provide a detailed, authentic Islamic jurisprudential (Fiqh) ruling and explanation for the user's question.
Language Requirement: You MUST respond in $langName.

Guidelines:
1. Address the question strictly according to the $selectedMadhhab Madhhab principles.
2. Structure your response clearly:
   - Ruling / Summary (الحكم / خلاصہ)
   - Shariah Principles & Evidence (الأدلة والأصول)
   - Detailed Explanation (التحقيق والتفصيل)
3. Maintain classical scholarly tone and respect for the Shariah.
''';

    for (final provider in priorityList) {
      final apiKey = userKeysPayload[provider] ??
          userKeysPayload[provider.toLowerCase()] ??
          userKeysPayload[provider.toUpperCase()];
      if (apiKey == null || apiKey.trim().isEmpty) continue;
      final cleanKey = sanitizeApiKey(apiKey);

      try {
        if (provider.toLowerCase() == 'groq') {
          if (onProgress != null) onProgress('Consulting Groq (LLaMA 3.3) directly...');
          final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
          final res = await http.post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $cleanKey',
            },
            body: jsonEncode({
              'model': 'llama-3.3-70b-versatile',
              'messages': [
                {'role': 'system', 'content': systemPrompt},
                {'role': 'user', 'content': text},
              ],
              'temperature': 0.3,
              'max_tokens': 1500,
            }),
          ).timeout(const Duration(seconds: 25));

          if (res.statusCode == 200) {
            final data = jsonDecode(res.body);
            final answer = data['choices']?[0]?['message']?['content']?.toString() ?? '';
            if (answer.trim().isNotEmpty) {
              return {
                'status': 'SUCCESS',
                'answer': answer,
                'citations': <String>[],
                'madhhab': selectedMadhhab,
                'isRealtimeStream': false,
                'byokProvider': 'Groq (LLaMA 3.3)',
              };
            }
          }
        } else if (provider.toLowerCase() == 'gemini') {
          if (onProgress != null) onProgress('Consulting Gemini (Flash) directly...');
          final url = Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$cleanKey',
          );
          final res = await http.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': '$systemPrompt\n\nUser Question:\n$text'}
                  ]
                }
              ],
              'generationConfig': {
                'temperature': 0.3,
                'maxOutputTokens': 1500,
              }
            }),
          ).timeout(const Duration(seconds: 25));

          if (res.statusCode == 200) {
            final data = jsonDecode(res.body);
            final candidates = data['candidates'] as List? ?? [];
            if (candidates.isNotEmpty) {
              final parts = candidates[0]['content']?['parts'] as List? ?? [];
              final textContent = parts.map((p) => p['text'] ?? '').join('\n');
              if (textContent.trim().isNotEmpty) {
                return {
                  'status': 'SUCCESS',
                  'answer': textContent,
                  'citations': <String>[],
                  'madhhab': selectedMadhhab,
                  'isRealtimeStream': false,
                  'byokProvider': 'Gemini (Flash)',
                };
              }
            }
          }
        } else if (provider.toLowerCase() == 'openrouter') {
          if (onProgress != null) onProgress('Consulting OpenRouter directly...');
          final url = Uri.parse('https://openrouter.ai/api/v1/chat/completions');
          final res = await http.post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $cleanKey',
              'HTTP-Referer': 'https://shirazi.ai',
              'X-Title': 'Shirazi AI',
            },
            body: jsonEncode({
              'model': 'meta-llama/llama-3.3-70b-instruct',
              'messages': [
                {'role': 'system', 'content': systemPrompt},
                {'role': 'user', 'content': text},
              ],
              'temperature': 0.3,
              'max_tokens': 1500,
            }),
          ).timeout(const Duration(seconds: 25));

          if (res.statusCode == 200) {
            final data = jsonDecode(res.body);
            final answer = data['choices']?[0]?['message']?['content']?.toString() ?? '';
            if (answer.trim().isNotEmpty) {
              return {
                'status': 'SUCCESS',
                'answer': answer,
                'citations': <String>[],
                'madhhab': selectedMadhhab,
                'isRealtimeStream': false,
                'byokProvider': 'OpenRouter',
              };
            }
          }
        }
      } catch (e) {
        debugPrint('[ApiService] Direct client BYOK ($provider) error: $e');
      }
    }
    return null;
  }

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
                'answer': detail.scholarlyAnswerArabic,
                'citations': detail.citations,
                'fatwaRef': detail.dossierRef,
                'isRealtimeStream': true,
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



  /// Tests a personal BYOK key directly against provider API with granular diagnostics
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

    try {
      if (p == 'gemini') {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models?key=$cleanKey',
        );
        final res = await http.get(url).timeout(const Duration(seconds: 8));

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
    } catch (e) {
      debugPrint('Error testing personal key: $e');
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
