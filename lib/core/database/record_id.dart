/// Conversion between the app's record IDs and the local database's keys.
///
/// The app identifies records with `String` IDs, so that synchronized records
/// can use UUIDs (cloud sync S5). The local database still keys rows by
/// auto-increment integers; repositories convert at this boundary only.
library;

/// The record ID of a local database row.
String recordIdOf(int rowId) => rowId.toString();

/// The nullable form of [recordIdOf], for optional references.
String? recordIdOrNull(int? rowId) => rowId?.toString();

/// The local database key of [recordId].
///
/// Throws an [ArgumentError] when [recordId] is not a local key, for example
/// a UUID from a synchronized store passed to a local repository.
int rowIdOf(String recordId) {
  final rowId = int.tryParse(recordId);
  if (rowId == null || rowId.toString() != recordId) {
    throw ArgumentError.value(recordId, 'recordId', 'not a local record ID');
  }
  return rowId;
}

/// The nullable form of [rowIdOf], for optional references.
int? rowIdOrNull(String? recordId) =>
    recordId == null ? null : rowIdOf(recordId);
