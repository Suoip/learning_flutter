import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

/// The raw data operations [NotesLogic][] needs for profiles (and profile
/// avatar storage), kept separate from `SupabaseClient` for the same reason
/// as [NotesDataSource][]: tests substitute an in-memory fake instead of a
/// real Supabase project.
///
/// [NotesLogic]: notes_logic.dart
/// [NotesDataSource]: notes_data_source.dart
abstract class ProfilesDataSource {
  /// The currently authenticated user, or null if signed out. Unlike
  /// [NotesDataSource.currentUserId], this exposes the full [User] (not
  /// just its id) because `NotesLogic.defaultUsernameForUser` reads its
  /// `userMetadata`/`email`, and `UserProfile.fromMap` takes it directly.
  User? get currentUser;

  Future<Map<String, dynamic>?> selectProfileById(String userId);

  Future<void> insertProfile(Map<String, dynamic> values);

  Future<void> updateProfileById(String userId, Map<String, dynamic> values);

  Future<void> upsertProfile(
    Map<String, dynamic> values, {
    required String onConflict,
  });

  Future<List<Map<String, dynamic>>> searchProfilesByUsername({
    required String query,
    required String excludeUserId,
    int limit = 20,
  });

  /// Uploads avatar bytes to [objectPath] and returns its public URL
  /// (without a cache-busting query string - callers append their own).
  Future<String> uploadAvatarAndGetPublicUrl({
    required String objectPath,
    required Uint8List bytes,
  });
}

/// The real [ProfilesDataSource], backed by a Supabase project.
class SupabaseProfilesDataSource implements ProfilesDataSource {
  SupabaseProfilesDataSource(this._client);

  final SupabaseClient _client;

  static const _table = 'profiles';
  static const _avatarsBucket = 'profile-pictures';
  static const _columns = 'id,username,avatar_url';

  @override
  User? get currentUser => _client.auth.currentUser;

  @override
  Future<Map<String, dynamic>?> selectProfileById(String userId) {
    return _client.from(_table).select(_columns).eq('id', userId).maybeSingle();
  }

  @override
  Future<void> insertProfile(Map<String, dynamic> values) async {
    await _client.from(_table).insert(values);
  }

  @override
  Future<void> updateProfileById(
    String userId,
    Map<String, dynamic> values,
  ) async {
    await _client.from(_table).update(values).eq('id', userId);
  }

  @override
  Future<void> upsertProfile(
    Map<String, dynamic> values, {
    required String onConflict,
  }) async {
    await _client.from(_table).upsert(values, onConflict: onConflict);
  }

  @override
  Future<List<Map<String, dynamic>>> searchProfilesByUsername({
    required String query,
    required String excludeUserId,
    int limit = 20,
  }) async {
    final rows = await _client
        .from(_table)
        .select(_columns)
        .ilike('username', '%$query%')
        .neq('id', excludeUserId)
        .order('username')
        .limit(limit);
    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  @override
  Future<String> uploadAvatarAndGetPublicUrl({
    required String objectPath,
    required Uint8List bytes,
  }) async {
    await _client.storage.from(_avatarsBucket).uploadBinary(
          objectPath,
          bytes,
          fileOptions: const FileOptions(
            upsert: true,
            cacheControl: '3600',
          ),
        );
    return _client.storage.from(_avatarsBucket).getPublicUrl(objectPath);
  }
}
