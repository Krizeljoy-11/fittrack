import 'package:flutter/foundation.dart';

import '../core/utils/error_messages.dart';
import '../models/app_user.dart';
import '../models/fitness_goal.dart';
import '../repositories/user_repository.dart';

/// UI state for the signed-in member's `users/{uid}` profile.
///
/// Screens watch this provider and never touch Firestore themselves: every
/// read and write goes through [UserRepository]. Like [AuthProvider], every
/// method swallows failures and reports them through [errorMessage] instead of
/// throwing, so a missing or unreachable backend can never crash the app.
class ProfileProvider extends ChangeNotifier {
  ProfileProvider({UserRepository? repository})
      : _repository = repository ?? FirestoreUserRepository();

  static const String notConfiguredMessage =
      'Firebase is not configured yet. Configure Firebase, then try again.';

  final UserRepository _repository;

  AppUser? _profile;
  String? _uid;
  bool _loading = false;
  bool _saving = false;
  String? _error;
  String? _success;

  /// Guards against a slow `load` completing after a newer one started.
  int _loadToken = 0;

  AppUser? get profile => _profile;
  String? get uid => _uid;
  bool get isLoading => _loading;
  bool get isSaving => _saving;
  String? get errorMessage => _error;
  String? get successMessage => _success;
  bool get isConfigured => _repository.isConfigured;

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  void clearSuccess() {
    if (_success == null) return;
    _success = null;
    notifyListeners();
  }

  /// Loads the profile for the authenticated [uid].
  ///
  /// When the document does not exist yet — right after registration, or the
  /// first time an existing account opens FitTrack — it is seeded from the
  /// auth record ([email] / [displayName]) via
  /// [UserRepository.createIfMissing]. That is the registration integration
  /// point: the auth flow itself stays untouched.
  Future<void> load({
    required String uid,
    String email = '',
    String displayName = '',
  }) async {
    final int token = ++_loadToken;
    _uid = uid;
    _loading = true;
    _error = null;
    _success = null;
    notifyListeners();

    try {
      if (!_repository.isConfigured) {
        // The screen renders the "not configured" notice itself.
        _profile = null;
        return;
      }
      AppUser? loaded = await _repository.get(uid);
      if (token != _loadToken) return;
      loaded ??= await _seedProfile(
        uid: uid,
        email: email,
        displayName: displayName,
      );
      if (token != _loadToken) return;
      _profile = loaded;
    } on Object catch (error) {
      if (token != _loadToken) return;
      _error = describeError(error);
      debugPrint('ProfileProvider: $error');
    } finally {
      if (token == _loadToken) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  /// Saves the edited profile and returns whether it succeeded.
  ///
  /// Builds the document from the submitted values (rather than patching the
  /// loaded one) so clearing a field actually writes `null`.
  Future<bool> save({
    required String uid,
    required String email,
    required String displayName,
    required double? height,
    required double? weight,
    required FitnessGoal fitnessGoal,
  }) async {
    _saving = true;
    _error = null;
    _success = null;
    notifyListeners();

    try {
      if (!_repository.isConfigured) {
        _error = notConfiguredMessage;
        return false;
      }
      final DateTime now = DateTime.now();
      final AppUser updated = AppUser(
        uid: uid,
        email: email,
        displayName: displayName.trim(),
        height: height,
        weight: weight,
        fitnessGoal: fitnessGoal,
        createdAt: _profile?.createdAt ?? now,
        updatedAt: now,
      );
      if (_profile == null) {
        await _repository.createIfMissing(updated);
      } else {
        await _repository.update(updated);
      }
      _uid = uid;
      _profile = updated;
      _success = 'Profile updated.';
      return true;
    } on Object catch (error) {
      _error = describeError(error);
      debugPrint('ProfileProvider: $error');
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<AppUser> _seedProfile({
    required String uid,
    required String email,
    required String displayName,
  }) async {
    final DateTime now = DateTime.now();
    final AppUser seeded = AppUser(
      uid: uid,
      email: email,
      displayName: displayName,
      createdAt: now,
      updatedAt: now,
    );
    await _repository.createIfMissing(seeded);
    return seeded;
  }
}
