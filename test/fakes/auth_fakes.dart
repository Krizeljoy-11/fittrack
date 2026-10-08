import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:fittrack/services/auth_service.dart';

/// Signed-in user double: only the fields FitTrack reads are real.
class FakeUser implements User {
  FakeUser({
    this.uid = 'test-uid',
    this.email = 'tester@example.com',
    this.displayName = 'Test User',
  });

  @override
  final String uid;

  @override
  final String? email;

  @override
  final String? displayName;

  @override
  bool get emailVerified => true;

  @override
  bool get isAnonymous => false;

  @override
  String? get photoURL => null;

  @override
  String? get refreshToken => null;

  @override
  String? get phoneNumber => null;

  @override
  String? get tenantId => null;

  @override
  List<UserInfo> get providerData => const <UserInfo>[];

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Credential double — [AuthProvider] ignores the credential itself.
class FakeUserCredential implements UserCredential {
  FakeUserCredential([User? user]) : _user = user;

  final User? _user;

  @override
  User? get user => _user;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Scriptable [AuthService] double.
///
/// Nothing here touches Firebase: outcomes are controlled through the public
/// `fail*` flags and recorded in the `*Calls` lists.
class FakeAuthService extends AuthService {
  final StreamController<User?> _controller =
      StreamController<User?>.broadcast(sync: true);
  final List<String> signInEmails = <String>[];
  final List<String> registerEmails = <String>[];
  final List<String> resetEmails = <String>[];

  User? _user;
  int signOutCalls = 0;

  bool configured = true;
  bool failSignIn = false;
  bool failRegister = false;
  bool failReset = false;

  /// Puts a user "into" the session before or during a test.
  void emitUser(User? user) {
    _user = user;
    _controller.add(user);
  }

  @override
  bool get isConfigured => configured;

  @override
  Stream<User?> get authStateChanges => _controller.stream;

  @override
  User? get currentUser => _user;

  @override
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    signInEmails.add(email);
    if (failSignIn) {
      throw FirebaseAuthException(code: 'invalid-credential');
    }
    emitUser(FakeUser(email: email));
    return FakeUserCredential(_user);
  }

  @override
  Future<UserCredential> register({
    required String email,
    required String password,
  }) async {
    registerEmails.add(email);
    if (failRegister) {
      throw FirebaseAuthException(code: 'email-already-in-use');
    }
    emitUser(FakeUser(email: email));
    return FakeUserCredential(_user);
  }

  @override
  Future<void> sendPasswordReset({required String email}) async {
    resetEmails.add(email);
    if (failReset) {
      throw FirebaseAuthException(code: 'user-not-found');
    }
  }

  @override
  Future<void> signOut() async {
    signOutCalls += 1;
    emitUser(null);
  }

  void dispose() {
    _controller.close();
  }
}
