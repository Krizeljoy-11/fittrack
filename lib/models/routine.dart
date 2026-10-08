import '../core/utils/map_utils.dart';

/// Difficulty band shown when browsing routines.
enum RoutineDifficulty { beginner, intermediate, advanced }

/// A single exercise slot inside a [Routine].
///
/// It references the shared catalog by `exerciseId` but keeps `exerciseName`
/// so routines render even if the catalog entry is renamed later.
class RoutineExercise {
  const RoutineExercise({
    required this.exerciseId,
    required this.exerciseName,
    this.sets = 3,
    this.reps,
    this.durationSeconds,
    this.restSeconds = 60,
    this.order = 0,
  });

  final String exerciseId;
  final String exerciseName;
  final int sets;
  final int? reps;
  final int? durationSeconds;
  final int restSeconds;
  final int order;

  factory RoutineExercise.fromMap(Map<String, dynamic> map) {
    return RoutineExercise(
      exerciseId: asString(map['exerciseId']) ?? '',
      exerciseName: asString(map['exerciseName']) ?? '',
      sets: asInt(map['sets']) ?? 3,
      reps: asInt(map['reps']),
      durationSeconds: asInt(map['durationSeconds']),
      restSeconds: asInt(map['restSeconds']) ?? 60,
      order: asInt(map['order']) ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'sets': sets,
      'reps': reps,
      'durationSeconds': durationSeconds,
      'restSeconds': restSeconds,
      'order': order,
    };
  }

  RoutineExercise copyWith({
    String? exerciseId,
    String? exerciseName,
    int? sets,
    int? reps,
    int? durationSeconds,
    int? restSeconds,
    int? order,
  }) {
    return RoutineExercise(
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      restSeconds: restSeconds ?? this.restSeconds,
      order: order ?? this.order,
    );
  }
}

/// A reusable workout template stored at `users/{uid}/routines/{routineId}`.
class Routine {
  const Routine({
    required this.id,
    required this.name,
    this.description = '',
    this.difficulty = RoutineDifficulty.beginner,
    this.exercises = const <RoutineExercise>[],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String description;
  final RoutineDifficulty difficulty;
  final List<RoutineExercise> exercises;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Total number of working sets in the routine.
  int get totalSets =>
      exercises.fold<int>(0, (int sum, RoutineExercise e) => sum + e.sets);

  factory Routine.fromMap(String id, Map<String, dynamic> map) {
    return Routine(
      id: id,
      name: asString(map['name']) ?? '',
      description: asString(map['description']) ?? '',
      difficulty: enumFromString<RoutineDifficulty>(
        RoutineDifficulty.values,
        map['difficulty'],
        RoutineDifficulty.beginner,
      ),
      exercises: asList(map['exercises'])
          .whereType<Map<String, dynamic>>()
          .map(RoutineExercise.fromMap)
          .toList(),
      createdAt: asDateTime(map['createdAt']),
      updatedAt: asDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'description': description,
      'difficulty': difficulty.name,
      'exercises': exercises
          .map((RoutineExercise exercise) => exercise.toMap())
          .toList(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  Routine copyWith({
    String? name,
    String? description,
    RoutineDifficulty? difficulty,
    List<RoutineExercise>? exercises,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Routine(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      exercises: exercises ?? this.exercises,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
