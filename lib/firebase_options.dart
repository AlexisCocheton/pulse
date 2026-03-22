import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBe7nmY_ChkKOIvT7z9ezJzLFiRCeUPFn8',
    appId: '1:954551225019:android:527b30b95a06b2aa21b79e',
    messagingSenderId: '954551225019',
    projectId: 'pulse-bccf8',
    storageBucket: 'pulse-bccf8.firebasestorage.app',
  );
}
