import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'backup_importer.dart';
import 'dataset_request.dart';

/// This device's data was copied into an account (cloud sync S6.2).
@immutable
final class DeviceCopy {
  const DeviceCopy({
    required this.userId,
    required this.email,
    required this.copiedAt,
  });

  final String userId;
  final String email;
  final DateTime copiedAt;

  Map<String, Object?> toJson() => {
    'userId': userId,
    'email': email,
    'copiedAt': copiedAt.toUtc().toIso8601String(),
  };

  static DeviceCopy fromJson(Map<String, Object?> json) => DeviceCopy(
    userId: json['userId']! as String,
    email: json['email']! as String,
    copiedAt: DateTime.parse(json['copiedAt']! as String),
  );
}

/// A copy the server accepted whose check has not run yet, because this
/// device had not downloaded the account in time.
@immutable
final class PendingCopyCheck {
  const PendingCopyCheck({
    required this.userId,
    required this.email,
    required this.ids,
    required this.counts,
  });

  final String userId;
  final String email;
  final ImportIdMap ids;
  final BackupCounts counts;

  Map<String, Object?> toJson() => {
    'userId': userId,
    'email': email,
    'ids': ids,
    'counts': countsJson(counts),
  };

  static PendingCopyCheck fromJson(Map<String, Object?> json) {
    final counts = json['counts']! as Map<String, Object?>;
    // Checks saved before the banks release have no custom_banks count.
    int count(String key) => counts[key] as int? ?? 0;
    return PendingCopyCheck(
      userId: json['userId']! as String,
      email: json['email']! as String,
      ids: {
        for (final MapEntry(:key, :value)
            in (json['ids']! as Map<String, Object?>).entries)
          key: (value! as Map<String, Object?>).cast<String, String>(),
      },
      counts: BackupCounts(
        customAccountTypes: count('custom_account_types'),
        accounts: count('accounts'),
        categories: count('categories'),
        transactions: count('transactions'),
        monthlyPlans: count('monthly_plans'),
        customBanks: count('custom_banks'),
      ),
    );
  }
}

/// What this device remembers about copying its data into accounts.
@immutable
final class DeviceCopyState {
  const DeviceCopyState({
    this.copies = const [],
    this.dismissed = const {},
    this.pending,
  });

  /// Checked copies, oldest first.
  final List<DeviceCopy> copies;

  /// Accounts whose sign-in prompt the user answered with "Not now".
  final Set<String> dismissed;

  /// A copy waiting for its check.
  final PendingCopyCheck? pending;

  /// The most recent checked copy, shown while signed out.
  DeviceCopy? get lastCopy => copies.isEmpty ? null : copies.last;

  /// Whether the sign-in prompt should stay quiet for [userId].
  bool settledFor(String userId) =>
      dismissed.contains(userId) ||
      pending?.userId == userId ||
      copies.any((copy) => copy.userId == userId);

  Map<String, Object?> toJson() => {
    'copies': [for (final copy in copies) copy.toJson()],
    'dismissed': dismissed.toList(),
    'pending': pending?.toJson(),
  };

  static DeviceCopyState fromJson(Map<String, Object?> json) => DeviceCopyState(
    copies: [
      for (final copy in json['copies']! as List<Object?>)
        DeviceCopy.fromJson(copy! as Map<String, Object?>),
    ],
    dismissed: {
      for (final userId in json['dismissed']! as List<Object?>)
        userId! as String,
    },
    pending: json['pending'] == null
        ? null
        : PendingCopyCheck.fromJson(json['pending']! as Map<String, Object?>),
  );
}

/// Where [DeviceCopyState] is kept.
abstract class DeviceCopyStore {
  DeviceCopyState read();

  Future<void> write(DeviceCopyState state);
}

/// Keeps the state for this run only: tests, and builds without the cloud
/// configuration.
class InMemoryDeviceCopyStore implements DeviceCopyStore {
  InMemoryDeviceCopyStore([this._state = const DeviceCopyState()]);

  DeviceCopyState _state;

  @override
  DeviceCopyState read() => _state;

  @override
  Future<void> write(DeviceCopyState state) async => _state = state;
}

/// Keeps the state in the app's preferences on the device.
class SharedPreferencesDeviceCopyStore implements DeviceCopyStore {
  SharedPreferencesDeviceCopyStore(this._preferences);

  static const key = 'fundly.deviceCopy';

  final SharedPreferences _preferences;

  @override
  DeviceCopyState read() {
    final text = _preferences.getString(key);
    if (text == null) return const DeviceCopyState();
    try {
      return DeviceCopyState.fromJson(jsonDecode(text) as Map<String, Object?>);
    } on Object {
      // Unreadable (for example from a future version): start over rather
      // than fail. Only reminders are lost; no financial data lives here.
      return const DeviceCopyState();
    }
  }

  @override
  Future<void> write(DeviceCopyState state) =>
      _preferences.setString(key, jsonEncode(state.toJson()));
}

final deviceCopyStoreProvider = Provider<DeviceCopyStore>(
  (ref) => InMemoryDeviceCopyStore(),
);

/// What this device remembers about copies, kept in [deviceCopyStoreProvider].
final deviceCopyStateProvider =
    NotifierProvider<DeviceCopyStateNotifier, DeviceCopyState>(
      DeviceCopyStateNotifier.new,
    );

class DeviceCopyStateNotifier extends Notifier<DeviceCopyState> {
  @override
  DeviceCopyState build() => ref.watch(deviceCopyStoreProvider).read();

  Future<void> _save(DeviceCopyState next) async {
    state = next;
    await ref.read(deviceCopyStoreProvider).write(next);
  }

  /// The user answered the sign-in prompt for [userId] with "Not now".
  Future<void> dismiss(String userId) => _save(
    DeviceCopyState(
      copies: state.copies,
      dismissed: {...state.dismissed, userId},
      pending: state.pending,
    ),
  );

  /// The server accepted a copy that is not checked yet.
  Future<void> setPending(PendingCopyCheck pending) => _save(
    DeviceCopyState(
      copies: state.copies,
      dismissed: state.dismissed,
      pending: pending,
    ),
  );

  /// The copy into [copy]'s account was checked. Clears any pending check.
  Future<void> recordCopy(DeviceCopy copy) => _save(
    DeviceCopyState(
      copies: [
        ...state.copies.where((earlier) => earlier.userId != copy.userId),
        copy,
      ],
      dismissed: state.dismissed,
    ),
  );

  /// Forgets a pending check, for example after it found a difference.
  Future<void> clearPending() =>
      _save(DeviceCopyState(copies: state.copies, dismissed: state.dismissed));
}
