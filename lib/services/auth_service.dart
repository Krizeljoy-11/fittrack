import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// Thin wrapper around Firebase Authentication (email/password).
///
/// The class is deliberately small: UI never talks to `FirebaseAuth`
/// directly, it goes through [AuthService] (via `AuthProvider`) instead.
class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;

  /// `true` once Firebase has been configured for this build.
  bool get isConfigured => Firebase.apps.isNotEmpty;

  Stream<User?> get authStateChanges {
    if (!isConfigured) return const Stream<User?>.empty();
    return _auth.authStateChanges();
  }

  User? get currentUser => isConfigured ? _auth.currentUser : null;

  String? get currentUid => currentUser?.uid;

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> register({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> sendPasswordReset({required String email}) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() => _auth.signOut();
}
