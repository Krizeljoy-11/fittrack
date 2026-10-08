import '../core/utils/map_utils.dart';

/// The signed-in FitTrack user profile stored at `users/{uid}`.
class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    this.displayName = '',
    this.photoUrl,
    this.heightCm,
    this.weightKg,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final double? heightCm;
  final double? weightKg;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      email: asString(map['email']) ?? '',
      displayName: asString(map['displayName']) ?? '',
      photoUrl: asString(map['photoUrl']),
      heightCm: asDouble(map['heightCm']),
      weightKg: asDouble(map['weightKg']),
      createdAt: asDateTime(map['createdAt']),
      updatedAt: asDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  AppUser copyWith({
    String? email,
    String? displayName,
    String? photoUrl,
    double? heightCm,
    double? weightKg,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      uid: uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
