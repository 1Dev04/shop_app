
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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
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
    apiKey: 'AIzaSyDWBh2qcfyOUF8xrWgvXLxhYqSQ8wNAbN0',
    appId: '1:773184115397:web:3d231070d503aa174596ac',
    messagingSenderId: '773184115397',
    projectId: 'abc-shop-dad8c',
    authDomain: 'abc-shop-dad8c.firebaseapp.com',
    storageBucket: 'abc-shop-dad8c.firebasestorage.app',
    measurementId: 'G-81ERPHS9QW',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC1S9xZ9uaA6MlG7xIE8_x9sDWEFvw4ZUs',
    appId: '1:773184115397:android:2da7bbeb6df9c7204596ac',
    messagingSenderId: '773184115397',
    projectId: 'abc-shop-dad8c',
    storageBucket: 'abc-shop-dad8c.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDYJcPuwSOB_r-76mCZzOM_P_ShY7fGyl0',
    appId: '1:773184115397:ios:c9692aec167c534e4596ac',
    messagingSenderId: '773184115397',
    projectId: 'abc-shop-dad8c',
    storageBucket: 'abc-shop-dad8c.firebasestorage.app',
    androidClientId: '773184115397-s3egfkdaq2j683naqk6cr2o5j6fa8v76.apps.googleusercontent.com',
    iosClientId: '773184115397-dv6pqigm77bjh56eiolg800l3jhhu3no.apps.googleusercontent.com',
    iosBundleId: 'com.example.flutterApplication1',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDYJcPuwSOB_r-76mCZzOM_P_ShY7fGyl0',
    appId: '1:773184115397:ios:c9692aec167c534e4596ac',
    messagingSenderId: '773184115397',
    projectId: 'abc-shop-dad8c',
    storageBucket: 'abc-shop-dad8c.firebasestorage.app',
    androidClientId: '773184115397-s3egfkdaq2j683naqk6cr2o5j6fa8v76.apps.googleusercontent.com',
    iosClientId: '773184115397-dv6pqigm77bjh56eiolg800l3jhhu3no.apps.googleusercontent.com',
    iosBundleId: 'com.example.flutterApplication1',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDWBh2qcfyOUF8xrWgvXLxhYqSQ8wNAbN0',
    appId: '1:773184115397:web:d27af8857a6a8be84596ac',
    messagingSenderId: '773184115397',
    projectId: 'abc-shop-dad8c',
    authDomain: 'abc-shop-dad8c.firebaseapp.com',
    storageBucket: 'abc-shop-dad8c.firebasestorage.app',
    measurementId: 'G-63BSGTX662',
  );
}
