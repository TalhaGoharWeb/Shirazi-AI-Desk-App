import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Installs an in-memory mock for the flutter_secure_storage platform channel.
///
/// The real channel (`plugins.it_nomads.com/flutter_secure_storage`) has no
/// implementation in unit tests, so any test that saves or reads BYOK keys
/// throws `MissingPluginException` without this mock. Call it in `setUp`
/// (fresh store per test) before constructing [StorageService].
void mockSecureStorage() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final Map<String, String> store = {};
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall call) async {
    final args = (call.arguments as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
    switch (call.method) {
      case 'read':
        return store[args['key'] as String?];
      case 'write':
        store[args['key'] as String] = args['value'] as String;
        return null;
      case 'delete':
        store.remove(args['key'] as String?);
        return null;
      case 'readAll':
        return Map<String, String>.from(store);
      case 'deleteAll':
        store.clear();
        return null;
      case 'containsKey':
        return store.containsKey(args['key'] as String?);
      default:
        return null;
    }
  });
}
