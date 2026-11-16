import 'package:fundly/core/money/money.dart';
import 'package:fundly/core/time/calendar_date.dart';
import 'package:fundly/features/accounts/domain/account.dart';
import 'package:fundly/features/accounts/domain/account_type.dart';
import 'package:fundly/features/categories/domain/category.dart';
import 'package:fundly/features/transactions/domain/transaction.dart';
import 'package:fundly/features/transactions/domain/transaction_type.dart';

Money php(int minorUnits) => Money(minorUnits: minorUnits, currencyCode: 'PHP');

final today = CalendarDate(2026, 11, 16);

Account _account(
  int id,
  String name,
  AccountType type, {
  bool archived = false,
}) => Account(
  id: id,
  name: name,
  type: type,
  openingBalance: php(0),
  createdAt: DateTime.utc(2026, 11, 1),
  isArchived: archived,
);

// Account ids used across transaction tests.
const bdoId = 1;
const walletId = 2;
const rcbcCardId = 3;
const carLoanId = 4;
const oldWalletId = 5; // archived

final accounts = <int, Account>{
  bdoId: _account(bdoId, 'BDO Savings', AccountType.savingsCash),
  walletId: _account(walletId, 'Cash Wallet', AccountType.savingsCash),
  rcbcCardId: _account(rcbcCardId, 'RCBC Credit', AccountType.credit),
  carLoanId: _account(carLoanId, 'Car Loan', AccountType.loan),
  oldWalletId: _account(
    oldWalletId,
    'Old Wallet',
    AccountType.savingsCash,
    archived: true,
  ),
};

const foodId = 10;
const salaryId = 20;

final categories = <int, Category>{
  foodId: const Category(id: foodId, name: 'Food', kind: CategoryKind.spending),
  salaryId: const Category(
    id: salaryId,
    name: 'Salary',
    kind: CategoryKind.inflow,
  ),
};

TransactionDraft spending({
  int amount = 50000,
  int? from = bdoId,
  int? to,
  int? category = foodId,
  String payee = 'SM Supermarket',
}) => TransactionDraft(
  type: TransactionType.spending,
  amount: php(amount),
  date: today,
  payee: payee,
  categoryId: category,
  sourceAccountId: from,
  destinationAccountId: to,
);

TransactionDraft inflow({
  int amount = 3000000,
  int? from,
  int? to = bdoId,
  int? category = salaryId,
  String payee = 'Employer',
}) => TransactionDraft(
  type: TransactionType.inflow,
  amount: php(amount),
  date: today,
  payee: payee,
  categoryId: category,
  sourceAccountId: from,
  destinationAccountId: to,
);

TransactionDraft transfer({
  int amount = 200000,
  int? from = bdoId,
  int? to = walletId,
  int? category,
}) => TransactionDraft(
  type: TransactionType.transfer,
  amount: php(amount),
  date: today,
  categoryId: category,
  sourceAccountId: from,
  destinationAccountId: to,
);

TransactionDraft cardPayment({
  int amount = 300000,
  int? from = bdoId,
  int? to = rcbcCardId,
}) => TransactionDraft(
  type: TransactionType.creditCardPayment,
  amount: php(amount),
  date: today,
  sourceAccountId: from,
  destinationAccountId: to,
);

/// Saves [draft] as a transaction with id 1.
Transaction saved(TransactionDraft draft) => Transaction(
  id: 1,
  type: draft.type,
  amount: draft.amount,
  date: draft.date,
  payee: draft.payee,
  categoryId: draft.categoryId,
  sourceAccountId: draft.sourceAccountId,
  destinationAccountId: draft.destinationAccountId,
  note: draft.note,
  createdAt: DateTime.utc(2026, 11, 16, 9),
  updatedAt: DateTime.utc(2026, 11, 16, 9),
);
