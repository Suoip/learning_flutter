import 'package:supabase_flutter/supabase_flutter.dart';

/// The raw data operations [EducatorLogic][] needs for comments and likes on
/// SmartAcademy videos, kept separate from `SupabaseClient` for the same
/// reason as [EducatorForumEngagementDataSource][]: tests substitute an
/// in-memory fake instead of a real Supabase project. Mirrors
/// [EducatorForumEngagementDataSource]'s shape exactly, scoped to
/// `video_id` instead of `forum_post_id`.
///
/// [EducatorLogic]: educator_logic.dart
/// [EducatorForumEngagementDataSource]: educator_forum_engagement_data_source.dart
abstract class EducatorVideoEngagementDataSource {
  String? get currentUserId;

  Future<List<Map<String, dynamic>>> selectLikesForVideoIds(
    List<String> ids,
  );

  Future<Map<String, dynamic>?> selectLike({
    required String videoId,
    required String userId,
  });

  Future<void> insertLike({
    required String videoId,
    required String userId,
  });

  Future<void> deleteLike({
    required String videoId,
    required String userId,
  });

  /// Rows with just the `video_id` column, for aggregate comment counts
  /// across many videos (as opposed to [selectCommentsForVideo], which
  /// returns full rows for one).
  Future<List<Map<String, dynamic>>> selectCommentCountRowsForVideoIds(
    List<String> ids,
  );

  Future<List<Map<String, dynamic>>> selectCommentsForVideo(String videoId);

  Future<void> insertComment(Map<String, dynamic> values);
}

/// The real [EducatorVideoEngagementDataSource], backed by a Supabase
/// project.
class SupabaseEducatorVideoEngagementDataSource
    implements EducatorVideoEngagementDataSource {
  SupabaseEducatorVideoEngagementDataSource(this._client);

  final SupabaseClient _client;

  static const _likesTable = 'educator_video_likes';
  static const _commentsTable = 'educator_video_comments';

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Future<List<Map<String, dynamic>>> selectLikesForVideoIds(
    List<String> ids,
  ) async {
    if (ids.isEmpty) return [];
    final rows = await _client
        .from(_likesTable)
        .select('video_id,user_id')
        .inFilter('video_id', ids);
    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  @override
  Future<Map<String, dynamic>?> selectLike({
    required String videoId,
    required String userId,
  }) {
    return _client
        .from(_likesTable)
        .select('video_id,user_id')
        .eq('video_id', videoId)
        .eq('user_id', userId)
        .maybeSingle();
  }

  @override
  Future<void> insertLike({
    required String videoId,
    required String userId,
  }) async {
    await _client.from(_likesTable).insert({
      'video_id': videoId,
      'user_id': userId,
    });
  }

  @override
  Future<void> deleteLike({
    required String videoId,
    required String userId,
  }) async {
    await _client
        .from(_likesTable)
        .delete()
        .eq('video_id', videoId)
        .eq('user_id', userId);
  }

  @override
  Future<List<Map<String, dynamic>>> selectCommentCountRowsForVideoIds(
    List<String> ids,
  ) async {
    if (ids.isEmpty) return [];
    final rows = await _client
        .from(_commentsTable)
        .select('video_id')
        .inFilter('video_id', ids);
    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  @override
  Future<List<Map<String, dynamic>>> selectCommentsForVideo(
    String videoId,
  ) async {
    final rows = await _client
        .from(_commentsTable)
        .select('id,video_id,user_id,content,created_at')
        .eq('video_id', videoId)
        .order('created_at');
    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  @override
  Future<void> insertComment(Map<String, dynamic> values) async {
    await _client.from(_commentsTable).insert(values);
  }
}
