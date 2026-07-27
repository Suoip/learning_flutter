import 'package:new_project/resources_and_services/educator_forum_posts_data_source.dart';

/// An in-memory [EducatorForumPostsDataSource] for tests, standing in for a
/// real Supabase project. Mirrors [FakeEducatorVideosDataSource]'s
/// behavior: `updateForumPostById`/`deleteForumPostById` silently do
/// nothing if the id doesn't match any row, exactly like a real
/// `.update()`/`.delete()` with no matching rows would.
///
/// [FakeEducatorVideosDataSource]: fake_educator_videos_data_source.dart
class FakeEducatorForumPostsDataSource implements EducatorForumPostsDataSource {
  final List<Map<String, dynamic>> rows = [];
  int _nextId = 1;

  @override
  String? currentUserId;

  @override
  Future<List<Map<String, dynamic>>> selectForumPosts({
    required String educatorId,
  }) async {
    return rows
        .where((row) => row['educator_id'] == educatorId)
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> insertForumPost(
    Map<String, dynamic> values,
  ) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final row = {
      'id': 'post-${_nextId++}',
      'created_at': now,
      'updated_at': now,
      ...values,
    };
    rows.add(row);
    return Map<String, dynamic>.from(row);
  }

  @override
  Future<void> updateForumPostById(
    String id,
    Map<String, dynamic> values,
  ) async {
    final index = rows.indexWhere((row) => row['id'] == id);
    if (index == -1) return;
    rows[index] = {...rows[index], ...values};
  }

  @override
  Future<void> deleteForumPostById(String id) async {
    rows.removeWhere((row) => row['id'] == id);
  }
}
