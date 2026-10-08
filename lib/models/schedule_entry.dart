import '../core/utils/map_utils.dart';

/// Lifecycle of a scheduled workout.
enum ScheduleStatus { planned, completed, skipped }

/// Supported recurrence patterns.
///
/// Only `weekly` is implemented in the first release; `none` is a one-off entry.
enum RecurrenceType { none, weekly }

/// A workout slot at `users/{uid}/schedules/{scheduleId}`.
class ScheduleEntry {
  const ScheduleEntry({
    required this.id,
    required this.routineId,
    required this.routineName,
    required this.scheduledDate,
    this.scheduledTime = '07:00',
    this.status = ScheduleStatus.planned,
    this.isRecurring = false,
    this.recurrenceType = RecurrenceType.none,
    this.daysOfWeek = const <int>[],
    this.recurrenceEndDate,
    this.reminderEnabled = false,
    this.reminderId,
    this.createdAt,
  });

  final String id;
  final String routineId;
  final String routineName;

  /// Calendar day the entry belongs to (time is stored separately).
  final DateTime scheduledDate;

  /// 24-hour wall-clock time as `HH:mm`, e.g. `07:30`.
  final String scheduledTime;

  final ScheduleStatus status;
  final bool isRecurring;
  final RecurrenceType recurrenceType;

  /// Days the entry repeats on, `1 = Monday … 7 = Sunday`.
  final List<int> daysOfWeek;
  final DateTime? recurrenceEndDate;

  final bool reminderEnabled;

  /// Platform notification id used to cancel/update the reminder.
  final int? reminderId;
  final DateTime? createdAt;

  /// Combined date + time, useful for ordering and notifications.
  DateTime get scheduledDateTime {
    final DateTime parsed = DateTime.tryParse(scheduledDate.toString()) ??
        scheduledDate;
    final List<String> parts = scheduledTime.split(':');
    final int hour = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 0;
    final int minute = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
    return DateTime(
      parsed.year,
      parsed.month,
      parsed.day,
      hour,
      minute,
    );
  }

  bool get isDone => status == ScheduleStatus.completed;

  factory ScheduleEntry.fromMap(String id, Map<String, dynamic> map) {
    return ScheduleEntry(
      id: id,
      routineId: asString(map['routineId']) ?? '',
      routineName: asString(map['routineName']) ?? '',
      scheduledDate: asDateTime(map['scheduledDate']) ?? DateTime.now(),
      scheduledTime: asString(map['scheduledTime']) ?? '07:00',
      status: enumFromString<ScheduleStatus>(
        ScheduleStatus.values,
        map['status'],
        ScheduleStatus.planned,
      ),
      isRecurring: asBool(map['isRecurring']),
      recurrenceType: enumFromString<RecurrenceType>(
        RecurrenceType.values,
        map['recurrenceType'],
        RecurrenceType.none,
      ),
      daysOfWeek: asIntList(map['daysOfWeek']),
      recurrenceEndDate: asDateTime(map['recurrenceEndDate']),
      reminderEnabled: asBool(map['reminderEnabled']),
      reminderId: asInt(map['reminderId']),
      createdAt: asDateTime(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'routineId': routineId,
      'routineName': routineName,
      'scheduledDate': scheduledDate,
      'scheduledTime': scheduledTime,
      'status': status.name,
      'isRecurring': isRecurring,
      'recurrenceType': recurrenceType.name,
      'daysOfWeek': daysOfWeek,
      'recurrenceEndDate': recurrenceEndDate,
      'reminderEnabled': reminderEnabled,
      'reminderId': reminderId,
      'createdAt': createdAt,
    };
  }

  ScheduleEntry copyWith({
    String? routineId,
    String? routineName,
    DateTime? scheduledDate,
    String? scheduledTime,
    ScheduleStatus? status,
    bool? isRecurring,
    RecurrenceType? recurrenceType,
    List<int>? daysOfWeek,
    DateTime? recurrenceEndDate,
    bool? reminderEnabled,
    int? reminderId,
    DateTime? createdAt,
  }) {
    return ScheduleEntry(
      id: id,
      routineId: routineId ?? this.routineId,
      routineName: routineName ?? this.routineName,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      status: status ?? this.status,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      recurrenceEndDate: recurrenceEndDate ?? this.recurrenceEndDate,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderId: reminderId ?? this.reminderId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
