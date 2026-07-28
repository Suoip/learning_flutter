import 'package:new_project/resources_and_services/educator_videos_data_source.dart';

/// An in-memory [EducatorVideosDataSource] for tests, standing in for a
/// real Supabase project. Mirrors [FakeNotesDataSource]'s behavior:
/// `updateVideoById`/`deleteVideoById` silently do nothing if the id
/// doesn't match any row, exactly like a real `.update()`/`.delete()` with
/// no matching rows would.
///
/// [FakeNotesDataSource]: fake_notes_data_source.dart
class FakeEducatorVideosDataSource implements EducatorVideosDataSource {
  final List<Map<String, dynamic>> rows = [];

  /// Keyed by educator id - populated by tests to simulate the real
  /// `educators` embed for [selectRecentVideosWithAuthor].
  final Map<String, Map<String, dynamic>> educators = {};

  int _nextId = 1;

  @override
  String? currentUserId;

  @override
  Future<List<Map<String, dynamic>>> selectVideos({
    required String educatorId,
  }) async {
    return rows
        .where((row) => row['educator_id'] == educatorId)
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> selectRecentVideosWithAuthor({
    required int limit,
  }) async {
    final sorted = [...rows]..sort(
        (a, b) =>
            (b['updated_at'] as String).compareTo(a['updated_at'] as String),
      );
    return sorted.take(limit).map((row) {
      return {
        ...row,
        'educators': educators[row['educator_id']],
      };
    }).toList();
  }

  @override
  Future<Map<String, dynamic>> insertVideo(
    Map<String, dynamic> values,
  ) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final row = {
      'id': 'video-${_nextId++}',
      'created_at': now,
      'updated_at': now,
      ...values,
    };
    rows.add(row);
    return Map<String, dynamic>.from(row);
  }

  @override
  Future<void> updateVideoById(String id, Map<String, dynamic> values) async {
    final index = rows.indexWhere((row) => row['id'] == id);
    if (index == -1) return;
    rows[index] = {...rows[index], ...values};
  }

  @override
  Future<void> deleteVideoById(String id) async {
    rows.removeWhere((row) => row['id'] == id);
  }
}
