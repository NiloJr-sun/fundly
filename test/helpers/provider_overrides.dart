import 'package:flutter_riverpod/misc.dart';
import 'package:fundly/features/accounts/domain/account.dart';
import 'package:fundly/features/accounts/presentation/accounts_providers.dart';

/// Overrides that keep widget tests off the real on-device database.
List<Override> fakeAccounts([List<Account> accounts = const []]) => [
  activeAccountsProvider.overrideWith((ref) => Stream.value(accounts)),
];
