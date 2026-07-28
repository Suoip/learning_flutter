import 'package:supabase_flutter/supabase_flutter.dart';

/// The raw data operations [EducatorLogic][] needs to manage an educator's
/// video entries, kept separate from `SupabaseClient` so tests can
/// substitute an in-memory fake instead of a real Supabase project. Mirrors
/// [NotesDataSource]'s shape exactly - see that file for the rationale.
///
/// [EducatorLogic]: educator_logic.dart
/// [NotesDataSource]: notes_data_source.dart
abstract class EducatorVideosDataSource {
  /// The currently authenticated user's id, or null if signed out. Equal to
  /// the owning educator's id, since `public.educators.id` IS
  /// `auth.users.id` for that account.
  String? get currentUserId;

  Future<List<Map<String, dynamic>>> selectVideos({
    required String educatorId,
  });

  /// Videos across ALL educators, newest-updated-first, capped at [limit] -
  /// each row includes the authoring educator's id/username/avatar_url
  /// (embedded, not a separate per-row fetch) under an `educators` key. Used
  /// by the public hub, which browses across every educator rather than one
  /// at a time like every other query in this file.
  Future<List<Map<String, dynamic>>> selectRecentVideosWithAuthor({
    required int limit,
  });

  Future<Map<String, dynamic>> insertVideo(Map<String, dynamic> values);

  Future<void> updateVideoById(String id, Map<String, dynamic> values);

  Future<void> deleteVideoById(String id);
}

/// The real [EducatorVideosDataSource], backed by a Supabase project.
class SupabaseEducatorVideosDataSource implements EducatorVideosDataSource {
  SupabaseEducatorVideosDataSource(this._client);

  final SupabaseClient _client;

  static const _columns =
      'id,title,description,duration_label,created_at,updated_at';

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Future<List<Map<String, dynamic>>> selectVideos({
    required String educatorId,
  }) async {
    final rows = await _client
        .from('educator_videos')
        .select(_columns)
        .eq('educator_id', educatorId)
        .order('updated_at', ascending: false);
    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  @override
  Future<List<Map<String, dynamic>>> selectRecentVideosWithAuthor({
    required int limit,
  }) async {
    final rows = await _client
        .from('educator_videos')
        .select(
          'id,title,description,duration_label,created_at,updated_at,'
          'educator_id,educators(id,username,avatar_url)',
        )
        .order('updated_at', ascending: false)
        .limit(limit);
    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  @override
  Future<Map<String, dynamic>> insertVideo(Map<String, dynamic> values) {
    return _client
        .from('educator_videos')
        .insert(values)
        .select(_columns)
        .single();
  }

  @override
  Future<void> updateVideoById(String id, Map<String, dynamic> values) async {
    await _client.from('educator_videos').update(values).eq('id', id);
  }

  @override
  Future<void> deleteVideoById(String id) async {
    await _client.from('educator_videos').delete().eq('id', id);
  }
}
