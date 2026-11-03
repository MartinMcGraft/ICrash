import 'package:cloud_firestore/cloud_firestore.dart';

/// Converts a Firestore field value (`Timestamp`, already a `DateTime`, or
/// absent) into a `DateTime?`. Domain entities stay Firestore-agnostic and
/// only ever see plain `DateTime`s.
DateTime? timestampToDateTime(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}

/// Returns a copy of [data] with every field in [keys] converted from a
/// Firestore `Timestamp` to a plain `DateTime`, so entity `fromMap`
/// constructors can safely cast them without importing `cloud_firestore`.
Map<String, Object?> normalizeTimestamps(Map<String, Object?> data, List<String> keys) {
  final copy = Map<String, Object?>.from(data);
  for (final key in keys) {
    if (copy.containsKey(key)) {
      copy[key] = timestampToDateTime(copy[key]);
    }
  }
  return copy;
}
