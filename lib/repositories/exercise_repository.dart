import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/exercise.dart';

/// Read-only access to the shared exercise catalog at `exercises/{id}`.
///
/// The catalog is seeded outside the app. Firestore security rules allow
/// authenticated users to **read** only — there are deliberately no create,
/// update or delete helpers here, and no admin panel is planned.
class ExerciseRepository {
  CollectionReference<Map<String, dynamic>> get _catalog =>
      FirebaseFirestore.instance.collection('exercises');

  Stream<List<Exercise>> watchAll() {
    return _catalog.orderBy('name').snapshots().map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs
              .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                  Exercise.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<List<Exercise>> fetchAll() async {
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _catalog.orderBy('name').get();
    return snapshot.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
            Exercise.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<Exercise?> getById(String exerciseId) async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _catalog.doc(exerciseId).get();
    if (!snapshot.exists || snapshot.data() == null) return null;
    return Exercise.fromMap(snapshot.id, snapshot.data()!);
  }
}
