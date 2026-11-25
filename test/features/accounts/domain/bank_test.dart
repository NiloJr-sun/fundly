import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fundly/features/accounts/domain/bank.dart';

void main() {
  test('the starting list of banks (BANKS_PLAN.md, B-1)', () {
    expect(
      [for (final bank in builtInBanks) bank.name],
      [
        'BDO',
        'BPI',
        'Metrobank',
        'Land Bank',
        'PNB',
        'Security Bank',
        'UnionBank',
        'RCBC',
        'China Bank',
        'EastWest',
        'GCash',
        'Maya',
        'GoTyme',
        'SeaBank',
        'CIMB',
        'Tonik',
      ],
    );
  });

  test('keys have the server shape and, like names, are unique', () {
    final keys = [for (final bank in builtInBanks) bank.key];
    expect(keys, everyElement(matches(RegExp(r'^[a-z0-9]{1,32}$'))));
    expect(keys.toSet(), hasLength(keys.length));
    final names = {for (final bank in builtInBanks) bank.name.toLowerCase()};
    expect(names, hasLength(builtInBanks.length));
  });

  test('looks a bank up by key; an unknown key is no bank', () {
    expect(builtInBankByKey('gcash'), const Bank(key: 'gcash', name: 'GCash'));
    expect(builtInBankByKey('komo'), isNull);
    expect(builtInBankByKey('GCASH'), isNull);
  });

  test('built-in names are recognised ignoring ASCII case only', () {
    expect(isBuiltInBankName('BDO'), isTrue);
    expect(isBuiltInBankName('land bank'), isTrue);
    expect(isBuiltInBankName('SECURITY BANK'), isTrue);
    expect(isBuiltInBankName('Land  Bank'), isFalse);
    expect(isBuiltInBankName('Town Coop'), isFalse);
    // The server folds A-Z only, so a dotless capital I stays different.
    expect(isBuiltInBankName('GCASHİ'), isFalse);
  });

  test('the server refuses exactly these names for custom banks', () {
    final migration = File('supabase/migrations/20261126010000_banks.sql')
        .readAsStringSync();
    final list = RegExp(
      r'builtin_bank_name\(value text\)[\s\S]*?array\[([\s\S]*?)\]',
    ).firstMatch(migration)!.group(1)!;
    final serverNames = [
      for (final match in RegExp(r"'([^']*)'").allMatches(list)) match[1],
    ];
    expect(serverNames, [
      for (final bank in builtInBanks) bank.name.toLowerCase(),
    ]);
  });
}
