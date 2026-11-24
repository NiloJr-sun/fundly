import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/sync/batch_uploader.dart';
import '../domain/space.dart';

/// Why creating or renaming a space did not happen.
enum SpaceProblem {
  /// No connection, or the server is busy: try again.
  offline,
  invalidName,
  nameTaken,
  limitReached,

  /// Renamed elsewhere since this device last downloaded it.
  changed,

  /// Not (or no longer) allowed, or anything else the server refused.
  refused,
}

class SpaceException implements Exception {
  const SpaceException(this.problem, [this.code]);

  final SpaceProblem problem;
  final String? code;

  @override
  String toString() => 'SpaceException(${problem.name}, $code)';
}

/// Creating and renaming spaces, online only (shared spaces C2, Decision
/// C2-3), through `fundly_create_space` and `fundly_rename_space`.
abstract interface class SpaceService {
  /// Creates a space called [name] with the id [spaceId] (retrying the same
  /// id and name is safe). Throws [SpaceException].
  Future<Space> create({required String spaceId, required String name});

  /// Renames [space] (owners only). Throws [SpaceException].
  Future<Space> rename(Space space, String name);

  /// The ids of the spaces the signed-in user belongs to, as the server says
  /// now. Throws when offline.
  Future<Set<String>> memberSpaceIds();
}

/// The real [SpaceService], through [client].
class SupabaseSpaceService implements SpaceService {
  SupabaseSpaceService(this._client);

  final SupabaseClient _client;

  @override
  Future<Space> create({required String spaceId, required String name}) =>
      _call('fundly_create_space', {'space_id': spaceId, 'name': name});

  @override
  Future<Space> rename(Space space, String name) =>
      _call('fundly_rename_space', {
        'space_id': space.id,
        'name': name,
        'expected_revision': '${space.revision}',
      }, role: space.role);

  @override
  Future<Set<String>> memberSpaceIds() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const {};
    final rows = await _client
        .from('space_members')
        .select('space_id')
        .eq('user_id', userId);
    return {for (final row in rows) row['space_id'] as String};
  }

  Future<Space> _call(
    String function,
    Map<String, Object?> params, {
    SpaceRole role = SpaceRole.owner,
  }) async {
    try {
      final result = Map<String, Object?>.from(
        await _client.rpc<dynamic>(function, params: params) as Map,
      );
      return Space(
        id: result['id']! as String,
        name: result['name']! as String,
        isPersonal: result['personal']! as bool,
        role: role,
        revision: int.parse(result['revision']! as String),
      );
    } on Object catch (error) {
      throw spaceExceptionFor(error);
    }
  }
}

/// Maps a failed space call to what the screen says (public for tests).
SpaceException spaceExceptionFor(Object error) {
  final failure = classifyUploadError(error);
  if (failure.outcome == UploadOutcome.transient) {
    return SpaceException(SpaceProblem.offline, failure.code);
  }
  return SpaceException(switch (failure.code) {
    'invalid_name' => SpaceProblem.invalidName,
    'name_taken' => SpaceProblem.nameTaken,
    'space_limit_reached' => SpaceProblem.limitReached,
    'revision_conflict' => SpaceProblem.changed,
    _ => SpaceProblem.refused,
  }, failure.code);
}

/// Set in `main.dart` when the build carries the cloud configuration; `null`
/// otherwise (and in tests unless overridden).
final spaceServiceProvider = Provider<SpaceService?>((ref) => null);
