import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/inquiry.dart';

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
    return StorageService(prefs);
  }

  // --- Device-Bound Key Persistence ---
  // Keys are obfuscated with a device-bound XOR cipher and stored with an
  // 'enc_' prefix. Plaintext values written by older builds are still read
  // back correctly by _decryptKey (no-prefix passthrough).
  String _encryptKey(String plain) {
    final clean = plain.trim();
    if (clean.isEmpty) return '';
    final salt = 'SHIRAZI_SEC_${guestUid.hashCode.abs()}';
    final saltBytes = utf8.encode(salt);
    final plainBytes = utf8.encode(clean);
    final xored = List<int>.generate(
      plainBytes.length,
      (i) => plainBytes[i] ^ saltBytes[i % saltBytes.length],
    );
    return 'enc_${base64Encode(xored)}';
  }

  String _decryptKey(String cipher) {
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

  // BYOK Keys (Locally Encrypted)
  String get geminiKey => _decryptKey(_prefs.getString(_keyGemini) ?? '');
  set geminiKey(String value) => _prefs.setString(_keyGemini, _encryptKey(value));

  String get groqKey => _decryptKey(_prefs.getString(_keyGroq) ?? '');
  set groqKey(String value) => _prefs.setString(_keyGroq, _encryptKey(value));

  String get openAiKey => _decryptKey(_prefs.getString(_keyOpenAI) ?? '');
  set openAiKey(String value) => _prefs.setString(_keyOpenAI, _encryptKey(value));

  String get anthropicKey => _decryptKey(_prefs.getString(_keyAnthropic) ?? '');
  set anthropicKey(String value) => _prefs.setString(_keyAnthropic, _encryptKey(value));

  String get deepSeekKey => _decryptKey(_prefs.getString(_keyDeepSeek) ?? '');
  set deepSeekKey(String value) => _prefs.setString(_keyDeepSeek, _encryptKey(value));

  String get openRouterKey => _decryptKey(_prefs.getString(_keyOpenRouter) ?? '');
  set openRouterKey(String value) => _prefs.setString(_keyOpenRouter, _encryptKey(value));

  void deleteKey(String provider) {
    switch (provider.toLowerCase().trim()) {
      case 'gemini':
        _prefs.remove(_keyGemini);
        break;
      case 'groq':
        _prefs.remove(_keyGroq);
        break;
      case 'openai':
        _prefs.remove(_keyOpenAI);
        break;
      case 'anthropic':
        _prefs.remove(_keyAnthropic);
        break;
      case 'deepseek':
        _prefs.remove(_keyDeepSeek);
        break;
      case 'openrouter':
        _prefs.remove(_keyOpenRouter);
        break;
    }
  }

  String getKeyForProvider(String provider) {
    switch (provider.toLowerCase().trim()) {
      case 'gemini':
        return geminiKey;
      case 'groq':
        return groqKey;
      case 'openai':
        return openAiKey;
      case 'anthropic':
        return anthropicKey;
      case 'deepseek':
        return deepSeekKey;
      case 'openrouter':
        return openRouterKey;
      default:
        return '';
    }
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

  String get serverUrl => _prefs.getString(_keyServerUrl) ?? 'http://129.154.242.136:4040';
  set serverUrl(String value) => _prefs.setString(_keyServerUrl, value);

  // Onboarding & Scholar Identity
  bool get isFirstLaunch => _prefs.getBool(_keyFirstLaunch) ?? true;
  set isFirstLaunch(bool value) => _prefs.setBool(_keyFirstLaunch, value);

  bool get isAuthenticated => _prefs.getBool(_keyAuthStatus) ?? false;
  set isAuthenticated(bool value) => _prefs.setBool(_keyAuthStatus, value);

  String get scholarName => _prefs.getString(_keyScholarName) ?? 'د. أحمد فاروق (Dr. Ahmad Farooq)';
  set scholarName(String value) => _prefs.setString(_keyScholarName, value);

  String get scholarEmail => _prefs.getString(_keyScholarEmail) ?? 'scholar@darulifta.edu';
  set scholarEmail(String value) => _prefs.setString(_keyScholarEmail, value);

  String get scholarRole => _prefs.getString(_keyScholarRole) ?? 'Mufti / Darul Ifta';
  set scholarRole(String value) => _prefs.setString(_keyScholarRole, value);

  void login({required String email, String? name, String? role}) {
    isAuthenticated = true;
    scholarEmail = email;
    if (name != null && name.isNotEmpty) scholarName = name;
    if (role != null && role.isNotEmpty) scholarRole = role;
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
