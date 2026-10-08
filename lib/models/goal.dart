import '../core/utils/map_utils.dart';

/// What a goal measures.
enum GoalType {
  workoutsPerWeek,
  totalMinutes,
  workoutStreak,
}

/// Lifecycle of a goal.
enum GoalStatus { active, completed, cancelled }

/// A fitness goal at `users/{uid}/goals/{goalId}`.
class Goal {
  const Goal({
    required this.id,
    required this.type,
    required this.target,
    required this.unit,
    this.current = 0,
    this.status = GoalStatus.active,
    this.startDate,
    this.dueDate,
  });

  final String id;
  final GoalType type;
  final double target;
  final double current;
  final String unit;
  final GoalStatus status;
  final DateTime? startDate;
  final DateTime? dueDate;

  /// Completion ratio in the range 0…1 (returns 0 when target is 0).
  double get progress {
    if (target == 0) return 0;
    final double ratio = current / target;
    if (ratio < 0) return 0;
    if (ratio > 1) return 1;
    return ratio;
  }

  bool get isAchieved => target > 0 && current >= target;

  factory Goal.fromMap(String id, Map<String, dynamic> map) {
    return Goal(
      id: id,
      type: enumFromString<GoalType>(
        GoalType.values,
        map['type'],
        GoalType.workoutsPerWeek,
      ),
      target: asDouble(map['target']) ?? 0,
      current: asDouble(map['current']) ?? 0,
      unit: asString(map['unit']) ?? '',
      status: enumFromString<GoalStatus>(
        GoalStatus.values,
        map['status'],
        GoalStatus.active,
      ),
      startDate: asDateTime(map['startDate']),
      dueDate: asDateTime(map['dueDate']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'type': type.name,
      'target': target,
      'current': current,
      'unit': unit,
      'status': status.name,
      'startDate': startDate,
      'dueDate': dueDate,
    };
  }

  Goal copyWith({
    GoalType? type,
    double? target,
    double? current,
    String? unit,
    GoalStatus? status,
    DateTime? startDate,
    DateTime? dueDate,
  }) {
    return Goal(
      id: id,
      type: type ?? this.type,
      target: target ?? this.target,
      current: current ?? this.current,
      unit: unit ?? this.unit,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      dueDate: dueDate ?? this.dueDate,
    );
  }
}
