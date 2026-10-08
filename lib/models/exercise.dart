import '../core/utils/map_utils.dart';

/// One entry of the shared, read-only exercise catalog at `exercises/{id}`.
///
/// The catalog is seeded/managed outside the mobile app: clients may read it
/// but never create, update or delete entries (enforced by Firestore rules).
class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    this.muscleGroup = '',
    this.equipment = '',
    this.description = '',
  });

  final String id;
  final String name;
  final String muscleGroup;
  final String equipment;
  final String description;

  factory Exercise.fromMap(String id, Map<String, dynamic> map) {
    return Exercise(
      id: id,
      name: asString(map['name']) ?? '',
      muscleGroup: asString(map['muscleGroup']) ?? '',
      equipment: asString(map['equipment']) ?? '',
      description: asString(map['description']) ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'muscleGroup': muscleGroup,
      'equipment': equipment,
      'description': description,
    };
  }

  Exercise copyWith({
    String? name,
    String? muscleGroup,
    String? equipment,
    String? description,
  }) {
    return Exercise(
      id: id,
      name: name ?? this.name,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      equipment: equipment ?? this.equipment,
      description: description ?? this.description,
    );
  }
}
