import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';

/// Firestore access for the `users/{uid}` profile document.
class UserRepository {
  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid);

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
  Future<void> createIfMissing(AppUser user) async {
    final DateTime now = DateTime.now();
    final Map<String, dynamic> data = user.toMap()
      ..['createdAt'] = now
      ..['updatedAt'] = now;
    await _doc(user.uid).set(data, SetOptions(merge: true));
  }

  /// Merges profile changes; never touches `createdAt`.
  Future<void> update(AppUser user) async {
    final Map<String, dynamic> data = user.toMap()
      ..remove('createdAt')
      ..['updatedAt'] = DateTime.now();
    await _doc(user.uid).set(data, SetOptions(merge: true));
  }
}
