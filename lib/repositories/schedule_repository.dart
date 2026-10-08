import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/schedule_entry.dart';

/// Firestore access for `users/{uid}/schedules/{scheduleId}`.
class ScheduleRepository {
  CollectionReference<Map<String, dynamic>> _collection(String uid) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('schedules');

  Stream<List<ScheduleEntry>> watch(String uid) {
    return _collection(uid)
        .orderBy('scheduledDate')
        .snapshots()
        .map(_toList);
  }

  /// Entries falling on a single calendar [day].
  Stream<List<ScheduleEntry>> watchDay(String uid, DateTime day) {
    final DateTime start = DateTime(day.year, day.month, day.day);
    final DateTime end = start.add(const Duration(days: 1));
    return _collection(uid)
        .where('scheduledDate', isGreaterThanOrEqualTo: start)
        .where('scheduledDate', isLessThan: end)
        .orderBy('scheduledDate')
        .snapshots()
        .map(_toList);
  }

  Future<ScheduleEntry?> getById(String uid, String entryId) async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _collection(uid).doc(entryId).get();
    if (!snapshot.exists || snapshot.data() == null) return null;
    return ScheduleEntry.fromMap(snapshot.id, snapshot.data()!);
  }

  Future<String> create(String uid, ScheduleEntry entry) async {
    final DocumentReference<Map<String, dynamic>> doc = _collection(uid).doc();
    await doc.set(
      entry.copyWith(createdAt: DateTime.now()).toMap(),
    );
    return doc.id;
  }

  Future<void> update(String uid, ScheduleEntry entry) async {
    await _collection(uid).doc(entry.id).update(entry.toMap());
  }

  Future<void> delete(String uid, String entryId) async {
    await _collection(uid).doc(entryId).delete();
  }

  List<ScheduleEntry> _toList(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
            ScheduleEntry.fromMap(doc.id, doc.data()))
        .toList();
  }
}
