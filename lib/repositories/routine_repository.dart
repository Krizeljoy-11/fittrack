import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/routine.dart';

/// Firestore access for `users/{uid}/routines/{routineId}`.
///
/// This is the boundary the UI layer depends on: screens and providers only
/// ever see this interface, while [FirestoreRoutineRepository] owns every
/// piece of Firebase access. Tests inject a fake instead of a real project.
abstract class RoutineRepository {
  /// `false` until Firebase has been configured for this build, so callers can
  /// skip work (and show a friendly notice) instead of crashing.
  bool get isConfigured;

  /// Live routines for [uid], newest first.
  Stream<List<Routine>> watch(String uid);

  /// The routine at `routines/{routineId}`, or `null` when it is gone.
  Future<Routine?> getById(String uid, String routineId);

  /// Stores a new routine and returns its document id.
  Future<String> create(String uid, Routine routine);

  /// Overwrites the routine at `routines/{routineId}`.
  Future<void> update(String uid, Routine routine);

  /// Deletes the routine at `routines/{routineId}`.
  Future<void> delete(String uid, String routineId);
}

/// Firestore-backed [RoutineRepository] for `users/{uid}/routines`.
class FirestoreRoutineRepository implements RoutineRepository {
  FirestoreRoutineRepository({FirebaseFirestore? firestore})
      : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;

  /// Resolved lazily: touching `FirebaseFirestore.instance` before Firebase
  /// has been configured throws, so it must never run in the constructor.
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  @override
  bool get isConfigured => Firebase.apps.isNotEmpty;

  CollectionReference<Map<String, dynamic>> _collection(String uid) =>
      _firestore
          .collection('users')
          .doc(uid)
          .collection('routines');

  @override
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

  @override
  Future<Routine?> getById(String uid, String routineId) async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _collection(uid).doc(routineId).get();
    if (!snapshot.exists || snapshot.data() == null) return null;
    return Routine.fromMap(snapshot.id, snapshot.data()!);
  }

  @override
  Future<String> create(String uid, Routine routine) async {
    final DateTime now = DateTime.now();
    final DocumentReference<Map<String, dynamic>> doc = _collection(uid).doc();
    await doc.set(
      routine.copyWith(createdAt: now, updatedAt: now).toMap(),
    );
    return doc.id;
  }

  @override
  Future<void> update(String uid, Routine routine) async {
    await _collection(uid).doc(routine.id).update(
          routine.copyWith(updatedAt: DateTime.now()).toMap(),
        );
  }

  @override
  Future<void> delete(String uid, String routineId) async {
    await _collection(uid).doc(routineId).delete();
  }
}
