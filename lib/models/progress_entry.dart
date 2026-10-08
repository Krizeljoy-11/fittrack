import '../core/utils/map_utils.dart';

/// Daily training summary at `users/{uid}/progress/{yyyy-MM-dd}`.
///
/// Written whenever a workout is saved; kept intentionally simple —
/// no chart data, no derived metrics.
class ProgressEntry {
  const ProgressEntry({
    required this.date,
    this.workoutsCompleted = 0,
    this.totalMinutes = 0,
    this.streak = 0,
  });

  /// Midnight of the day this entry describes.
  final DateTime date;
  final int workoutsCompleted;
  final int totalMinutes;
  final int streak;

  String get dayKey =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  factory ProgressEntry.fromMap(DateTime date, Map<String, dynamic> map) {
    return ProgressEntry(
      date: asDateTime(map['date']) ?? date,
      workoutsCompleted: asInt(map['workoutsCompleted']) ?? 0,
      totalMinutes: asInt(map['totalMinutes']) ?? 0,
      streak: asInt(map['streak']) ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'date': date,
      'workoutsCompleted': workoutsCompleted,
      'totalMinutes': totalMinutes,
      'streak': streak,
    };
  }

  ProgressEntry copyWith({
    int? workoutsCompleted,
    int? totalMinutes,
    int? streak,
  }) {
    return ProgressEntry(
      date: date,
      workoutsCompleted: workoutsCompleted ?? this.workoutsCompleted,
      totalMinutes: totalMinutes ?? this.totalMinutes,
      streak: streak ?? this.streak,
    );
  }
}
