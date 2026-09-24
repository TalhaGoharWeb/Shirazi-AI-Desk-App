import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class SettingsProvider with ChangeNotifier {
  final StorageService storageService;
  final ApiService apiService;

  bool _isTestingKey = false;
  String _testStatus = 'Active & Ready'; // 'Active & Ready', 'Validating...', 'Connection Verified', 'Test Failed'

  SettingsProvider({
    required this.storageService,
    required this.apiService,
  });

  String get selectedProvider => storageService.selectedProvider;
  String get preferredProvider => storageService.preferredProvider;
  String get secondaryProvider => storageService.secondaryProvider;
  String get geminiKey => storageService.geminiKey;
  String get groqKey => storageService.groqKey;
  String get openRouterKey => storageService.openRouterKey;
  String get language => storageService.language;
  double get arabicFontSize => storageService.arabicFontSize;
  bool get offlineCache => storageService.offlineCache;
  bool get autoFailover => storageService.autoFailover;
  bool get isTestingKey => _isTestingKey;
  String get testStatus => _testStatus;

  String get currentApiKey => getKeyForProvider(selectedProvider);

  String getKeyForProvider(String provider) => storageService.getKeyForProvider(provider);

  bool isProviderEnabled(String provider) => storageService.isProviderEnabled(provider);

  /// §1: true when the Oracle endpoint uses HTTPS (production requirement).
  bool get isSecureTransport => apiService.isSecureTransport;

  /// Log-safe Oracle endpoint label (no credentials).
  String get oracleServerLabel => apiService.redactedEndpoint;

  void toggleProviderEnabled(String provider, bool enabled) {
    storageService.setProviderEnabled(provider, enabled);
    notifyListeners();
  }

  void setPreferredProvider(String provider) {
    storageService.preferredProvider = provider;
    notifyListeners();
  }

  void setSecondaryProvider(String provider) {
    storageService.secondaryProvider = provider;
    notifyListeners();
  }

  /// Returns a privacy-masked representation of the key for UI display (e.g. AIzaSy...9a2f)
  String getMaskedKey(String provider) {
    final key = getKeyForProvider(provider);
    if (key.isEmpty) return '';
    if (key.length <= 8) return '••••••••';
    final prefix = key.substring(0, 6);
    final suffix = key.substring(key.length - 4);
    return '$prefix••••$suffix';
  }

  static String sanitizeApiKey(String key) => ApiService.sanitizeApiKey(key);

  void selectProvider(String provider) {
    storageService.selectedProvider = provider;
    _testStatus = 'Active & Ready';
    notifyListeners();
  }

  Future<bool> saveCurrentKey(String key) {
    return saveKeyForProvider(selectedProvider, key);
  }

  /// Saves [key] for [provider] into secure device storage.
  /// Returns `true` only when the write actually landed in platform secure
  /// storage — the UI must show the returned result, not an assumed success.
  Future<bool> saveKeyForProvider(String provider, String key) async {
    final clean = sanitizeApiKey(key);
    final p = provider.toLowerCase().trim();
    bool ok;
    switch (p) {
      case 'gemini':
      case 'groq':
      case 'openrouter':
        ok = await storageService.saveKey(p, clean);
        break;
      default:
        ok = false;
    }
    _testStatus = ok
        ? (clean.isEmpty ? 'Active & Ready' : 'Key Saved Successfully')
        : 'Save failed: ${storageService.lastKeyWriteError ?? 'secure storage unavailable'}';
    notifyListeners();
    return ok;
  }

  void deleteKey(String provider) {
    storageService.deleteKey(provider);
    _testStatus = 'Key Removed';
    notifyListeners();
  }

  Future<void> testConnection([String? candidateKey]) async {
    final keyToTest = (candidateKey != null && candidateKey.trim().isNotEmpty)
        ? candidateKey
        : currentApiKey;

    final clean = sanitizeApiKey(keyToTest);
    if (clean.isEmpty) {
      _testStatus = 'Please enter an API key';
      notifyListeners();
      return;
    }

    // Auto-save the sanitized key immediately
    saveCurrentKey(clean);

    _isTestingKey = true;
    _testStatus = 'Validating API Handshake...';
    notifyListeners();

    final result = await apiService.testPersonalKeyDetailed(
      provider: selectedProvider,
      apiKey: clean,
    );

    _isTestingKey = false;
    _testStatus = result.message;
    notifyListeners();
  }

  Future<KeyValidationResult> testKeyForProvider(String provider, [String? candidateKey]) async {
    final keyToTest = (candidateKey != null && candidateKey.trim().isNotEmpty)
        ? candidateKey
        : getKeyForProvider(provider);

    final clean = sanitizeApiKey(keyToTest);
    if (clean.isEmpty) {
      _testStatus = 'Please enter an API key';
      notifyListeners();
      return const KeyValidationResult(
        isValid: false,
        message: 'Please enter an API key',
      );
    }

    saveKeyForProvider(provider, clean);

    _isTestingKey = true;
    _testStatus = 'Validating ${provider.toUpperCase()} API...';
    notifyListeners();

    final result = await apiService.testPersonalKeyDetailed(
      provider: provider,
      apiKey: clean,
    );

    _isTestingKey = false;
    _testStatus = result.message;
    notifyListeners();
    return result;
  }

  void setLanguage(String lang) {
    storageService.language = lang;
    notifyListeners();
  }

  void setFontSize(double size) {
    storageService.arabicFontSize = size;
    notifyListeners();
  }

  void toggleOfflineCache(bool val) {
    storageService.offlineCache = val;
    notifyListeners();
  }

  void toggleAutoFailover(bool val) {
    storageService.autoFailover = val;
    notifyListeners();
  }

  // Scholar Identity & Auth
  bool get isAuthenticated => storageService.isAuthenticated;
  String get scholarName => storageService.scholarName;
  String get scholarEmail => storageService.scholarEmail;
  String get scholarRole => storageService.scholarRole;

  void login({required String email, String? name, String? role}) {
    storageService.login(email: email, name: name, role: role);
    notifyListeners();
  }

  void logout() {
    storageService.logout();
    notifyListeners();
  }
}
