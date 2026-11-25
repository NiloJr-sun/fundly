import 'package:drift/drift.dart';

import '../../../core/sync/sync_queue.dart';
import '../../../core/sync/synced_database.dart';
import '../domain/custom_bank.dart';
import 'custom_bank_repository.dart';

/// Custom banks in the signed-in space's synchronized store. Writes apply
/// locally at once and queue `bank.create`, `bank.update` or `bank.delete`
/// for upload, with the same rules as the local store (supabase/ACCOUNT_API.md,
/// Banks).
class SyncedCustomBankRepository implements CustomBankRepository {
  SyncedCustomBankRepository(this._database, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  final SyncedDatabase _database;
  final DateTime Function() _now;

  $SyncedCustomBanksTable get _banks => _database.syncedCustomBanks;

  @override
  Stream<List<CustomBank>> watchAll() =>
      (_database.select(_banks)..where(
            (_) => CustomExpression<bool>(
              'NOT (${unsafe('custom_banks.revision')})',
            ),
          ))
          .watch()
          .map((rows) => sortedBanks(rows.map(syncedCustomBank).toList()));

  @override
  Future<CustomBank> create(String name) => _database.writeAndQueue(() async {
    final trimmedName = await _validName(name);
    final id = newRecordId();
    final now = syncedTimestamp(_now());
    final row = await _database
        .into(_banks)
        .insertReturning(
          SyncedCustomBanksCompanion.insert(
            id: id,
            name: trimmedName,
            createdAt: now,
            updatedAt: now,
            revision: 1,
          ),
        );
    return (
      syncedCustomBank(row),
      [
        SyncOperation('bank.create', id, data: {'name': trimmedName}),
      ],
    );
  });

  @override
  Future<CustomBank> rename(String id, String name) =>
      _database.writeAndQueue(() async {
        final existing = await _find(id);
        final trimmedName = await _validName(name, excludingId: id);
        // The same name: the server would change nothing.
        if (trimmedName == existing.name) {
          return (syncedCustomBank(existing), <SyncOperation>[]);
        }
        final rows =
            await (_database.update(
              _banks,
            )..where((bank) => bank.id.equals(id))).writeReturning(
              SyncedCustomBanksCompanion(
                name: Value(trimmedName),
                updatedAt: Value(syncedTimestamp(_now())),
                revision: Value(nextRevision(existing.revision)),
              ),
            );
        return (
          syncedCustomBank(rows.single),
          [
            SyncOperation(
              'bank.update',
              id,
              expectedRevision: existing.revision,
              data: {'name': trimmedName},
            ),
          ],
        );
      });

  @override
  Future<void> delete(String id) => _database.writeAndQueue(() async {
    final accounts = _database.syncedAccounts;
    final usage = accounts.id.count();
    final used =
        await (_database.selectOnly(accounts)
              ..addColumns([usage])
              ..where(accounts.customBankId.equals(id)))
            .map((row) => row.read(usage)!)
            .getSingle();
    if (used > 0) {
      throw const CustomBankValidationException(
        CustomBankValidationError.inUse,
      );
    }
    final existing = await _find(id);
    await (_database.delete(_banks)..where((bank) => bank.id.equals(id))).go();
    return (
      null,
      [SyncOperation('bank.delete', id, expectedRevision: existing.revision)],
    );
  });

  Future<SyncedCustomBankRow> _find(String id) async {
    final row = await (_database.select(
      _banks,
    )..where((bank) => bank.id.equals(id))).getSingleOrNull();
    if (row == null) throw StateError('Bank $id does not exist.');
    return row;
  }

  Future<String> _validName(String name, {String? excludingId}) async {
    final trimmed = checkedCustomBankName(name);
    final query = _database.select(_banks)
      ..where((bank) {
        final sameName = sameNameAs(bank.name, trimmed);
        return excludingId == null
            ? sameName
            : sameName & bank.id.equals(excludingId).not();
      });
    if ((await query.get()).isNotEmpty) {
      throw const CustomBankValidationException(
        CustomBankValidationError.nameTaken,
      );
    }
    return trimmed;
  }
}

CustomBank syncedCustomBank(SyncedCustomBankRow row) => CustomBank(
  id: row.id,
  name: row.name,
  createdAt: parseSyncedTimestamp(row.createdAt),
);
