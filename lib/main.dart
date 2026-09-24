import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/shirazi_theme.dart';
import 'firebase_options.dart';
import 'services/api_service.dart';
import 'services/storage_service.dart';
import 'services/firebase_auth_service.dart';
import 'providers/research_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/chat_provider.dart';
import 'screens/main_shell.dart';
import 'screens/welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase Spark Plan with graceful fallback
  try {
    await FirebaseAuthService.initializeFirebase(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase Spark startup: $e');
  }

  final prefs = await SharedPreferences.getInstance();
  final storageService = StorageService(prefs);
  // §7: load BYOK keys from platform secure storage (Keystore/Keychain)
  // into the memory cache before anything reads them.
  await storageService.loadSecureKeys();
  final authService = FirebaseAuthService(storageService: storageService);
  // Keep the local BYOK vault namespaced by Firebase UID: every sign-in,
  // sign-out, or OS-restored session swaps the vault before any key is
  // read, so keys can never leak across accounts on a shared device.
  // (Sign-in methods additionally switch the vault inside
  // mergeApiKeysWithCloud; setActiveUid is idempotent.)
  authService.authStateChanges.listen((user) {
    storageService.setActiveUid(
      user?.uid,
      isAnonymous: user?.isAnonymous ?? true,
    );
  });
  final apiService = ApiService(
    baseUrl: storageService.serverUrl,
    // §11: Socket.IO authentication — Firebase ID token attached on connect.
    authTokenProvider: () => authService.getIdToken(),
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storageService),
        Provider<FirebaseAuthService>.value(value: authService),
        ChangeNotifierProvider(
          create: (_) => ResearchProvider(
            apiService: apiService,
            storageService: storageService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(
            storageService: storageService,
            apiService: apiService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ChatProvider(
            apiService: apiService,
            storageService: storageService,
            authService: authService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => AdminProvider(
            apiService: apiService,
            authService: authService,
          ),
        ),
      ],
      child: ShiraziApp(storageService: storageService),
    ),
  );
}

class ShiraziApp extends StatelessWidget {
  final StorageService storageService;

  const ShiraziApp({super.key, required this.storageService});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final Locale currentLocale;
        switch (settings.language) {
          case 'ar':
            currentLocale = const Locale('ar', 'SA');
            break;
          case 'ur':
            currentLocale = const Locale('ur', 'PK');
            break;
          default:
            currentLocale = const Locale('en', 'US');
            break;
        }

        return MaterialApp(
          title: 'Shirazi Jurisprudence (شیرازی)',
          debugShowCheckedModeBanner: false,
          theme: ShiraziTheme.darkTheme,
          locale: currentLocale,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', 'US'), // English
            Locale('ar', 'SA'), // Arabic
            Locale('ur', 'PK'), // Urdu
          ],
          home: storageService.isFirstLaunch
              ? const WelcomeScreen(isStandalone: false)
              : const MainShell(),
        );
      },
    );
  }
}
