import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Boots Firebase if — and only if — the project has been configured.
///
/// FitTrack does **not** ship generated credentials. Until
/// `google-services.json` (Android) and `firebase_options.dart` are produced by
/// the FlutterFire CLI, this returns `false` and the app still starts so the
/// Phase 0 navigation foundation can be verified.
abstract final class FirebaseBootstrap {
  static Future<bool> init() async {
    try {
      await Firebase.initializeApp();
      debugPrint('FirebaseBootstrap: Firebase configured.');
      return true;
    } on Object catch (error) {
      debugPrint(
        'FirebaseBootstrap: Firebase is NOT configured yet '
        '(${error.runtimeType}). Complete the manual Firebase steps in '
        'README.md, then re-run.',
      );
      return false;
    }
  }
}
