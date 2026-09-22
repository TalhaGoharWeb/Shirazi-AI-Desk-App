import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shirazi_app/services/api_service.dart';

void main() {
  test('Shirazi API Health & Endpoints Probe', () async {
    final healthRes = await http.get(Uri.parse('http://129.154.242.136:4040/api/health'));
    print('HEALTH STATUS: ${healthRes.statusCode} - ${healthRes.body}');
    expect(healthRes.statusCode, 200);

    print('Connecting Socket.IO to 129.154.242.136:4040...');
    final completer = Completer<void>();
    final socket = IO.io('http://129.154.242.136:4040', IO.OptionBuilder()
        .setTransports(['websocket', 'polling'])
        .enableForceNew()
        .setTimeout(5000)
        .build());

    socket.onConnect((_) {
      print('SOCKET CONNECTED!');
      if (!completer.isCompleted) completer.complete();
    });

    socket.onConnectError((err) {
      print('SOCKET CONNECT ERROR: $err');
      if (!completer.isCompleted) completer.complete();
    });

    socket.connect();

    await completer.future.timeout(const Duration(seconds: 5), onTimeout: () {});
    socket.disconnect();
    socket.dispose();
  });

  test('Shirazi Online Server Live Fatwas Retrieval Test', () async {
    final apiService = ApiService(baseUrl: 'http://129.154.242.136:4040');
    final fatwas = await apiService.fetchRealtimeFatwas(fetchFullDetails: false);
    print('Fetched ${fatwas.length} fatwas from live server');
    expect(fatwas.isNotEmpty, true);
    for (final f in fatwas) {
      print('Fatwa [${f.dossierRef}] (${f.madhhab}): ${f.questionArabic.substring(0, f.questionArabic.length > 50 ? 50 : f.questionArabic.length)}');
    }
  });
}
