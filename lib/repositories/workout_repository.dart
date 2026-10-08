import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/progress_entry.dart';
import '../models/workout_log.dart';

/// Firestore access for workout history and progress metrics.
///
/// Collections:
/// - `users/{uid}/workoutLogs/{logId}`  — one document per completed workout
/// - `users/{uid}/progress/{dayKey}`    — one document per day (keyed `yyyy-MM-dd`)
class WorkoutRepository {
  CollectionReference<Map<String, dynamic>> _logs(String uid) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('workoutLogs');

  CollectionReference<Map<String, dynamic>> _progress(String uid) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('progress');

  Stream<List<WorkoutLog>> watchLogs(String uid) {
    return _logs(uid).orderBy('startedAt', descending: true).snapshots().map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs
              .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                  WorkoutLog.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<List<WorkoutLog>> recentLogs(String uid, {int limit = 20}) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _logs(uid)
        .orderBy('startedAt', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
            WorkoutLog.fromMap(doc.id, doc.data()))
        .toList();
  }

  /// Creates or overwrites a log. `startedAt` is always persisted so the
  /// `orderBy('startedAt')` queries above can never drop the document.
  Future<String> saveLog(String uid, WorkoutLog log) async {
    final DateTime startedAt = log.startedAt ?? DateTime.now();
    final WorkoutLog withStart = log.copyWith(startedAt: startedAt);

    if (log.id.isNotEmpty) {
      await _logs(uid).doc(log.id).update(withStart.toMap());
      return log.id;
    }
    final DocumentReference<Map<String, dynamic>> doc = _logs(uid).doc();
    await doc.set(withStart.toMap());
    return doc.id;
  }

  Future<void> deleteLog(String uid, String logId) async {
    await _logs(uid).doc(logId).delete();
  }

  Stream<List<ProgressEntry>> watchProgress(String uid, {DateTime? since}) {
    return _progress(uid).orderBy('date', descending: true).snapshots().map(
      (QuerySnapshot<Map<String, dynamic>> snapshot) {
        final DateTime? cutoff = since;
        return snapshot.docs
            .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                ProgressEntry.fromMap(_dateFromKey(doc.id), doc.data()))
            .where(
                (ProgressEntry entry) => cutoff == null || !entry.date.isBefore(cutoff))
            .toList();
      },
    );
  }

  Future<ProgressEntry?> getProgress(String uid, DateTime day) async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _progress(uid).doc(_key(day)).get();
    if (!snapshot.exists || snapshot.data() == null) return null;
    return ProgressEntry.fromMap(_dateFromKey(snapshot.id), snapshot.data()!);
  }

  Future<void> saveProgress(String uid, ProgressEntry entry) async {
    await _progress(uid)
        .doc(_key(entry.date))
        .set(entry.toMap(), SetOptions(merge: true));
  }

  static String _key(DateTime day) {
    final String mm = day.month.toString().padLeft(2, '0');
    final String dd = day.day.toString().padLeft(2, '0');
    return '${day.year}-$mm-$dd';
  }

  static DateTime _dateFromKey(String key) {
    final List<String> parts = key.split('-');
    if (parts.length != 3) return DateTime.now();
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }
}
