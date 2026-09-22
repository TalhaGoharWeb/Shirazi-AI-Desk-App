import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/inquiry.dart';
import '../models/provider_health.dart';
import '../models/chat_models.dart';
import '../services/api_service.dart';
import '../services/firestore_service.dart';
import '../services/firebase_auth_service.dart';

class AdminProvider with ChangeNotifier {
  final ApiService apiService;
  final FirebaseAuthService? authService;

  ClusterMetrics _metrics = const ClusterMetrics();
  List<ProviderHealth> _providers = [];
  List<Inquiry> _auditInquiries = [];
  Map<String, dynamic>? _serverHealth;
  bool _isLoading = false;
  bool _isLoadingAudit = false;
  String? _errorMessage;

  // Multi-user Oversight Data
  List<ShiraziConversation> _allUserConversations = [];
  StreamSubscription<List<ShiraziConversation>>? _adminConvSubscription;
  String _searchFilter = '';
  String _selectedMadhhabFilter = 'All';
  bool _isAdminVerified = false;

  // Selected conversation for deep-dive inspection
  ShiraziConversation? _inspectedConversation;
  List<ShiraziChatMessage> _inspectedMessages = [];
  StreamSubscription<List<ShiraziChatMessage>>? _inspectMsgSubscription;

  AdminProvider({
    required this.apiService,
    this.authService,
  }) {
    refreshDiagnostics();
    fetchAuditInquiries();
    fetchServerHealth();
    checkAdminStatus();
    _listenToAllConversations();
  }

  ClusterMetrics get metrics => _metrics;
  List<ProviderHealth> get providers => _providers;
  List<Inquiry> get auditInquiries => _auditInquiries;
  Map<String, dynamic>? get serverHealth => _serverHealth;
  bool get isLoading => _isLoading;
  bool get isLoadingAudit => _isLoadingAudit;
  String? get errorMessage => _errorMessage;

  bool get isAdminVerified => _isAdminVerified;
  String get searchFilter => _searchFilter;
  String get selectedMadhhabFilter => _selectedMadhhabFilter;
  ShiraziConversation? get inspectedConversation => _inspectedConversation;
  List<ShiraziChatMessage> get inspectedMessages => _inspectedMessages;

  List<ShiraziConversation> get filteredConversations {
    return _allUserConversations.where((conv) {
      final matchesSearch = _searchFilter.isEmpty ||
          conv.title.toLowerCase().contains(_searchFilter.toLowerCase()) ||
          conv.lastMessagePreview.toLowerCase().contains(_searchFilter.toLowerCase()) ||
          (conv.ownerEmail?.toLowerCase().contains(_searchFilter.toLowerCase()) ?? false) ||
          conv.ownerUid.toLowerCase().contains(_searchFilter.toLowerCase());

      final matchesMadhhab = _selectedMadhhabFilter == 'All' ||
          conv.madhhab.toLowerCase() == _selectedMadhhabFilter.toLowerCase();

      return matchesSearch && matchesMadhhab;
    }).toList();
  }

  void setSearchFilter(String filter) {
    _searchFilter = filter;
    notifyListeners();
  }

  void setMadhhabFilter(String madhhab) {
    _selectedMadhhabFilter = madhhab;
    notifyListeners();
  }

  Future<void> checkAdminStatus() async {
    if (authService != null) {
      _isAdminVerified = await authService!.checkIsAdmin();
      notifyListeners();
    } else {
      _isAdminVerified = true;
    }
  }

  void _listenToAllConversations() {
    _adminConvSubscription?.cancel();
    _adminConvSubscription = FirestoreService.streamAllConversationsAdmin().listen(
      (convs) {
        _allUserConversations = convs;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('Admin all-conversations stream error: $e');
      },
    );
  }

  void inspectConversation(ShiraziConversation conv) {
    _inspectedConversation = conv;
    _inspectMsgSubscription?.cancel();
    _inspectMsgSubscription = FirestoreService.streamConversationMessages(conv.id).listen(
      (msgs) {
        _inspectedMessages = msgs;
        notifyListeners();
      },
    );
    notifyListeners();
  }

  void clearInspection() {
    _inspectMsgSubscription?.cancel();
    _inspectedConversation = null;
    _inspectedMessages = [];
    notifyListeners();
  }

  Future<void> moderateDeleteConversation(String conversationId) async {
    await FirestoreService.deleteConversation(conversationId);
    if (_inspectedConversation?.id == conversationId) {
      clearInspection();
    }
  }

  Future<void> refreshDiagnostics() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final diag = await apiService.fetchDiagnostics();
      _metrics = diag.metrics;
      _providers = diag.providers;
      if (_providers.isEmpty) {
        _errorMessage = 'لم يتم استلام مزودي الذكاء الاصطناعي من الخادم.';
      }
    } catch (e) {
      _errorMessage = 'خطأ في الاتصال بالخادم: $e';
      debugPrint('Error refreshing admin diagnostics: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAuditInquiries() async {
    _isLoadingAudit = true;
    notifyListeners();

    try {
      final liveFatwas = await apiService.fetchRealtimeFatwas(fetchFullDetails: true);
      _auditInquiries = liveFatwas;
    } catch (e) {
      debugPrint('Error fetching audit fatwas: $e');
    } finally {
      _isLoadingAudit = false;
      notifyListeners();
    }
  }

  Future<void> fetchServerHealth() async {
    try {
      _serverHealth = await apiService.fetchServerHealth();
      notifyListeners();
    } catch (_) {}
  }

  @override
  void dispose() {
    _adminConvSubscription?.cancel();
    _inspectMsgSubscription?.cancel();
    super.dispose();
  }
}
