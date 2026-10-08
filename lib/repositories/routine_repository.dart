import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/routine.dart';

/// Firestore access for `users/{uid}/routines/{routineId}`.
class RoutineRepository {
  CollectionReference<Map<String, dynamic>> _collection(String uid) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('routines');

  Stream<List<Routine>> watch(String uid) {
    return _collection(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs
              .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                  Routine.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<Routine?> getById(String uid, String routineId) async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _collection(uid).doc(routineId).get();
    if (!snapshot.exists || snapshot.data() == null) return null;
    return Routine.fromMap(snapshot.id, snapshot.data()!);
  }

  Future<String> create(String uid, Routine routine) async {
    final DateTime now = DateTime.now();
    final DocumentReference<Map<String, dynamic>> doc = _collection(uid).doc();
    await doc.set(
      routine.copyWith(createdAt: now, updatedAt: now).toMap(),
    );
    return doc.id;
  }

  Future<void> update(String uid, Routine routine) async {
    await _collection(uid).doc(routine.id).update(
          routine.copyWith(updatedAt: DateTime.now()).toMap(),
        );
  }

  Future<void> delete(String uid, String routineId) async {
    await _collection(uid).doc(routineId).delete();
  }
}
