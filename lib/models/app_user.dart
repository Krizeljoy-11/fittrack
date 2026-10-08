import '../core/utils/map_utils.dart';
import 'fitness_goal.dart';

/// The signed-in FitTrack user profile stored at `users/{uid}`.
///
/// The document id is always the authenticated user's uid; [uid] is also
/// written into the document so the stored shape matches the profile contract:
/// `uid, email, displayName, height, weight, fitnessGoal, createdAt,
/// updatedAt`.
class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    this.displayName = '',
    this.photoUrl,
    this.height,
    this.weight,
    this.fitnessGoal,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;

  /// Height in centimetres.
  final double? height;

  /// Weight in kilograms.
  final double? weight;

  /// Training focus; `null` until the member chooses one.
  final FitnessGoal? fitnessGoal;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Reads a profile document.
  ///
  /// [uid] comes from the caller (the authenticated user), never from the
  /// document, so a tampered document cannot point the UI at another account.
  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      email: asString(map['email']) ?? '',
      displayName: asString(map['displayName']) ?? '',
      photoUrl: asString(map['photoUrl']),
      height: asDouble(map['height']),
      weight: asDouble(map['weight']),
      fitnessGoal: FitnessGoal.fromValue(map['fitnessGoal']),
      createdAt: asDateTime(map['createdAt']),
      updatedAt: asDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'height': height,
      'weight': weight,
      'fitnessGoal': fitnessGoal?.label,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  AppUser copyWith({
    String? email,
    String? displayName,
    String? photoUrl,
    double? height,
    double? weight,
    FitnessGoal? fitnessGoal,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      uid: uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      fitnessGoal: fitnessGoal ?? this.fitnessGoal,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
