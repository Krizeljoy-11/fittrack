import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/app_user.dart';

/// Read/write access to the `users/{uid}` profile document.
///
/// This is the boundary the UI layer depends on: screens and providers only
/// ever see this interface, while [FirestoreUserRepository] owns every piece
/// of Firebase access. Tests inject a fake instead of a real Firebase project.
abstract class UserRepository {
  /// `false` until Firebase has been configured for this build, so callers can
  /// skip work (and show a friendly notice) instead of crashing.
  bool get isConfigured;

  /// The profile for [uid], or `null` when the document does not exist yet.
  Future<AppUser?> get(String uid);

  /// Creates the profile document without overwriting anything already there.
  Future<void> createIfMissing(AppUser user);

  /// Merges profile changes; never touches `createdAt`.
  Future<void> update(AppUser user);
}

/// Firestore-backed [UserRepository] for `users/{uid}`.
class FirestoreUserRepository implements UserRepository {
  FirestoreUserRepository({FirebaseFirestore? firestore})
      : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;

  /// Resolved lazily: touching `FirebaseFirestore.instance` before Firebase
  /// has been configured throws, so it must never run in the constructor.
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  @override
  bool get isConfigured => Firebase.apps.isNotEmpty;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _firestore.collection('users').doc(uid);

  @override
  Future<AppUser?> get(String uid) async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot = await _doc(uid).get();
    if (!snapshot.exists || snapshot.data() == null) return null;
    return AppUser.fromMap(uid, snapshot.data()!);
  }

  Stream<AppUser?> watch(String uid) {
    return _doc(uid).snapshots().map(
          (DocumentSnapshot<Map<String, dynamic>> snapshot) =>
              snapshot.exists && snapshot.data() != null
                  ? AppUser.fromMap(uid, snapshot.data()!)
                  : null,
        );
  }

  /// Creates the profile document on first sign-in without overwriting
  /// anything that is already there.
  @override
  Future<void> createIfMissing(AppUser user) async {
    final DateTime now = DateTime.now();
    final Map<String, dynamic> data = user.toMap()
      ..['createdAt'] = now
      ..['updatedAt'] = now;
    await _doc(user.uid).set(data, SetOptions(merge: true));
  }

  /// Merges profile changes; never touches `createdAt`.
  @override
  Future<void> update(AppUser user) async {
    final Map<String, dynamic> data = user.toMap()
      ..remove('createdAt')
      ..['updatedAt'] = DateTime.now();
    await _doc(user.uid).set(data, SetOptions(merge: true));
  }
}
