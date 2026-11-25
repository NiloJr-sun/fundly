import 'package:flutter/foundation.dart';

/// A bank the user added because it is not one of the built-in banks
/// (docs/BANKS_PLAN.md, B-5). Each space has its own list. Presentation only.
@immutable
final class CustomBank {
  const CustomBank({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  final String id;
  final String name;

  /// When the bank was added, in UTC.
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      other is CustomBank &&
      other.id == id &&
      other.name == name &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(id, name, createdAt);

  @override
  String toString() => 'CustomBank($id, "$name")';
}

/// Why a custom bank could not be added, renamed or deleted.
enum CustomBankValidationError {
  nameEmpty,
  nameTooLong,

  /// Another custom bank already uses this name, or it is a built-in bank's
  /// name (ignoring case).
  nameTaken,

  /// An account, active or archived, belongs to the bank, so it cannot be
  /// deleted.
  inUse,
}

class CustomBankValidationException implements Exception {
  const CustomBankValidationException(this.error);

  final CustomBankValidationError error;

  @override
  String toString() => 'CustomBankValidationException(${error.name})';
}
