import 'package:new_project/resources_and_services/educator_forum_engagement_data_source.dart';

/// An in-memory [EducatorForumEngagementDataSource] for tests, standing in
/// for a real Supabase project. Mirrors [FakeFeedDataSource][]'s
/// likes/comments semantics exactly, scoped to `forum_post_id`.
///
/// [FakeFeedDataSource]: fake_feed_data_source.dart
class FakeEducatorForumEngagementDataSource
    implements EducatorForumEngagementDataSource {
  final List<Map<String, dynamic>> likes = [];
  final List<Map<String, dynamic>> comments = [];
  int _nextCommentId = 1;

  @override
  String? currentUserId;

  @override
  Future<List<Map<String, dynamic>>> selectLikesForForumPostIds(
    List<String> ids,
  ) async {
    return likes
        .where((row) => ids.contains(row['forum_post_id']))
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  @override
  Future<Map<String, dynamic>?> selectLike({
    required String forumPostId,
    required String userId,
  }) async {
    final index = likes.indexWhere(
      (row) => row['forum_post_id'] == forumPostId && row['user_id'] == userId,
    );
    if (index == -1) return null;
    return Map<String, dynamic>.from(likes[index]);
  }

  @override
  Future<void> insertLike({
    required String forumPostId,
    required String userId,
  }) async {
    likes.add({
      'forum_post_id': forumPostId,
      'user_id': userId,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  @override
  Future<void> deleteLike({
    required String forumPostId,
    required String userId,
  }) async {
    likes.removeWhere(
      (row) => row['forum_post_id'] == forumPostId && row['user_id'] == userId,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> selectCommentCountRowsForForumPostIds(
    List<String> ids,
  ) async {
    return comments
        .where((row) => ids.contains(row['forum_post_id']))
        .map((row) => {'forum_post_id': row['forum_post_id']})
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> selectCommentsForForumPost(
    String forumPostId,
  ) async {
    final matches = comments
        .where((row) => row['forum_post_id'] == forumPostId)
        .map((row) => Map<String, dynamic>.from(row))
        .toList()
      ..sort(
        (a, b) =>
            (a['created_at'] as String).compareTo(b['created_at'] as String),
      );
    return matches;
  }

  @override
  Future<void> insertComment(Map<String, dynamic> values) async {
    comments.add({
      'id': 'comment-${_nextCommentId++}',
      'created_at': DateTime.now().toUtc().toIso8601String(),
      ...values,
    });
  }
}
