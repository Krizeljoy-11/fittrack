/// Reusable form validation rules.
///
/// Each rule returns `null` when the input is valid, otherwise a short message
/// suitable for showing under a `TextFormField`.
abstract final class Validators {
  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field is required.';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required.';
    }
    final String email = value.trim();
    final RegExp pattern = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');
    if (!pattern.hasMatch(email)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password.';
    }
    if (value != password) {
      return 'Passwords do not match.';
    }
    return null;
  }

  /// Display name: required, trimmed, and bounded to a sensible length.
  static String? displayName(String? value, {String field = 'Display name'}) {
    final String? missing = required(value, field: field);
    if (missing != null) return missing;
    final String name = value!.trim();
    if (name.length < 2) {
      return '$field must be at least 2 characters.';
    }
    if (name.length > 50) {
      return '$field must be 50 characters or fewer.';
    }
    return null;
  }

  static String? number(
    String? value, {
    String field = 'Value',
    double? min,
    double? max,
    bool allowEmpty = true,
  }) {
    if (value == null || value.trim().isEmpty) {
      return allowEmpty ? null : '$field is required.';
    }
    final double? parsed = double.tryParse(value.trim());
    if (parsed == null) {
      return '$field must be a number.';
    }
    if (min != null && parsed < min) {
      return '$field must be at least $min.';
    }
    if (max != null && parsed > max) {
      return '$field must be at most $max.';
    }
    return null;
  }
}
