import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

/// The raw data operations [EducatorLogic][] needs for an educator's own
/// profile (and avatar storage), kept separate from `SupabaseClient` for the
/// same reason as [EducatorVideosDataSource][]: tests substitute an
/// in-memory fake instead of a real Supabase project. Mirrors
/// [ProfilesDataSource][]'s shape, trimmed to what educators actually need -
/// no username-lookup/search methods, since educators don't look each other
/// up anywhere.
///
/// [EducatorLogic]: educator_logic.dart
/// [EducatorVideosDataSource]: educator_videos_data_source.dart
/// [ProfilesDataSource]: profiles_data_source.dart
abstract class EducatorProfileDataSource {
  /// The currently authenticated user, or null if signed out.
  User? get currentUser;

  Future<Map<String, dynamic>?> selectEducatorById(String id);

  Future<void> insertEducator(Map<String, dynamic> values);

  Future<void> updateEducatorById(String id, Map<String, dynamic> values);

  Future<void> upsertEducator(
    Map<String, dynamic> values, {
    required String onConflict,
  });

  /// Uploads avatar bytes to [objectPath] and returns its public URL
  /// (without a cache-busting query string - callers append their own).
  Future<String> uploadAvatarAndGetPublicUrl({
    required String objectPath,
    required Uint8List bytes,
  });
}

/// The real [EducatorProfileDataSource], backed by a Supabase project.
class SupabaseEducatorProfileDataSource implements EducatorProfileDataSource {
  SupabaseEducatorProfileDataSource(this._client);

  final SupabaseClient _client;

  static const _table = 'educators';
  static const _avatarsBucket = 'educator-avatars';
  static const _columns = 'id,username,avatar_url';

  @override
  User? get currentUser => _client.auth.currentUser;

  @override
  Future<Map<String, dynamic>?> selectEducatorById(String id) {
    return _client.from(_table).select(_columns).eq('id', id).maybeSingle();
  }

  @override
  Future<void> insertEducator(Map<String, dynamic> values) async {
    await _client.from(_table).insert(values);
  }

  @override
  Future<void> updateEducatorById(
    String id,
    Map<String, dynamic> values,
  ) async {
    await _client.from(_table).update(values).eq('id', id);
  }

  @override
  Future<void> upsertEducator(
    Map<String, dynamic> values, {
    required String onConflict,
  }) async {
    await _client.from(_table).upsert(values, onConflict: onConflict);
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
