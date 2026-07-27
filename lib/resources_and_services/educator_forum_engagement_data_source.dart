import 'package:supabase_flutter/supabase_flutter.dart';

/// The raw data operations [EducatorLogic][] needs for comments and likes on
/// SmartAcademy forum posts, kept separate from `SupabaseClient` for the
/// same reason as [FeedDataSource][]: tests substitute an in-memory fake
/// instead of a real Supabase project. Mirrors [FeedDataSource]'s
/// likes/comments half exactly, scoped to `forum_post_id` instead of
/// `shared_note_id`.
///
/// [EducatorLogic]: educator_logic.dart
/// [FeedDataSource]: feed_data_source.dart
abstract class EducatorForumEngagementDataSource {
  String? get currentUserId;

  Future<List<Map<String, dynamic>>> selectLikesForForumPostIds(
    List<String> ids,
  );

  Future<Map<String, dynamic>?> selectLike({
    required String forumPostId,
    required String userId,
  });

  Future<void> insertLike({
    required String forumPostId,
    required String userId,
  });

  Future<void> deleteLike({
    required String forumPostId,
    required String userId,
  });

  /// Rows with just the `forum_post_id` column, for aggregate comment
  /// counts across many forum posts (as opposed to
  /// [selectCommentsForForumPost], which returns full rows for one).
  Future<List<Map<String, dynamic>>> selectCommentCountRowsForForumPostIds(
    List<String> ids,
  );

  Future<List<Map<String, dynamic>>> selectCommentsForForumPost(
    String forumPostId,
  );

  Future<void> insertComment(Map<String, dynamic> values);
}

/// The real [EducatorForumEngagementDataSource], backed by a Supabase
/// project.
class SupabaseEducatorForumEngagementDataSource
    implements EducatorForumEngagementDataSource {
  SupabaseEducatorForumEngagementDataSource(this._client);

  final SupabaseClient _client;

  static const _likesTable = 'educator_forum_post_likes';
  static const _commentsTable = 'educator_forum_post_comments';

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Future<List<Map<String, dynamic>>> selectLikesForForumPostIds(
    List<String> ids,
  ) async {
    if (ids.isEmpty) return [];
    final rows = await _client
        .from(_likesTable)
        .select('forum_post_id,user_id')
        .inFilter('forum_post_id', ids);
    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  @override
  Future<Map<String, dynamic>?> selectLike({
    required String forumPostId,
    required String userId,
  }) {
    return _client
        .from(_likesTable)
        .select('forum_post_id,user_id')
        .eq('forum_post_id', forumPostId)
        .eq('user_id', userId)
        .maybeSingle();
  }

  @override
  Future<void> insertLike({
    required String forumPostId,
    required String userId,
  }) async {
    await _client.from(_likesTable).insert({
      'forum_post_id': forumPostId,
      'user_id': userId,
    });
  }

  @override
  Future<void> deleteLike({
    required String forumPostId,
    required String userId,
  }) async {
    await _client
        .from(_likesTable)
        .delete()
        .eq('forum_post_id', forumPostId)
        .eq('user_id', userId);
  }

  @override
  Future<List<Map<String, dynamic>>> selectCommentCountRowsForForumPostIds(
    List<String> ids,
  ) async {
    if (ids.isEmpty) return [];
    final rows = await _client
        .from(_commentsTable)
        .select('forum_post_id')
        .inFilter('forum_post_id', ids);
    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  @override
  Future<List<Map<String, dynamic>>> selectCommentsForForumPost(
    String forumPostId,
  ) async {
    final rows = await _client
        .from(_commentsTable)
        .select('id,forum_post_id,user_id,content,created_at')
        .eq('forum_post_id', forumPostId)
        .order('created_at');
    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  @override
  Future<void> insertComment(Map<String, dynamic> values) async {
    await _client.from(_commentsTable).insert(values);
  }
}
