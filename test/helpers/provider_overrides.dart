import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:fundly/features/accounts/data/account_repository.dart';
import 'package:fundly/features/accounts/domain/account.dart';
import 'package:fundly/features/accounts/domain/account_balance.dart';
import 'package:fundly/features/accounts/presentation/accounts_providers.dart';

import 'fake_account_repository.dart';

/// Overrides that keep widget tests off the real on-device database.
///
/// Account lookups by id search both [accounts] and [archived]. Balances are
/// the opening balances (no transactions). Pass [repository] to inspect what
/// screens asked it to do.
List<Override> fakeAccounts(
  List<Account> accounts, {
  List<Account> archived = const [],
  FakeAccountRepository? repository,
}) {
  Account? byId(int id) {
    for (final account in [...accounts, ...archived]) {
      if (account.id == id) return account;
    }
    return null;
  }

  return [
    activeAccountsProvider.overrideWith((ref) => Stream.value(accounts)),
    archivedAccountsProvider.overrideWith((ref) => Stream.value(archived)),
    accountByIdProvider.overrideWith((ref, id) => Stream.value(byId(id))),
    accountBalancesProvider.overrideWithValue(
      AsyncData(balancesFor([...accounts, ...archived], const [])),
    ),
    accountRepositoryProvider.overrideWithValue(
      repository ?? FakeAccountRepository(),
    ),
  ];
}

/// No accounts at all.
List<Override> noAccounts() => fakeAccounts(const []);
