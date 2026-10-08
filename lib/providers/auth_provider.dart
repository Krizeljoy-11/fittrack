import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/utils/error_messages.dart';
import '../services/auth_service.dart';

/// UI-facing state for Firebase Authentication.
///
/// Screens listen to this via `context.watch<AuthProvider>()` and never call
/// `FirebaseAuth` directly. All methods resolve to `false` (never throw) when
/// something went wrong; the message lands in [errorMessage] for the screen
/// to render.
class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? service}) : _service = service ?? AuthService() {
    _user = _service.currentUser;
    _subscription = _service.authStateChanges.listen(
      (User? user) {
        _user = user;
        if (_busy) _busy = false;
        notifyListeners();
      },
      onError: (Object error) {
        _error = describeError(error);
        _busy = false;
        notifyListeners();
      },
    );
  }

  final AuthService _service;
  late final StreamSubscription<User?> _subscription;
  User? _user;
  bool _busy = false;
  String? _error;

  User? get user => _user;
  String? get uid => _user?.uid;
  bool get isSignedIn => _user != null;
  bool get isBusy => _busy;
  String? get errorMessage => _error;
  bool get isConfigured => _service.isConfigured;

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) =>
      _run(() => _service.signIn(email: email, password: password));

  Future<bool> register({
    required String email,
    required String password,
  }) =>
      _run(() => _service.register(email: email, password: password));

  Future<bool> sendPasswordReset({required String email}) async {
    _start();
    try {
      await _service.sendPasswordReset(email: email);
      _error = null;
      _busy = false;
      notifyListeners();
      return true;
    } on Object catch (error) {
      _fail(error);
      return false;
    }
  }

  Future<bool> signOut() => _run(_service.signOut);

  Future<bool> _run(Future<void> Function() action) async {
    _start();
    try {
      await action();
      _error = null;
      _busy = false;
      notifyListeners();
      return true;
    } on Object catch (error) {
      _fail(error);
      return false;
    }
  }

  void _start() {
    _busy = true;
    _error = null;
    notifyListeners();
  }

  void _fail(Object error) {
    _error = describeError(error);
    _busy = false;
    notifyListeners();
    debugPrint('AuthProvider: $error');
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
