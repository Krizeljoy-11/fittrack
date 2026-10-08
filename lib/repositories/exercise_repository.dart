import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/exercise.dart';

/// Read-only access to the shared exercise catalog at `exercises/{id}`.
///
/// The catalog is seeded outside the app. Firestore security rules allow
/// authenticated users to **read** only — there are deliberately no create,
/// update or delete helpers here, and no admin panel is planned. Tests
/// inject a fake instead of a real Firebase project.
abstract class ExerciseRepository {
  /// `false` until Firebase has been configured for this build, so callers can
  /// skip work (and show a friendly notice) instead of crashing.
  bool get isConfigured;

  /// The full catalog ordered by name.
  Stream<List<Exercise>> watchAll();

  /// One-shot load of the full catalog ordered by name.
  Future<List<Exercise>> fetchAll();

  /// A single catalog entry, or `null` when it does not exist.
  Future<Exercise?> getById(String exerciseId);
}

/// Firestore-backed [ExerciseRepository] for the `exercises` collection.
class FirestoreExerciseRepository implements ExerciseRepository {
  FirestoreExerciseRepository({FirebaseFirestore? firestore})
      : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;

  /// Resolved lazily: touching `FirebaseFirestore.instance` before Firebase
  /// has been configured throws, so it must never run in the constructor.
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  @override
  bool get isConfigured => Firebase.apps.isNotEmpty;

  CollectionReference<Map<String, dynamic>> get _catalog =>
      _firestore.collection('exercises');

  @override
  Stream<List<Exercise>> watchAll() {
    return _catalog.orderBy('name').snapshots().map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs
              .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                  Exercise.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  @override
  Future<List<Exercise>> fetchAll() async {
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _catalog.orderBy('name').get();
    return snapshot.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
            Exercise.fromMap(doc.id, doc.data()))
        .toList();
  }

  @override
  Future<Exercise?> getById(String exerciseId) async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _catalog.doc(exerciseId).get();
    if (!snapshot.exists || snapshot.data() == null) return null;
    return Exercise.fromMap(snapshot.id, snapshot.data()!);
  }
}
