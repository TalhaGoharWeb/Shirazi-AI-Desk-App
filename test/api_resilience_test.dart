@Timeout(Duration(seconds: 120))
import 'package:flutter_test/flutter_test.dart';
import 'package:shirazi_app/services/api_service.dart';

void main() {
  test('ApiService streamRealtimeQuery resolves queries cleanly without connection error', () async {
    final apiService = ApiService(baseUrl: 'https://shirazi-oracle.140-238-250-139.sslip.io');

    // Test with a sample Urdu query
    final resUrdu = await apiService.streamRealtimeQuery(
      text: 'نماز کے اوقات کیا ہیں؟',
      persona: 'muhaqqiq',
      lang: 'ur',
      madhhab: 'Hanafi',
    );

    expect(resUrdu['status'], anyOf('SUCCESS', 'EXHAUSTED'));
    expect(resUrdu['answer'], isNotEmpty);
    expect(resUrdu['answer'], isNot(contains('تعذر استلام الرد')));
    print('Urdu Answer received (${resUrdu['answer'].length} chars):');
    print(resUrdu['answer']);

    // Test with Arabic query
    final resAr = await apiService.streamRealtimeQuery(
      text: 'ما حكم السفر في رمضان؟',
      persona: 'muhaqqiq',
      lang: 'ar',
      madhhab: 'Hanafi',
    );

    expect(resAr['status'], anyOf('SUCCESS', 'EXHAUSTED'));
    expect(resAr['answer'], isNotEmpty);
    expect(resAr['answer'], isNot(contains('تعذر استلام الرد')));
    print('\nArabic Answer received (${resAr['answer'].length} chars):');
    print(resAr['answer']);
  });
}
