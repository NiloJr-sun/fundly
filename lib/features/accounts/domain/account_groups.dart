import 'package:flutter/foundation.dart';

import 'account.dart';
import 'account_type.dart';
import 'custom_account_type.dart';

/// The accounts shown under one account type: a built-in [type], or the
/// [customType] based on it.
@immutable
final class AccountGroup {
  const AccountGroup({
    required this.type,
    required this.customType,
    required this.accounts,
  });

  /// The built-in type whose rules the accounts follow.
  final AccountType type;

  /// `null` for the built-in [type] itself.
  final CustomAccountType? customType;

  final List<Account> accounts;

  AccountClass get accountClass => type.accountClass;
}

/// Groups [accounts] by account type, keeping their order within each group.
///
/// Groups are ordered by class (assets, then liabilities); within a class,
/// built-in types come first in [AccountType] order, then custom types by
/// name ignoring case. Types without accounts are left out. An account whose
/// custom type is not in [customTypes] is shown under its built-in type.
List<AccountGroup> groupAccounts(
  Iterable<Account> accounts,
  Iterable<CustomAccountType> customTypes,
) {
  final customById = {for (final custom in customTypes) custom.id: custom};
  final builtIn = <AccountType, List<Account>>{};
  final custom = <int, List<Account>>{};
  for (final account in accounts) {
    final customType = customById[account.customTypeId];
    if (customType == null) {
      builtIn.putIfAbsent(account.type, () => []).add(account);
    } else {
      custom.putIfAbsent(customType.id, () => []).add(account);
    }
  }

  final sortedCustom = [for (final id in custom.keys) customById[id]!]
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  return [
    for (final accountClass in AccountClass.values) ...[
      for (final type in AccountType.values)
        if (type.accountClass == accountClass && builtIn[type] != null)
          AccountGroup(type: type, customType: null, accounts: builtIn[type]!),
      for (final customType in sortedCustom)
        if (customType.baseType.accountClass == accountClass)
          AccountGroup(
            type: customType.baseType,
            customType: customType,
            accounts: custom[customType.id]!,
          ),
    ],
  ];
}
