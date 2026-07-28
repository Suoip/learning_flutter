import 'package:supabase_flutter/supabase_flutter.dart';

/// The raw data operations [EducatorLogic][] needs to manage an educator's
/// forum posts, kept separate from `SupabaseClient` so tests can substitute
/// an in-memory fake instead of a real Supabase project. Mirrors
/// [EducatorVideosDataSource]'s shape exactly - see that file for the
/// rationale.
///
/// [EducatorLogic]: educator_logic.dart
/// [EducatorVideosDataSource]: educator_videos_data_source.dart
abstract class EducatorForumPostsDataSource {
  /// The currently authenticated user's id, or null if signed out. Equal to
  /// the owning educator's id, since `public.educators.id` IS
  /// `auth.users.id` for that account.
  String? get currentUserId;

  Future<List<Map<String, dynamic>>> selectForumPosts({
    required String educatorId,
  });

  /// Forum posts across ALL educators, newest-updated-first, capped at
  /// [limit] - each row includes the authoring educator's
  /// id/username/avatar_url (embedded, not a separate per-row fetch) under
  /// an `educators` key. Used by the public hub, which browses across every
  /// educator rather than one at a time like every other query in this file.
  Future<List<Map<String, dynamic>>> selectRecentForumPostsWithAuthor({
    required int limit,
  });

  /// A single forum post by id, regardless of who wrote it - used to
  /// refresh live engagement for a post reached via the public hub, which
  /// only has the post's own id, not necessarily the owning educator's
  /// other content already loaded.
  Future<Map<String, dynamic>?> selectForumPostById(String id);

  Future<Map<String, dynamic>> insertForumPost(Map<String, dynamic> values);

  Future<void> updateForumPostById(String id, Map<String, dynamic> values);

  Future<void> deleteForumPostById(String id);
}

/// The real [EducatorForumPostsDataSource], backed by a Supabase project.
class SupabaseEducatorForumPostsDataSource
    implements EducatorForumPostsDataSource {
  SupabaseEducatorForumPostsDataSource(this._client);

  final SupabaseClient _client;

  static const _columns = 'id,title,description,created_at,updated_at';

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Future<List<Map<String, dynamic>>> selectForumPosts({
    required String educatorId,
  }) async {
    final rows = await _client
        .from('educator_forum_posts')
        .select(_columns)
        .eq('educator_id', educatorId)
        .order('updated_at', ascending: false);
    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  @override
  Future<List<Map<String, dynamic>>> selectRecentForumPostsWithAuthor({
    required int limit,
  }) async {
    final rows = await _client
        .from('educator_forum_posts')
        .select(
          'id,title,description,created_at,updated_at,'
          'educator_id,educators(id,username,avatar_url)',
        )
        .order('updated_at', ascending: false)
        .limit(limit);
    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  @override
  Future<Map<String, dynamic>?> selectForumPostById(String id) {
    return _client
        .from('educator_forum_posts')
        .select(_columns)
        .eq('id', id)
        .maybeSingle();
  }

  @override
  Future<Map<String, dynamic>> insertForumPost(Map<String, dynamic> values) {
    return _client
        .from('educator_forum_posts')
        .insert(values)
        .select(_columns)
        .single();
  }

  @override
  Future<void> updateForumPostById(
    String id,
    Map<String, dynamic> values,
  ) async {
    await _client.from('educator_forum_posts').update(values).eq('id', id);
  }

  @override
  Future<void> deleteForumPostById(String id) async {
    await _client.from('educator_forum_posts').delete().eq('id', id);
  }
}
