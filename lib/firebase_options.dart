// File generated for Firebase project nbprojects-4a1a2.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows. '
          'Register a Windows app in the Firebase console or rerun FlutterFire configure.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux. '
          'Linux is not a supported Firebase target in this project yet.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDcaYOye2Pc1sheUot7EnHUxK3b_nsbys0',
    appId: '1:337878268199:web:d4ffb87a497c2c1704d102',
    messagingSenderId: '337878268199',
    projectId: 'nbprojects-4a1a2',
    authDomain: 'nbprojects-4a1a2.firebaseapp.com',
    storageBucket: 'nbprojects-4a1a2.firebasestorage.app',
    measurementId: 'G-X5FB3K4VY5',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAOGmp4y76l-igIkyXIW5pj0_k2fXGTgOg',
    appId: '1:337878268199:ios:79358dfd3cc41ae404d102',
    messagingSenderId: '337878268199',
    projectId: 'nbprojects-4a1a2',
    storageBucket: 'nbprojects-4a1a2.firebasestorage.app',
    iosBundleId: 'com.nbprojects.nbprojects',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAOGmp4y76l-igIkyXIW5pj0_k2fXGTgOg',
    appId: '1:337878268199:ios:79358dfd3cc41ae404d102',
    messagingSenderId: '337878268199',
    projectId: 'nbprojects-4a1a2',
    storageBucket: 'nbprojects-4a1a2.firebasestorage.app',
    iosBundleId: 'com.nbprojects.nbprojects',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDTgiIPeNr9nCeZuxkWo-XOnjE6zUm1va4',
    appId: '1:337878268199:android:03e3c48f4b5d304204d102',
    messagingSenderId: '337878268199',
    projectId: 'nbprojects-4a1a2',
    storageBucket: 'nbprojects-4a1a2.firebasestorage.app',
  );
}
