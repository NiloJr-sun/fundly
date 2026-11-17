import 'package:drift/drift.dart';

/// Keeps managed Plans rows in sync with their accounts. Raw SQL also works
/// inside migrations and while restoring old backups. Call in a transaction.
Future<void> syncLiabilityPlanCategories(
  DatabaseConnectionUser database,
) async {
  final accounts = await database
      .customSelect(
        "SELECT id, name, is_archived FROM accounts WHERE type IN ('credit', 'loan') ORDER BY id",
      )
      .get();
  for (final account in accounts) {
    final accountId = account.read<int>('id');
    final archived = account.read<bool>('is_archived');
    final existing = await database
        .customSelect(
          'SELECT id FROM categories WHERE linked_account_id = ?',
          variables: [Variable.withInt(accountId)],
        )
        .getSingleOrNull();
    if (existing == null && archived) continue;
    final categoryId = existing?.read<int>('id');
    final accountName = account.read<String>('name');
    var name = accountName;
    var suffixIndex = 0;
    while ((await database
            .customSelect(
              'SELECT id FROM categories WHERE name = ? COLLATE NOCASE AND id != ?',
              variables: [
                Variable.withString(name),
                Variable.withInt(categoryId ?? -1),
              ],
            )
            .get())
        .isNotEmpty) {
      final suffix =
          ' (debt $accountId${suffixIndex == 0 ? '' : '-$suffixIndex'})';
      final maxPrefix = 40 - suffix.length;
      name =
          '${accountName.substring(0, accountName.length > maxPrefix ? maxPrefix : accountName.length)}$suffix';
      suffixIndex++;
    }
    if (categoryId == null) {
      await database.customStatement(
        "INSERT INTO categories (name, kind, plan_group, is_archived, linked_account_id) VALUES (?, 'spending', 'liability', ?, ?)",
        [name, archived, accountId],
      );
    } else {
      await database.customStatement(
        'UPDATE categories SET name = ?, is_archived = ? WHERE id = ?',
        [name, archived, categoryId],
      );
    }
  }
  // Raw writes must notify category streams, including when only an account
  // rename or archive changed the rendered Plans rows.
  database.notifyUpdates({const TableUpdate('categories')});
}
