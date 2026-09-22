// File generated and managed for Firebase Spark Plan configuration
// Default Firebase Options for Shirazi Jurisprudence AI
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAUs6CnLL68T7zidYikFUr6G2VFdcxHIOM',
    appId: '1:302847199432:web:7db8e4d8b6e838d46f3dfd',
    messagingSenderId: '302847199432',
    projectId: 'shirazi-ai',
    authDomain: 'shirazi-ai.firebaseapp.com',
    storageBucket: 'shirazi-ai.firebasestorage.app',
    measurementId: 'G-XGLTCFVNL0',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD-QPVOEynL-LVA8fB5k9DLfh0RMPAt3B8',
    appId: '1:302847199432:android:b17d48947520a6fb6f3dfd',
    messagingSenderId: '302847199432',
    projectId: 'shirazi-ai',
    storageBucket: 'shirazi-ai.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDemoSparkKeyShiraziAIJuristIos03',
    appId: '1:568697267620:ios:com_shirazi_jurist',
    messagingSenderId: '568697267620',
    projectId: 'shirazi-jurist',
    storageBucket: 'shirazi-jurist.appspot.com',
    iosBundleId: 'com.shirazi.jurist',
  );
}
