import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shirazi_app/services/api_service.dart';
import 'package:shirazi_app/services/storage_service.dart';
import 'package:shirazi_app/providers/research_provider.dart';

class _RealHttpOverrides extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _RealHttpOverrides();

  test('ResearchProvider loads live fatwa without crypto mock data', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storageService = StorageService(prefs);
    final apiService = ApiService(baseUrl: 'http://129.154.242.136:4040');

    final research = ResearchProvider(
      apiService: apiService,
      storageService: storageService,
    );

    // Initially not inq-892
    expect(research.activeInquiry.id != 'inq-892', true);

    // Allow background live fetch to complete
    await Future.delayed(const Duration(seconds: 3));

    print('Active inquiry on Research Desk:');
    print('ID: ${research.activeInquiry.id}');
    print('Ref: ${research.activeInquiry.dossierRef}');
    print('Question: ${research.activeInquiry.questionArabic}');
    print('Ans len: ${research.activeInquiry.scholarlyAnswerArabic.length}');

    expect(research.activeInquiry.id != 'inq-892', true);
  });
}
