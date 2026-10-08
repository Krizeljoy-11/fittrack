import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/goal.dart';

/// Firestore access for `users/{uid}/goals/{goalId}`.
///
/// `Goal` carries no timestamp fields, so ordering happens in memory.
class GoalRepository {
  CollectionReference<Map<String, dynamic>> _collection(String uid) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('goals');

  Stream<List<Goal>> watch(String uid) {
    return _collection(uid).snapshots().map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) => _sorted(
            snapshot.docs
                .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                    Goal.fromMap(doc.id, doc.data()))
                .toList(),
          ),
        );
  }

  Future<List<Goal>> fetch(String uid) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _collection(uid).get();
    return _sorted(
      snapshot.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
              Goal.fromMap(doc.id, doc.data()))
          .toList(),
    );
  }

  Future<Goal?> getById(String uid, String goalId) async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _collection(uid).doc(goalId).get();
    if (!snapshot.exists || snapshot.data() == null) return null;
    return Goal.fromMap(snapshot.id, snapshot.data()!);
  }

  Future<String> create(String uid, Goal goal) async {
    final DocumentReference<Map<String, dynamic>> doc = _collection(uid).doc();
    await doc.set(goal.toMap());
    return doc.id;
  }

  Future<void> update(String uid, Goal goal) async {
    await _collection(uid).doc(goal.id).update(goal.toMap());
  }

  Future<void> delete(String uid, String goalId) async {
    await _collection(uid).doc(goalId).delete();
  }

  List<Goal> _sorted(List<Goal> goals) {
    goals.sort((Goal a, Goal b) {
      final DateTime? left = a.dueDate ?? a.startDate;
      final DateTime? right = b.dueDate ?? b.startDate;
      if (left == null && right == null) return 0;
      if (left == null) return 1;
      if (right == null) return -1;
      return right.compareTo(left);
    });
    return goals;
  }
}
