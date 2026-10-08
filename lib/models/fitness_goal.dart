/// The training focus a member picks for their profile.
///
/// Stored on `users/{uid}.fitnessGoal` as the human-readable [label], so the
/// Firestore document reads exactly like the option in the UI. The set is
/// deliberately closed: the edit screen offers these choices instead of free
/// text.
enum FitnessGoal {
  generalFitness('General Fitness'),
  weightManagement('Weight Management'),
  strength('Strength'),
  endurance('Endurance'),
  flexibility('Flexibility');

  const FitnessGoal(this.label);

  /// Value written to and read from Firestore.
  final String label;

  /// Parses a stored value; missing or unknown values return `null` so a
  /// profile never silently inherits a goal the member did not pick.
  static FitnessGoal? fromValue(Object? value) {
    if (value is! String || value.isEmpty) return null;
    for (final FitnessGoal goal in values) {
      if (goal.label == value || goal.name == value) return goal;
    }
    return null;
  }
}
