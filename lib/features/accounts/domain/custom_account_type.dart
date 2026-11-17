import 'package:flutter/foundation.dart';

import 'account_type.dart';

/// An account type the user created, such as "E-wallet" or "Pay later".
///
/// It follows the rules of its [baseType]: an account of this type stores
/// [baseType] as its [AccountType], so balances, allowed transactions and
/// Spending totals behave exactly as for the built-in type. The name can
/// change at any time; [baseType] only while no account uses the type.
@immutable
final class CustomAccountType {
  const CustomAccountType({
    required this.id,
    required this.name,
    required this.baseType,
    required this.createdAt,
  });

  final int id;
  final String name;
  final AccountType baseType;

  /// When the type was created, in UTC.
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      other is CustomAccountType &&
      other.id == id &&
      other.name == name &&
      other.baseType == baseType &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(id, name, baseType, createdAt);

  @override
  String toString() => 'CustomAccountType($id, "$name", ${baseType.name})';
}
