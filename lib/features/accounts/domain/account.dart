import 'package:flutter/foundation.dart';

import '../../../core/money/money.dart';
import 'account_type.dart';

/// The bank an account belongs to: a built-in bank's key, a custom bank's ID,
/// or neither (no bank). Never both.
typedef AccountBank = ({String? bankKey, String? customBankId});

/// A financial account owned by the user.
///
/// [openingBalance] is signed (CLAUDE.md §11, D1): asset accounts are usually
/// zero or positive, and liability accounts are negative when money is owed.
/// Use `openingBalanceFor` and `enteredAmountFor` in `account_rules.dart` to
/// convert between this value and the positive amount the user types.
@immutable
final class Account {
  const Account({
    required this.id,
    required this.name,
    required this.type,
    required this.openingBalance,
    required this.createdAt,
    this.isArchived = false,
    this.customTypeId,
    this.isBudgetAccount = false,
    this.bankKey,
    this.customBankId,
  });

  /// Currency for every account in the MVP (CLAUDE.md §11, G6).
  static const String defaultCurrency = 'PHP';

  /// Database-assigned identifier (CLAUDE.md §11, D7).
  final String id;
  final String name;

  /// Fixed after creation, so [copyWith] cannot change it.
  final AccountType type;
  final Money openingBalance;

  /// When the account was created, in UTC.
  final DateTime createdAt;
  final bool isArchived;

  /// The custom type the account is shown under, or `null` for the built-in
  /// [type]. A custom type always has [type] as its base type, so every
  /// accounting rule keeps using [type].
  final String? customTypeId;

  /// Whether money coming into this account funds Ready to assign on Plans.
  /// At most one account is the budget account, and it is Savings/Cash.
  final bool isBudgetAccount;

  /// The built-in bank the account belongs to (`Bank.key`), or `null`. A key
  /// this app does not know, from a later version, is shown as no bank.
  final String? bankKey;

  /// The custom bank the account belongs to, or `null`. At most one of
  /// [bankKey] and [customBankId] is set. Presentation only (BANKS_PLAN.md).
  final String? customBankId;

  /// The account's bank as one value.
  AccountBank get bank => (bankKey: bankKey, customBankId: customBankId);

  String get currencyCode => openingBalance.currencyCode;

  /// Returns a copy with the editable fields replaced. [id], [type] and
  /// [createdAt] cannot change after creation; [customTypeId] and the bank
  /// are kept.
  Account copyWith({String? name, Money? openingBalance, bool? isArchived}) {
    return Account(
      id: id,
      name: name ?? this.name,
      type: type,
      openingBalance: openingBalance ?? this.openingBalance,
      createdAt: createdAt,
      isArchived: isArchived ?? this.isArchived,
      customTypeId: customTypeId,
      isBudgetAccount: isBudgetAccount,
      bankKey: bankKey,
      customBankId: customBankId,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Account &&
      other.id == id &&
      other.name == name &&
      other.type == type &&
      other.openingBalance == openingBalance &&
      other.createdAt == createdAt &&
      other.isArchived == isArchived &&
      other.customTypeId == customTypeId &&
      other.isBudgetAccount == isBudgetAccount &&
      other.bankKey == bankKey &&
      other.customBankId == customBankId;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    type,
    openingBalance,
    createdAt,
    isArchived,
    customTypeId,
    isBudgetAccount,
    bankKey,
    customBankId,
  );

  @override
  String toString() =>
      'Account($id, "$name", ${type.name}'
      '${customTypeId == null ? '' : ' (custom type $customTypeId)'}, '
      '$openingBalance'
      '${bankKey == null ? '' : ', bank $bankKey'}'
      '${customBankId == null ? '' : ', custom bank $customBankId'}'
      '${isBudgetAccount ? ', budget account' : ''}'
      '${isArchived ? ', archived' : ''})';
}
