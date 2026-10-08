/// Small helpers for turning untyped Firestore/JSON maps into Dart values.
///
/// Keeping these in one place means every model can read missing, null or
/// legacy fields without repeating defensive code.
library;

DateTime? asDateTime(Object? value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return null;
}

double? asDouble(Object? value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int? asInt(Object? value) {
  if (value is int) return value;
  if (value is double) return value.round();
  if (value is String) return int.tryParse(value);
  return null;
}

String? asString(Object? value) {
  if (value == null) return null;
  if (value is String) return value;
  return value.toString();
}

bool asBool(Object? value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is String) return value.toLowerCase() == 'true';
  return fallback;
}

List<Object?> asList(Object? value) {
  if (value is List) return value;
  return const <Object?>[];
}

List<String> asStringList(Object? value) {
  return asList(value)
      .map((Object? item) => item?.toString() ?? '')
      .where((String item) => item.isNotEmpty)
      .toList();
}

List<int> asIntList(Object? value) {
  return asList(value).map(asInt).whereType<int>().toList();
}

/// Safe enum parsing: unknown/missing values fall back instead of throwing.
T enumFromString<T extends Enum>(List<T> values, Object? value, T fallback) {
  for (final T candidate in values) {
    if (candidate.name == value) return candidate;
  }
  return fallback;
}
