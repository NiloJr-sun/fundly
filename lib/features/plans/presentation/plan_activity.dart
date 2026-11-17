import 'package:flutter/material.dart';

import '../../../core/time/calendar_month.dart';
import '../../categories/domain/category.dart';
import '../../transactions/domain/transaction_filter.dart';
import '../../transactions/presentation/all_transactions_screen.dart';

/// Opens exactly the transactions that contribute to this row's Activity.
void showPlanActivity(
  BuildContext context,
  CalendarMonth month,
  Category category,
) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => AllTransactionsScreen(
        initialFilter: TransactionFilter(
          dateRange: month.dateRange,
          categoryId: category.linkedAccountId == null ? category.id : null,
          accountId: category.linkedAccountId,
          paymentAccountId: category.linkedAccountId,
        ),
      ),
    ),
  );
}
