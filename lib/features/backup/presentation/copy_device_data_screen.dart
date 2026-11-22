import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/spacing.dart';
import '../../../core/formatting/money_formatter.dart';
import '../../../core/money/money.dart';
import '../../../core/sync/synced_store.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/auth_identity.dart';
import '../data/backup_exporter.dart';
import '../data/backup_source.dart';
import '../data/cloud_dataset_import.dart';
import '../data/dataset_request.dart';
import '../data/device_copy_store.dart';
import '../data/device_data_copier.dart';
import 'checkpoint_confirm_dialog.dart';
import 'export_backup.dart';
import 'restore_backup.dart' show describeCounts;
import 'signed_in_backup.dart';

/// What the user types to replace the account's data with this device's.
const replaceConfirmationPhrase = 'replace my data';

/// Opens [CopyDeviceDataScreen].
Future<void> openCopyDeviceData(BuildContext context) => Navigator.of(
  context,
).push(MaterialPageRoute<void>(builder: (_) => const CopyDeviceDataScreen()));

/// Copies this device's signed-out data into the signed-in account and checks
/// the copy record by record (cloud sync S6.2). The device's data never
/// changes. When the account already has records, they are replaced on every
/// device, after a checkpoint export and a typed confirmation.
class CopyDeviceDataScreen extends ConsumerStatefulWidget {
  const CopyDeviceDataScreen({super.key});

  @override
  ConsumerState<CopyDeviceDataScreen> createState() =>
      _CopyDeviceDataScreenState();
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
      "You're offline. Connect to the internet to copy your data.";

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
      _show(const _Message('Copying is not available in this version.'));
      return;
    }
    final pending = ref.read(deviceCopyStateProvider).pending;
    if (pending != null && pending.userId == identity.userId) {
      await _check(copier, pending);
    } else {
      await _loadPreview(copier);
    }
  }

  Future<void> _loadPreview(DeviceDataCopier copier) async {
    _show(const _Working('Reading your data…'));
    try {
      final blocked = await signedInServerBlockerText(ref, offline: _offline);
      if (blocked != null) return _show(_Message(blocked));
      final preview = await copier.preview();
      if (!hasDeviceData(preview.device)) {
        return _show(
          const _Message(
            "There's nothing to copy: this device has only the default "
            'categories.',
          ),
        );
      }
      _show(_Preview(preview));
    } on Object {
      _show(const _Message("Your data couldn't be read. Nothing was copied."));
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

    _show(const _Working('Copying your data…'));
    final CopySent sent;
    try {
      sent = await copier.send(preview);
    } on CopyTooLargeException catch (error) {
      final megabytes = (error.bytes / (1024 * 1024)).toStringAsFixed(1);
      return _show(
        _Message(
          'This device holds more than one copy can send ($megabytes MB; '
          'the limit is 8 MB). Nothing was copied.',
        ),
      );
    } on CloudImportException catch (error) {
      switch (error.problem) {
        case CloudImportProblem.datasetChanged:
          _snack(
            'Your account changed on another device. Check the new counts '
            'before copying.',
          );
          return _loadPreview(copier);
        case CloudImportProblem.unreachable:
          return _show(
            const _Message(
              "Couldn't reach the server. Open this screen again later: if "
              'the copy went through, your account already shows the same '
              'counts as this device.',
            ),
          );
        case CloudImportProblem.refused:
          return _show(
            _Message(
              'The copy was refused (${error.code}). Nothing was changed.',
            ),
          );
      }
    } on Object {
      return _show(
        const _Message(
          "This device's data couldn't be sent. Nothing was "
          'copied.',
        ),
      );
    }

    final pending = PendingCopyCheck(
      userId: identity.userId,
      email: identity.email,
      ids: sent.ids,
      counts: sent.counts,
    );
    await ref.read(deviceCopyStateProvider.notifier).setPending(pending);
    await _check(copier, pending, source: preview.device);
  }

  /// Waits for this device to download the copy, then compares it with the
  /// device's data. [source] is what was sent; read again when the check
  /// runs on a later visit.
  Future<void> _check(
    DeviceDataCopier copier,
    PendingCopyCheck pending, {
    BackupRecords? source,
  }) async {
    _show(const _Working('Checking the copy…'));
    final notifier = ref.read(deviceCopyStateProvider.notifier);
    final CopyCheck? check;
    try {
      check = await copier.check(
        source: source ?? await ref.read(deviceDataReaderProvider).read(),
        ids: pending.ids,
        counts: pending.counts,
        wait: ref.read(copyCheckWaitProvider),
      );
    } on Object {
      return _show(
        const _Message(
          "The copy couldn't be checked. Open this screen again to retry.",
        ),
      );
    }
    if (check == null) {
      return _show(
        const _Message(
          'Copied. This device will check it after it syncs: open this '
          'screen again later.',
        ),
      );
    }
    if (check.passed) {
      await notifier.recordCopy(
        DeviceCopy(
          userId: pending.userId,
          email: pending.email,
          copiedAt: DateTime.now(),
        ),
      );
    } else {
      await notifier.clearPending();
    }
    _show(_Checked(check));
  }

  Future<bool> _confirmReplace(CopyPreview preview, SignedIn identity) async =>
      await showDialog<bool>(
        context: context,
        builder: (_) => CheckpointConfirmDialog(
          title: "Replace your account's data?",
          heading: 'In your account now',
          current: preview.account,
          consequence:
              'Everything in your account is deleted on every device signed '
              'in as ${identity.email}, then replaced with this device\'s '
              "data. This device's data doesn't change.",
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

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("Copy this device's data")),
    body: SafeArea(
      child: switch (_stage) {
        _Working(:final text) => _ProgressView(text),
        _Message(:final text) => _MessageView(text),
        _Preview(:final preview) => _PreviewView(
          preview,
          email: _identity?.email ?? '',
          onCopy: () => _copy(preview),
        ),
        _Checked(:final check) => _CheckedView(check),
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
  const _PreviewView(this.preview, {required this.email, required this.onCopy});

  final CopyPreview preview;
  final String email;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final replace = !preview.accountIsEmpty;
    return ListView(
      padding: const EdgeInsets.all(Spacing.md),
      children: [
        Text('On this device', style: theme.textTheme.titleSmall),
        Text(describeCounts(preview.deviceCounts)),
        const SizedBox(height: Spacing.md),
        Text('In your account ($email)', style: theme.textTheme.titleSmall),
        Text(describeCounts(preview.account)),
        const SizedBox(height: Spacing.lg),
        Text(
          replace
              ? 'Your account already has data. Replacing deletes it on every '
                    "device signed in as $email, then copies this device's "
                    'data into it.'
              : 'Your account has only the default categories. Copying puts '
                    "this device's data in their place.",
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          "This device's data stays as it is. After copying, Fundly checks "
          'every record in your account against it.',
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
            child: const Text("Replace my account's data"),
          )
        else
          FilledButton(
            onPressed: onCopy,
            child: const Text('Copy to my account'),
          ),
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
  const _CheckedView(this.check);

  final CopyCheck check;

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
                check.passed
                    ? 'Copied and checked'
                    : "The copy doesn't match this device",
                style: theme.textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          check.passed
              ? "Every record in your account matches this device's data."
              : 'First difference: ${check.difference}. This device\'s data '
                    'is unchanged. Please report this.',
        ),
        if (check.deviceBalances.isNotEmpty) ...[
          const SizedBox(height: Spacing.lg),
          Text('Balances', style: theme.textTheme.titleSmall),
          for (final MapEntry(key: name, value: balance)
              in check.deviceBalances.entries)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(name),
              trailing: Text(MoneyFormatter.format(balance)),
              subtitle: check.accountBalances[name] == balance
                  ? const Text('Same in your account')
                  : Text(
                      'In your account: ${_balanceText(check.accountBalances[name])}',
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
