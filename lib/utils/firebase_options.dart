// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCSOHLIt0-R2SCcodc3poGtKhqf2-_CL8E',
    appId: '1:31786140418:web:2e7c123ba4a1704f0ff81b',
    messagingSenderId: '31786140418',
    projectId: 'your-companion-41ca1',
    authDomain: 'your-companion-41ca1.firebaseapp.com',
    storageBucket: 'your-companion-41ca1.appspot.com',
    measurementId: 'G-XR5Z164C9E',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA-a5PN0P2AtF5eGeiZofOlwefqWmJ7mOo',
    appId: '1:31786140418:android:ea1780609ff283c40ff81b',
    messagingSenderId: '31786140418',
    projectId: 'your-companion-41ca1',
    storageBucket: 'your-companion-41ca1.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD8m2e5tpESYM4WcnbYKuI2F5_5HdTfS0c',
    appId: '1:31786140418:ios:e6a6766b7fc4337d0ff81b',
    messagingSenderId: '31786140418',
    projectId: 'your-companion-41ca1',
    storageBucket: 'your-companion-41ca1.appspot.com',
    iosClientId: '31786140418-taq6bn6mg3m4kqmfs60dd5j16sdhsehj.apps.googleusercontent.com',
    iosBundleId: 'com.example.companion',
  );
}
