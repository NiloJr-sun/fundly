import 'package:flutter/foundation.dart';

/// A bank or e-wallet built into the app, which an account can belong to
/// (docs/BANKS_PLAN.md, B-1). Presentation only: no balance or transaction
/// rule depends on an account's bank.
///
/// [key] is what accounts store and the server receives. Keys are stable:
/// never change or reuse one. A key this app does not know (added by a later
/// version) is shown as no bank.
@immutable
final class Bank {
  const Bank({required this.key, required this.name});

  /// Lower-case letters and digits, 1-32 characters (the server's check).
  final String key;
  final String name;

  @override
  bool operator ==(Object other) =>
      other is Bank && other.key == key && other.name == name;

  @override
  int get hashCode => Object.hash(key, name);

  @override
  String toString() => 'Bank($key, "$name")';
}

/// The built-in banks, in the order the picker lists them: major banks, then
/// digital banks and e-wallets.
///
/// The names must match `fundly_private.builtin_bank_name` on the server
/// (supabase/migrations/20261126010000_banks.sql), which refuses them as
/// custom bank names; a test checks it.
const List<Bank> builtInBanks = [
  Bank(key: 'bdo', name: 'BDO'),
  Bank(key: 'bpi', name: 'BPI'),
  Bank(key: 'metrobank', name: 'Metrobank'),
  Bank(key: 'landbank', name: 'Land Bank'),
  Bank(key: 'pnb', name: 'PNB'),
  Bank(key: 'securitybank', name: 'Security Bank'),
  Bank(key: 'unionbank', name: 'UnionBank'),
  Bank(key: 'rcbc', name: 'RCBC'),
  Bank(key: 'chinabank', name: 'China Bank'),
  Bank(key: 'eastwest', name: 'EastWest'),
  Bank(key: 'gcash', name: 'GCash'),
  Bank(key: 'maya', name: 'Maya'),
  Bank(key: 'gotyme', name: 'GoTyme'),
  Bank(key: 'seabank', name: 'SeaBank'),
  Bank(key: 'cimb', name: 'CIMB'),
  Bank(key: 'tonik', name: 'Tonik'),
];

/// The built-in bank with [key], or `null` when this app does not know it.
Bank? builtInBankByKey(String key) {
  for (final bank in builtInBanks) {
    if (bank.key == key) return bank;
  }
  return null;
}

/// Whether [name] (already trimmed) is a built-in bank's name, ignoring ASCII
/// case, like the server. A custom bank cannot use one.
bool isBuiltInBankName(String name) {
  final folded = _foldAscii(name);
  return builtInBanks.any((bank) => _foldAscii(bank.name) == folded);
}

String _foldAscii(String text) => String.fromCharCodes([
  for (final unit in text.codeUnits)
    unit >= 0x41 && unit <= 0x5A ? unit + 0x20 : unit,
]);
