import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/inquiry.dart';

/// BYOK key security model (§7).
///
/// - At rest: keys live in PLATFORM SECURE STORAGE (Android Keystore /
///   iOS Keychain via flutter_secure_storage), never in SharedPreferences.
/// - In memory: cached after [loadSecureKeys] so the existing synchronous
///   API keeps working.
/// - In transit: keys are sent ONLY to the Shirazi Oracle over HTTPS
///   (enforced by ApiService). They are never logged, never written to
///   Firestore, and never included in analytics/crash reports.
/// - Legacy values (plaintext or the old XOR `enc_` obfuscation — which was
///   never real encryption) are migrated once into secure storage and then
///   deleted from SharedPreferences.
class StorageService {
  static const String _keyGemini = 'byok_gemini';
  static const String _keyGroq = 'byok_groq';
  static const String _keyOpenAI = 'byok_openai';
  static const String _keyAnthropic = 'byok_anthropic';
  static const String _keyDeepSeek = 'byok_deepseek';
  static const String _keyOpenRouter = 'byok_openrouter';
  static const String _keySelectedProvider = 'byok_selected_provider';
  static const String _keyPreferredProvider = 'byok_preferred_provider';
  static const String _keySecondaryProvider = 'byok_secondary_provider';
  static const String _keyGeminiEnabled = 'byok_gemini_enabled';
  static const String _keyGroqEnabled = 'byok_groq_enabled';
  static const String _keyOpenAIEnabled = 'byok_openai_enabled';
  static const String _keyAnthropicEnabled = 'byok_anthropic_enabled';
  static const String _keyDeepSeekEnabled = 'byok_deepseek_enabled';
  static const String _keyOpenRouterEnabled = 'byok_openrouter_enabled';
  static const String _keyLanguage = 'pref_language';
  static const String _keyFontSize = 'pref_font_size';
  static const String _keyOfflineCache = 'pref_offline_cache';
  static const String _keyAutoFailover = 'pref_auto_failover';
  static const String _keyServerUrl = 'pref_server_url';
  static const String _keySavedInquiries = 'saved_inquiries_json';
  static const String _keyFirstLaunch = 'pref_first_launch';
  static const String _keyAuthStatus = 'auth_authenticated';
  static const String _keyScholarName = 'auth_scholar_name';
  static const String _keyScholarEmail = 'auth_scholar_email';
  static const String _keyScholarRole = 'auth_scholar_role';
  static const String _keyScholarMadhhab = 'auth_scholar_madhhab';
  static const String _keyScholarRank = 'auth_scholar_rank';
  static const String _keyGuestUid = 'auth_guest_uid';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  String get guestUid {
    var uid = _prefs.getString(_keyGuestUid);
    if (uid == null || uid.isEmpty) {
      uid = 'usr_guest_${DateTime.now().millisecondsSinceEpoch}_${(DateTime.now().microsecond % 9000) + 1000}';
      _prefs.setString(_keyGuestUid, uid);
    }
    return uid;
  }

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    final service = StorageService(prefs);
    await service.loadSecureKeys();
    return service;
  }

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// In-memory cache of BYOK keys, populated by [loadSecureKeys].
  final Map<String, String> _keyCache = {};

  static const List<String> _keyProviders = [
    'gemini',
    'groq',
    'openai',
    'anthropic',
    'deepseek',
    'openrouter',
  ];

  String _legacyPrefsKey(String provider) {
    switch (provider) {
      case 'gemini':
        return _keyGemini;
      case 'groq':
        return _keyGroq;
      case 'openai':
        return _keyOpenAI;
      case 'anthropic':
        return _keyAnthropic;
      case 'deepseek':
        return _keyDeepSeek;
      case 'openrouter':
        return _keyOpenRouter;
      default:
        return 'byok_$provider';
    }
  }

  static String _secureKeyName(String provider) => 'byok_key_$provider';

  /// Loads BYOK keys from platform secure storage into the memory cache.
  /// Migrates any legacy SharedPreferences values (plaintext or old XOR
  /// `enc_` obfuscation) into secure storage exactly once, then deletes them.
  /// Call once at startup before any key is read.
  Future<void> loadSecureKeys() async {
    for (final p in _keyProviders) {
      String value = '';
      try {
        value = (await _secureStorage.read(key: _secureKeyName(p))) ?? '';
      } catch (e) {
        debugPrint('[StorageService] Secure storage read failed for $p: $e');
      }
      if (value.isEmpty) {
        final legacyKey = _legacyPrefsKey(p);
        final legacyCipher = _prefs.getString(legacyKey) ?? '';
        if (legacyCipher.isNotEmpty) {
          final migrated = _decryptLegacyKey(legacyCipher);
          if (migrated.isNotEmpty) {
            // Delete the legacy pref ONLY after a confirmed secure write.
            // Otherwise a failed migration would destroy the only copy.
            var writeOk = false;
            try {
              await _secureStorage.write(key: _secureKeyName(p), value: migrated);
              writeOk = true;
            } catch (e) {
              debugPrint('[StorageService] Secure storage write failed for $p: $e');
            }
            if (writeOk) {
              value = migrated;
              await _prefs.remove(legacyKey);
              debugPrint('[StorageService] Migrated legacy BYOK key for $p into secure storage.');
            } else {
              // Keep the legacy value alive as a last resort so the user's
              // key is not destroyed; it will be retried on next startup.
              debugPrint('[StorageService] Migration deferred for $p: secure write failed, legacy value kept.');
            }
          } else {
            await _prefs.remove(legacyKey);
          }
        }
      }
      _keyCache[p] = value;
    }
  }

  /// Writes a BYOK key through to platform secure storage and the cache.
  /// An empty value deletes the key.
  ///
  /// The in-memory cache is updated ONLY after the secure write succeeds, so
  /// the app never claims a key is saved when it actually was not. On
  /// failure the previous cache value is kept and the error is recorded in
  /// [lastKeyWriteError]; prefer [saveKey] when the caller needs the result.
  Future<void> _writeSecureKey(String provider, String value) async {
    await saveKey(provider, value);
  }

  /// Last secure-storage write failure, human-readable; `null` when the most
  /// recent write succeeded (or no write has happened yet).
  String? lastKeyWriteError;

  /// Saves [value] for [provider] in secure storage. Returns `true` only when
  /// the write actually landed in platform secure storage. Updates the
  /// memory cache on success and records [lastKeyWriteError] on failure.
  Future<bool> saveKey(String provider, String value) async {
    final p = provider.toLowerCase().trim();
    final clean = value.trim();
    try {
      if (clean.isEmpty) {
        await _secureStorage.delete(key: _secureKeyName(p));
      } else {
        await _secureStorage.write(key: _secureKeyName(p), value: clean);
      }
    } catch (e) {
      lastKeyWriteError = 'Secure device storage write failed for $p: $e';
      debugPrint('[StorageService] $lastKeyWriteError');
      return false;
    }
    lastKeyWriteError = null;
    _keyCache[p] = clean;
    return true;
  }

  /// Reads the old XOR `enc_` obfuscation (or plaintext) for one-time
  /// migration. This was never real encryption and is not used for new writes.
  String _decryptLegacyKey(String cipher) {
    if (cipher.isEmpty) return '';
    if (!cipher.startsWith('enc_')) return cipher.trim();
    try {
      final rawBase64 = cipher.substring(4);
      final xored = base64Decode(rawBase64);
      final salt = 'SHIRAZI_SEC_${guestUid.hashCode.abs()}';
      final saltBytes = utf8.encode(salt);
      final plainBytes = List<int>.generate(
        xored.length,
        (i) => xored[i] ^ saltBytes[i % saltBytes.length],
      );
      final dec = utf8.decode(plainBytes).trim();
      if (dec.isNotEmpty) return dec;
    } catch (_) {}
    return cipher.trim();
  }

  // --- BYOK Keys (platform secure storage; synchronous cache API) ---
  // NOTE: the synchronous getters below read the in-memory cache populated
  // by loadSecureKeys(). Setters write through to secure storage.

  String get geminiKey => getKeyForProvider('gemini');
  set geminiKey(String value) => _writeSecureKey('gemini', value);

  String get groqKey => getKeyForProvider('groq');
  set groqKey(String value) => _writeSecureKey('groq', value);

  String get openAiKey => getKeyForProvider('openai');
  set openAiKey(String value) => _writeSecureKey('openai', value);

  String get anthropicKey => getKeyForProvider('anthropic');
  set anthropicKey(String value) => _writeSecureKey('anthropic', value);

  String get deepSeekKey => getKeyForProvider('deepseek');
  set deepSeekKey(String value) => _writeSecureKey('deepseek', value);

  String get openRouterKey => getKeyForProvider('openrouter');
  set openRouterKey(String value) => _writeSecureKey('openrouter', value);

  void deleteKey(String provider) {
    _writeSecureKey(provider, '');
  }

  String getKeyForProvider(String provider) {
    final p = provider.toLowerCase().trim();
    if (_keyCache.containsKey(p)) return _keyCache[p]!;
    // Not yet loaded: fall back to a legacy prefs read so early callers
    // never crash (migrated properly on loadSecureKeys).
    return _decryptLegacyKey(_prefs.getString(_legacyPrefsKey(p)) ?? '');
  }

  // Preferred & Secondary Fallback Priority
  String get preferredProvider => _prefs.getString(_keyPreferredProvider) ?? selectedProvider;
  set preferredProvider(String value) {
    _prefs.setString(_keyPreferredProvider, value);
    selectedProvider = value;
  }

  String get secondaryProvider {
    final sec = _prefs.getString(_keySecondaryProvider);
    if (sec != null && sec.isNotEmpty && sec != preferredProvider) {
      return sec;
    }
    // Default sensible alternative
    return preferredProvider == 'gemini' ? 'groq' : 'gemini';
  }
  set secondaryProvider(String value) => _prefs.setString(_keySecondaryProvider, value);

  // Provider Enabled / Disabled Toggles
  bool isProviderEnabled(String provider) {
    switch (provider.toLowerCase().trim()) {
      case 'gemini':
        return _prefs.getBool(_keyGeminiEnabled) ?? (geminiKey.isNotEmpty);
      case 'groq':
        return _prefs.getBool(_keyGroqEnabled) ?? (groqKey.isNotEmpty);
      case 'openai':
        return _prefs.getBool(_keyOpenAIEnabled) ?? (openAiKey.isNotEmpty);
      case 'anthropic':
        return _prefs.getBool(_keyAnthropicEnabled) ?? (anthropicKey.isNotEmpty);
      case 'deepseek':
        return _prefs.getBool(_keyDeepSeekEnabled) ?? (deepSeekKey.isNotEmpty);
      case 'openrouter':
        return _prefs.getBool(_keyOpenRouterEnabled) ?? (openRouterKey.isNotEmpty);
      default:
        return true;
    }
  }

  void setProviderEnabled(String provider, bool enabled) {
    switch (provider.toLowerCase().trim()) {
      case 'gemini':
        _prefs.setBool(_keyGeminiEnabled, enabled);
        break;
      case 'groq':
        _prefs.setBool(_keyGroqEnabled, enabled);
        break;
      case 'openai':
        _prefs.setBool(_keyOpenAIEnabled, enabled);
        break;
      case 'anthropic':
        _prefs.setBool(_keyAnthropicEnabled, enabled);
        break;
      case 'deepseek':
        _prefs.setBool(_keyDeepSeekEnabled, enabled);
        break;
      case 'openrouter':
        _prefs.setBool(_keyOpenRouterEnabled, enabled);
        break;
    }
  }

  /// Resolves the ordered fallback chain of active, non-empty, enabled providers
  List<String> getActiveFallbackChain() {
    final chain = <String>[];

    // 1. Preferred Provider
    final pref = preferredProvider;
    if (isProviderEnabled(pref) && getKeyForProvider(pref).isNotEmpty) {
      chain.add(pref);
    }

    // 2. Secondary Provider
    final sec = secondaryProvider;
    if (sec != pref && isProviderEnabled(sec) && getKeyForProvider(sec).isNotEmpty) {
      chain.add(sec);
    }

    // 3. Other configured providers
    for (final p in ['gemini', 'groq', 'openai', 'anthropic', 'deepseek', 'openrouter']) {
      if (!chain.contains(p) && isProviderEnabled(p) && getKeyForProvider(p).isNotEmpty) {
        chain.add(p);
      }
    }

    return chain;
  }

  String get selectedProvider => _prefs.getString(_keySelectedProvider) ?? 'gemini';
  set selectedProvider(String value) => _prefs.setString(_keySelectedProvider, value);

  bool get autoFailover => _prefs.getBool(_keyAutoFailover) ?? true;
  set autoFailover(bool value) => _prefs.setBool(_keyAutoFailover, value);

  // App Reading Preferences
  String get language => _prefs.getString(_keyLanguage) ?? 'en'; // en, ar, ur
  set language(String value) => _prefs.setString(_keyLanguage, value);

  double get arabicFontSize => _prefs.getDouble(_keyFontSize) ?? 18.0;
  set arabicFontSize(double value) => _prefs.setDouble(_keyFontSize, value);

  bool get offlineCache => _prefs.getBool(_keyOfflineCache) ?? true;
  set offlineCache(bool value) => _prefs.setBool(_keyOfflineCache, value);

  /// Production Oracle (hardened Socket.IO server). Release builds must use
  /// this unless the user explicitly configured a different server URL.
  static const String productionOracleUrl = 'https://shirazi-oracle.140-238-250-139.sslip.io';

  /// Stale pre-hardening dev default. Never used in release builds; installs
  /// that persisted it are transparently migrated to [productionOracleUrl].
  static const String _legacyDevOracleUrl = 'http://129.154.242.136:4040';

  String get serverUrl {
    final stored = _prefs.getString(_keyServerUrl)?.trim();
    if (stored == null || stored.isEmpty || stored == _legacyDevOracleUrl) {
      return productionOracleUrl;
    }
    return stored;
  }
  set serverUrl(String value) => _prefs.setString(_keyServerUrl, value);

  // Onboarding & Scholar Identity
  bool get isFirstLaunch => _prefs.getBool(_keyFirstLaunch) ?? true;
  set isFirstLaunch(bool value) => _prefs.setBool(_keyFirstLaunch, value);

  bool get isAuthenticated => _prefs.getBool(_keyAuthStatus) ?? false;
  set isAuthenticated(bool value) => _prefs.setBool(_keyAuthStatus, value);

  String get scholarName => _prefs.getString(_keyScholarName) ?? 'Guest Scholar';
  set scholarName(String value) => _prefs.setString(_keyScholarName, value);

  String get scholarEmail => _prefs.getString(_keyScholarEmail) ?? '';
  set scholarEmail(String value) => _prefs.setString(_keyScholarEmail, value);

  String get scholarRole => _prefs.getString(_keyScholarRole) ?? 'Guest';
  set scholarRole(String value) => _prefs.setString(_keyScholarRole, value);

  String get scholarMadhhab => _prefs.getString(_keyScholarMadhhab) ?? 'Hanafi';
  set scholarMadhhab(String value) => _prefs.setString(_keyScholarMadhhab, value);

  String get scholarRank => _prefs.getString(_keyScholarRank) ?? 'Talib al-Ilm';
  set scholarRank(String value) => _prefs.setString(_keyScholarRank, value);

  void login({required String email, String? name, String? role, String? madhhab, String? rank}) {
    isAuthenticated = true;
    scholarEmail = email;
    if (name != null && name.isNotEmpty) scholarName = name;
    if (role != null && role.isNotEmpty) scholarRole = role;
    if (madhhab != null && madhhab.isNotEmpty) scholarMadhhab = madhhab;
    if (rank != null && rank.isNotEmpty) scholarRank = rank;
  }

  void logout() {
    isAuthenticated = false;
  }

  // Inquiry Persistence & Archive
  List<Inquiry> loadSavedInquiries() {
    final raw = _prefs.getString(_keySavedInquiries);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((item) => Inquiry.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> persistInquiries(List<Inquiry> inquiries) async {
    try {
      final raw = jsonEncode(inquiries.map((inq) => inq.toJson()).toList());
      await _prefs.setString(_keySavedInquiries, raw);
    } catch (_) {}
  }

  Future<void> appendInquiry(Inquiry inquiry) async {
    final list = loadSavedInquiries();
    list.removeWhere((item) => item.id == inquiry.id);
    list.insert(0, inquiry);
    await persistInquiries(list);
  }

  /// Purges legacy hardcoded mock items from local persistent storage
  Future<void> purgeMockData() async {
    final list = loadSavedInquiries();
    final filtered = list.where((item) =>
      !item.id.startsWith('dossier-') &&
      item.id != 'inq-892'
    ).toList();
    if (filtered.length != list.length) {
      await persistInquiries(filtered);
    }
  }
}
