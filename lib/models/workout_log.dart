import '../core/utils/map_utils.dart';

/// One performed set inside a workout log.
class LoggedSet {
  const LoggedSet({
    this.reps,
    this.weightKg,
    this.durationSeconds,
    this.completed = true,
  });

  final int? reps;
  final double? weightKg;
  final int? durationSeconds;
  final bool completed;

  factory LoggedSet.fromMap(Map<String, dynamic> map) {
    return LoggedSet(
      reps: asInt(map['reps']),
      weightKg: asDouble(map['weightKg']),
      durationSeconds: asInt(map['durationSeconds']),
      completed: asBool(map['completed'], fallback: true),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'reps': reps,
      'weightKg': weightKg,
      'durationSeconds': durationSeconds,
      'completed': completed,
    };
  }
}

/// One exercise performed during a workout, with its sets.
class LoggedExercise {
  const LoggedExercise({
    required this.exerciseId,
    required this.exerciseName,
    this.sets = const <LoggedSet>[],
  });

  final String exerciseId;
  final String exerciseName;
  final List<LoggedSet> sets;

  factory LoggedExercise.fromMap(Map<String, dynamic> map) {
    return LoggedExercise(
      exerciseId: asString(map['exerciseId']) ?? '',
      exerciseName: asString(map['exerciseName']) ?? '',
      sets: asList(map['sets'])
          .whereType<Map<String, dynamic>>()
          .map(LoggedSet.fromMap)
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'sets': sets.map((LoggedSet set) => set.toMap()).toList(),
    };
  }
}

/// A completed workout at `users/{uid}/workoutLogs/{logId}`.
///
/// `scheduleId` links the log back to the schedule entry that produced it
/// (empty when a workout was started without a schedule).
class WorkoutLog {
  const WorkoutLog({
    required this.id,
    required this.exercises,
    this.scheduleId = '',
    this.routineId = '',
    this.routineName = '',
    this.startedAt,
    this.completedAt,
    this.durationMinutes = 0,
    this.notes = '',
  });

  final String id;
  final String scheduleId;
  final String routineId;
  final String routineName;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int durationMinutes;
  final List<LoggedExercise> exercises;
  final String notes;

  int get totalSets => exercises.fold<int>(
        0,
        (int sum, LoggedExercise exercise) => sum + exercise.sets.length,
      );

  factory WorkoutLog.fromMap(String id, Map<String, dynamic> map) {
    return WorkoutLog(
      id: id,
      scheduleId: asString(map['scheduleId']) ?? '',
      routineId: asString(map['routineId']) ?? '',
      routineName: asString(map['routineName']) ?? '',
      startedAt: asDateTime(map['startedAt']),
      completedAt: asDateTime(map['completedAt']),
      durationMinutes: asInt(map['durationMinutes']) ?? 0,
      exercises: asList(map['exercises'])
          .whereType<Map<String, dynamic>>()
          .map(LoggedExercise.fromMap)
          .toList(),
      notes: asString(map['notes']) ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'scheduleId': scheduleId,
      'routineId': routineId,
      'routineName': routineName,
      'startedAt': startedAt,
      'completedAt': completedAt,
      'durationMinutes': durationMinutes,
      'exercises': exercises
          .map((LoggedExercise exercise) => exercise.toMap())
          .toList(),
      'notes': notes,
    };
  }

  WorkoutLog copyWith({
    String? scheduleId,
    String? routineId,
    String? routineName,
    DateTime? startedAt,
    DateTime? completedAt,
    int? durationMinutes,
    List<LoggedExercise>? exercises,
    String? notes,
  }) {
    return WorkoutLog(
      id: id,
      scheduleId: scheduleId ?? this.scheduleId,
      routineId: routineId ?? this.routineId,
      routineName: routineName ?? this.routineName,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      exercises: exercises ?? this.exercises,
      notes: notes ?? this.notes,
    );
  }
}
