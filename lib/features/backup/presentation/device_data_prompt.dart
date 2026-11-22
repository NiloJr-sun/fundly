import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/sync/synced_store.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/auth_identity.dart';
import '../data/device_copy_store.dart';
import '../data/device_data_copier.dart';
import 'copy_device_data_screen.dart';

/// Shows [child], and once per account offers to copy this device's
/// signed-out data into it (cloud sync S6.2): after sign-in, when the first
/// download has finished, if the device has data and the user has not
/// copied it to this account or answered "Not now" before.
class DeviceDataPrompt extends ConsumerStatefulWidget {
  const DeviceDataPrompt({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<DeviceDataPrompt> createState() => _DeviceDataPromptState();
}

class _DeviceDataPromptState extends ConsumerState<DeviceDataPrompt> {
  /// Accounts already considered in this run, so the prompt shows at most
  /// once per sign-in even if the user leaves it open and the status changes.
  final _considered = <String>{};

  @override
  void initState() {
    super.initState();
    ref.listenManual(
      syncStateProvider,
      (_, next) => _maybePrompt(next.value),
      fireImmediately: true,
    );
  }

  Future<void> _maybePrompt(SyncState? state) async {
    final identity = ref.read(authIdentityProvider);
    if (identity is! SignedIn ||
        state == null ||
        !state.hasSynced ||
        _considered.contains(identity.userId) ||
        ref.read(deviceDataCopierProvider) == null ||
        ref.read(deviceCopyStateProvider).settledFor(identity.userId)) {
      return;
    }
    _considered.add(identity.userId);
    final bool hasData;
    try {
      hasData = await ref.read(deviceHasDataProvider.future);
    } on Object {
      return; // The Profile row still offers it.
    }
    if (!hasData || !mounted) return;
    final review = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Copy this device's data?"),
        content: Text(
          'This device has data from before you signed in. You can copy it '
          'into your account (${identity.email}). It stays on this device '
          'either way, and you can do this later from Profile.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Review'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (review == true) {
      unawaited(openCopyDeviceData(context));
    } else {
      await ref.read(deviceCopyStateProvider.notifier).dismiss(identity.userId);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
