import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/spacing.dart';
import '../../../core/formatting/date_formatter.dart';
import '../../../core/formatting/money_formatter.dart';
import '../../../core/money/money.dart';
import '../../../core/sync/synced_store.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/auth_identity.dart';
import '../../spaces/presentation/space_providers.dart';
import '../data/backup_exporter.dart';
import '../data/backup_importer.dart';
import '../data/backup_source.dart';
import '../data/cloud_dataset_import.dart';
import '../data/dataset_request.dart';
import '../data/device_copy_store.dart';
import '../data/device_data_copier.dart';
import 'checkpoint_confirm_dialog.dart';
import 'export_backup.dart';
import 'restore_backup.dart' show describeCounts;
import 'signed_in_backup.dart';

/// What the user types to replace the account's data.
const replaceConfirmationPhrase = 'replace my data';

/// Opens [CopyDeviceDataScreen] for this device's signed-out data.
Future<void> openCopyDeviceData(BuildContext context) => Navigator.of(
  context,
).push(MaterialPageRoute<void>(builder: (_) => const CopyDeviceDataScreen()));

/// Opens [CopyDeviceDataScreen] to restore the checked [backup] into the
/// signed-in account (cloud sync S6.3).
Future<void> openRestoreToAccount(
  BuildContext context,
  BackupSnapshot backup,
) => Navigator.of(context).push(
  MaterialPageRoute<void>(builder: (_) => CopyDeviceDataScreen(backup: backup)),
);

/// Sends records into the signed-in account and checks the result record by
/// record: this device's signed-out data (cloud sync S6.2), or a [backup]
/// file (S6.3). Neither source changes. When the account already has
/// records, they are replaced on every device, after a checkpoint export and
/// a typed confirmation.
class CopyDeviceDataScreen extends ConsumerStatefulWidget {
  const CopyDeviceDataScreen({super.key, this.backup});

  /// The backup to restore; `null` to copy this device's data.
  final BackupSnapshot? backup;

  @override
  ConsumerState<CopyDeviceDataScreen> createState() =>
      _CopyDeviceDataScreenState();
}

/// What the screen says, for this device's data or a backup.
final class _Words {
  const _Words.device()
    : title = "Copy this device's data",
      source = 'On this device',
      go = 'Copy to my account',
      working = 'Copying your data…',
      fillsEmpty = "Copying puts this device's data in their place.",
      replaces = "then copies this device's data into it.",
      footnote =
          "This device's data stays as it is. After copying, Fundly checks "
          'every record in your account against it.',
      replacedWith = "this device's data. This device's data doesn't change.",
      passed = 'Copied and checked',
      passedDetail = "Every record in your account matches this device's data.",
      failed = "The copy doesn't match this device",
      failedDetail = "This device's data is unchanged. Please report this.",
      late =
          'Copied. This device will check it after it syncs: open this '
          'screen again later.',
      unreachable =
          "Couldn't reach the server. Open this screen again later: if the "
          'copy went through, your account already shows the same counts as '
          'this device.',
      tooLarge = 'This device holds more than one copy can send',
      refused = 'The copy was refused';

  _Words.backup(DateTime exportedAt)
    : title = 'Restore a backup',
      source = 'In the backup (${DateFormatter.localDate(exportedAt)})',
      go = 'Restore into my account',
      working = 'Restoring the backup…',
      fillsEmpty = "Restoring puts the backup's data in their place.",
      replaces = 'then restores the backup into it.',
      footnote =
          'After restoring, Fundly checks every record in your account '
          'against the backup.',
      replacedWith = "the backup's data.",
      passed = 'Restored and checked',
      passedDetail = 'Every record in your account matches the backup.',
      failed = "The restored account doesn't match the backup",
      failedDetail = 'Please report this.',
      late = 'Restored. This device will show it after it syncs.',
      unreachable =
          "Couldn't reach the server. If the restore went through, your "
          "account shows the backup's counts after it syncs.",
      tooLarge = 'This backup holds more than one restore can send',
      refused = 'The restore was refused';

  final String title;
  final String source;
  final String go;
  final String working;
  final String fillsEmpty;
  final String replaces;
  final String footnote;
  final String replacedWith;
  final String passed;
  final String passedDetail;
  final String failed;
  final String failedDetail;
  final String late;
  final String unreachable;
  final String tooLarge;
  final String refused;
}

sealed class _Stage {
  const _Stage();
}

final class _Working extends _Stage {
  const _Working(this.text);
  final String text;
}

final class _Message extends _Stage {
  const _Message(this.text);
  final String text;
}

final class _Preview extends _Stage {
  const _Preview(this.preview);
  final CopyPreview preview;
}

final class _Checked extends _Stage {
  const _Checked(this.check);
  final CopyCheck check;
}

class _CopyDeviceDataScreenState extends ConsumerState<CopyDeviceDataScreen> {
  _Stage _stage = const _Working('Reading your data…');

  static const _offline =
      "You're offline. Connect to the internet to change your account's data.";

  BackupSnapshot? get _backup => widget.backup;

  late final _Words _words = switch (_backup) {
    null => const _Words.device(),
    final backup => _Words.backup(backup.exportedAt),
  };

  @override
  void initState() {
    super.initState();
    // The guards read these; listening keeps them running while this screen
    // is open (a provider nobody listens to is paused).
    for (final provider in [
      syncStateProvider,
      pendingUploadCountProvider,
      unsafeSyncedRowCountProvider,
    ]) {
      ref.listenManual(provider, (_, _) {});
    }
    _start();
  }

  void _show(_Stage stage) {
    if (mounted) setState(() => _stage = stage);
  }

  SignedIn? get _identity => switch (ref.read(authIdentityProvider)) {
    final SignedIn identity => identity,
    _ => null,
  };

  Future<void> _start() async {
    final identity = _identity;
    final copier = ref.read(deviceDataCopierProvider);
    if (identity == null || copier == null) {
      _show(const _Message('This is not available in this version.'));
      return;
    }
    // Only a copy of this device's data can be checked on a later visit:
    // a backup file is not kept.
    final pending = ref.read(deviceCopyStateProvider).pending;
    if (_backup == null &&
        pending != null &&
        pending.userId == identity.userId) {
      await _check(
        copier,
        ids: pending.ids,
        counts: pending.counts,
        source: await ref.read(deviceDataReaderProvider).read(),
      );
    } else {
      await _loadPreview(copier);
    }
  }

  Future<void> _loadPreview(DeviceDataCopier copier) async {
    _show(const _Working('Reading your data…'));
    try {
      final blocked = await signedInServerBlockerText(ref, offline: _offline);
      if (blocked != null) return _show(_Message(blocked));
      final preview = await copier.preview(backup: _backup?.records);
      if (_backup == null && !hasDeviceData(preview.source)) {
        return _show(
          const _Message(
            "There's nothing to copy: this device has only the default "
            'categories.',
          ),
        );
      }
      _show(_Preview(preview));
    } on Object {
      _show(const _Message("Your data couldn't be read. Nothing was changed."));
    }
  }

  Future<void> _copy(CopyPreview preview) async {
    final identity = _identity;
    final copier = ref.read(deviceDataCopierProvider);
    if (identity == null || copier == null) return;
    if (!preview.accountIsEmpty && !await _confirmReplace(preview, identity)) {
      return;
    }
    // Things may have changed while the dialog was open.
    final String? blocked;
    try {
      blocked = await signedInServerBlockerText(ref, offline: _offline);
    } on Object {
      return _show(const _Message("Your sync status couldn't be read."));
    }
    if (blocked != null) return _show(_Message(blocked));

    _show(_Working(_words.working));
    final CopySent sent;
    try {
      sent = await copier.send(preview);
    } on CopyTooLargeException catch (error) {
      final megabytes = (error.bytes / (1024 * 1024)).toStringAsFixed(1);
      return _show(
        _Message(
          '${_words.tooLarge} ($megabytes MB; the limit is 8 MB). Nothing '
          'was changed.',
        ),
      );
    } on CloudImportException catch (error) {
      switch (error.problem) {
        case CloudImportProblem.datasetChanged:
          _snack(
            'Your account changed on another device. Check the new counts '
            'before going on.',
          );
          return _loadPreview(copier);
        case CloudImportProblem.unreachable:
          return _show(_Message(_words.unreachable));
        case CloudImportProblem.refused:
          return _show(
            _Message('${_words.refused} (${error.code}). Nothing was changed.'),
          );
      }
    } on Object {
      return _show(
        const _Message("The data couldn't be sent. Nothing was changed."),
      );
    }

    if (_backup == null) {
      await ref
          .read(deviceCopyStateProvider.notifier)
          .setPending(
            PendingCopyCheck(
              userId: identity.userId,
              email: identity.email,
              ids: sent.ids,
              counts: sent.counts,
            ),
          );
    }
    await _check(
      copier,
      ids: sent.ids,
      counts: sent.counts,
      source: preview.source,
    );
  }

  /// Waits for this device to download the account, then compares it with
  /// [source], which was sent with [ids]. A checked copy of this device's
  /// data is remembered; a restore is not (Decision S6.3-3).
  Future<void> _check(
    DeviceDataCopier copier, {
    required ImportIdMap ids,
    required BackupCounts counts,
    required BackupRecords source,
  }) async {
    _show(const _Working('Checking…'));
    final CopyCheck? check;
    try {
      check = await copier.check(
        source: source,
        ids: ids,
        counts: counts,
        wait: ref.read(copyCheckWaitProvider),
      );
    } on Object {
      return _show(
        const _Message("The result couldn't be checked. Nothing was undone."),
      );
    }
    if (check == null) return _show(_Message(_words.late));
    final identity = _identity;
    if (_backup == null && identity != null) {
      final notifier = ref.read(deviceCopyStateProvider.notifier);
      if (check.passed) {
        await notifier.recordCopy(
          DeviceCopy(
            userId: identity.userId,
            email: identity.email,
            copiedAt: DateTime.now(),
          ),
        );
      } else {
        await notifier.clearPending();
      }
    }
    _show(_Checked(check));
  }

  Future<bool> _confirmReplace(CopyPreview preview, SignedIn identity) async =>
      await showDialog<bool>(
        context: context,
        builder: (_) => CheckpointConfirmDialog(
          title: _space == null
              ? "Replace your account's data?"
              : 'Replace the data in $_space?',
          heading: 'In ${_space ?? 'your account'} now',
          current: preview.account,
          consequence:
              'Everything in ${_space ?? 'your account'} is deleted on every '
              'device signed '
              'in as ${identity.email}, then replaced with '
              '${_words.replacedWith}',
          phrase: replaceConfirmationPhrase,
          confirmLabel: 'Replace',
          exportCheckpoint: (dialogContext) => exportBackup(
            dialogContext,
            ref,
            kind: BackupFileKind.replaceCheckpoint,
          ),
        ),
      ) ==
      true;

  void _snack(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  /// The active space's name when the user has several (shared spaces C2).
  String? get _space => ref.read(shownSpaceNameProvider);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_words.title)),
    body: SafeArea(
      child: switch (_stage) {
        _Working(:final text) => _ProgressView(text),
        _Message(:final text) => _MessageView(text),
        _Preview(:final preview) => _PreviewView(
          preview,
          words: _words,
          email: _identity?.email ?? '',
          space: ref.watch(shownSpaceNameProvider),
          onCopy: () => _copy(preview),
        ),
        _Checked(:final check) => _CheckedView(check, words: _words),
      },
    ),
  );
}

class _ProgressView extends StatelessWidget {
  const _ProgressView(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: Spacing.md),
        Text(text),
      ],
    ),
  );
}

class _MessageView extends StatelessWidget {
  const _MessageView(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(Spacing.md),
    children: [
      Text(text),
      const SizedBox(height: Spacing.lg),
      Align(
        alignment: Alignment.centerLeft,
        child: FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ),
    ],
  );
}

class _PreviewView extends StatelessWidget {
  const _PreviewView(
    this.preview, {
    required this.words,
    required this.email,
    required this.space,
    required this.onCopy,
  });

  final CopyPreview preview;
  final _Words words;
  final String email;

  /// The active space's name when the user has several (shared spaces C2).
  final String? space;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final replace = !preview.accountIsEmpty;
    return ListView(
      padding: const EdgeInsets.all(Spacing.md),
      children: [
        Text(words.source, style: theme.textTheme.titleSmall),
        Text(describeCounts(preview.sourceCounts)),
        const SizedBox(height: Spacing.md),
        Text(
          'In ${space ?? 'your account'} ($email)',
          style: theme.textTheme.titleSmall,
        ),
        Text(describeCounts(preview.account)),
        const SizedBox(height: Spacing.lg),
        Text(
          replace
              ? '${space ?? 'Your account'} already has data. Replacing '
                    'deletes it on every device signed in as $email, '
                    '${words.replaces}'
              : '${space ?? 'Your account'} has only the default '
                    'categories. ${words.fillsEmpty}',
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          words.footnote,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Spacing.lg),
        if (replace)
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colors.error,
              foregroundColor: colors.onError,
            ),
            onPressed: onCopy,
            child: Text(
              space == null
                  ? "Replace my account's data"
                  : 'Replace the data in $space',
            ),
          )
        else
          FilledButton(onPressed: onCopy, child: Text(words.go)),
        const SizedBox(height: Spacing.sm),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Not now'),
        ),
      ],
    );
  }
}

class _CheckedView extends StatelessWidget {
  const _CheckedView(this.check, {required this.words});

  final CopyCheck check;
  final _Words words;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return ListView(
      padding: const EdgeInsets.all(Spacing.md),
      children: [
        Row(
          children: [
            Icon(
              check.passed ? Icons.check_circle : Icons.error,
              color: check.passed ? colors.primary : colors.error,
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Text(
                check.passed ? words.passed : words.failed,
                style: theme.textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          check.passed
              ? words.passedDetail
              : 'First difference: ${check.difference}. ${words.failedDetail}',
        ),
        if (check.sourceBalances.isNotEmpty) ...[
          const SizedBox(height: Spacing.lg),
          Text('Balances', style: theme.textTheme.titleSmall),
          for (final MapEntry(key: name, value: balance)
              in check.sourceBalances.entries)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(name),
              trailing: Text(MoneyFormatter.format(balance)),
              subtitle: check.accountBalances[name] == balance
                  ? const Text('Same in your account')
                  : Text(
                      'In your account: '
                      '${_balanceText(check.accountBalances[name])}',
                      style: TextStyle(color: colors.error),
                    ),
            ),
        ],
        const SizedBox(height: Spacing.lg),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ),
      ],
    );
  }

  static String _balanceText(Money? balance) =>
      balance == null ? 'missing' : MoneyFormatter.format(balance);
}
