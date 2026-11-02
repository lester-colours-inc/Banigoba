// Firebase is used for push notifications only (project banigoba-bbfe8).
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for the Firebase apps behind push messaging.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'Push messaging is not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAggwxAtRfKLSamcu_4WyjwaP7kdKq-Fc0',
    appId: '1:828873019132:web:79c25bbdc1a92c2062d179',
    messagingSenderId: '828873019132',
    projectId: 'banigoba-bbfe8',
    authDomain: 'banigoba-bbfe8.firebaseapp.com',
    storageBucket: 'banigoba-bbfe8.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyALHjMwbtbveD-_CtiMWRBoL9C6Q-7Vq-E',
    appId: '1:828873019132:android:8eb37d40de0489e862d179',
    messagingSenderId: '828873019132',
    projectId: 'banigoba-bbfe8',
    storageBucket: 'banigoba-bbfe8.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA-9W9IcS8qwZSM12Ib0TnsOz9foZ-Hv2U',
    appId: '1:828873019132:ios:deb58a800d71cabc62d179',
    messagingSenderId: '828873019132',
    projectId: 'banigoba-bbfe8',
    storageBucket: 'banigoba-bbfe8.firebasestorage.app',
    iosBundleId: 'com.coloursinc.banigoba',
  );
}
