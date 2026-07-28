import 'package:new_project/resources_and_services/educator_video_engagement_data_source.dart';

/// An in-memory [EducatorVideoEngagementDataSource] for tests, standing in
/// for a real Supabase project. Mirrors
/// [FakeEducatorForumEngagementDataSource][]'s semantics exactly, scoped to
/// `video_id`.
///
/// [FakeEducatorForumEngagementDataSource]: fake_educator_forum_engagement_data_source.dart
class FakeEducatorVideoEngagementDataSource
    implements EducatorVideoEngagementDataSource {
  final List<Map<String, dynamic>> likes = [];
  final List<Map<String, dynamic>> comments = [];
  int _nextCommentId = 1;

  @override
  String? currentUserId;

  @override
  Future<List<Map<String, dynamic>>> selectLikesForVideoIds(
    List<String> ids,
  ) async {
    return likes
        .where((row) => ids.contains(row['video_id']))
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  @override
  Future<Map<String, dynamic>?> selectLike({
    required String videoId,
    required String userId,
  }) async {
    final index = likes.indexWhere(
      (row) => row['video_id'] == videoId && row['user_id'] == userId,
    );
    if (index == -1) return null;
    return Map<String, dynamic>.from(likes[index]);
  }

  @override
  Future<void> insertLike({
    required String videoId,
    required String userId,
  }) async {
    likes.add({
      'video_id': videoId,
      'user_id': userId,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  @override
  Future<void> deleteLike({
    required String videoId,
    required String userId,
  }) async {
    likes.removeWhere(
      (row) => row['video_id'] == videoId && row['user_id'] == userId,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> selectCommentCountRowsForVideoIds(
    List<String> ids,
  ) async {
    return comments
        .where((row) => ids.contains(row['video_id']))
        .map((row) => {'video_id': row['video_id']})
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> selectCommentsForVideo(
    String videoId,
  ) async {
    final matches = comments
        .where((row) => row['video_id'] == videoId)
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
