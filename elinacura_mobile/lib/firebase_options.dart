// Firebase configuration for project `elinacura`.
// Run `flutterfire configure --project=elinacura` to regenerate with platform app IDs.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAdhru_HTFGDd4sSboPn3aOTLVCLdw__tA',
    appId: '1:609263120973:web:7f5970aae5a95e13fea204',
    messagingSenderId: '609263120973',
    projectId: 'elinacura',
    authDomain: 'elinacura.firebaseapp.com',
    storageBucket: 'elinacura.firebasestorage.app',
    measurementId: 'G-S4SNYPSZMH',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD0oJ3V6p_LXaeiXYd9oCof9lAMoXtdWjA',
    appId: '1:609263120973:android:dd32d5f60946f1e5fea204',
    messagingSenderId: '609263120973',
    projectId: 'elinacura',
    storageBucket: 'elinacura.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCz1VaY0_CG-TfBtqCzfKRc_t7c9YxXHXQ',
    appId: '1:609263120973:ios:c13eef2f9abc9047fea204',
    messagingSenderId: '609263120973',
    projectId: 'elinacura',
    storageBucket: 'elinacura.firebasestorage.app',
    iosClientId: '609263120973-qmf6ailhetg9rqo7pihu7g9g3k9pkajd.apps.googleusercontent.com',
    iosBundleId: 'com.elinacura.app',
  );

}