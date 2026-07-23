import 'package:new_project/resources_and_services/feed_data_source.dart';

/// An in-memory [FeedDataSource] for tests, standing in for a real Supabase
/// project. Mirrors the bits of real Postgres/Supabase behavior that matter
/// for [NotesLogic][]'s tests: `deleteSharedNoteByNoteAndAuthor` cascades to
/// its recipients/likes/comments exactly like the real `on delete cascade`
/// foreign keys would; `upsertSharedNoteRecipients` leaves an already-present
/// pair untouched (never re-adds/duplicates on republish); `upsertSharedNote`
/// updates the existing row for a (note_id, author_id) pair in place rather
/// than inserting a second one, matching its real `onConflict`.
///
/// [NotesLogic]: ../../lib/resources_and_services/notes_logic.dart
class FakeFeedDataSource implements FeedDataSource {
  final List<Map<String, dynamic>> sharedNotes = [];
  final List<Map<String, dynamic>> recipients = [];
  final List<Map<String, dynamic>> likes = [];
  final List<Map<String, dynamic>> comments = [];
  int _nextSharedNoteId = 1;
  int _nextCommentId = 1;

  @override
  String? currentUserId;

  @override
  Future<Map<String, dynamic>> upsertSharedNote(
    Map<String, dynamic> values,
  ) async {
    final index = sharedNotes.indexWhere(
      (row) =>
          row['note_id'] == values['note_id'] &&
          row['author_id'] == values['author_id'],
    );
    if (index != -1) {
      sharedNotes[index] = {...sharedNotes[index], ...values};
      return Map<String, dynamic>.from(sharedNotes[index]);
    }
    final row = {
      'id': 'shared-${_nextSharedNoteId++}',
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      ...values,
    };
    sharedNotes.add(row);
    return Map<String, dynamic>.from(row);
  }

  @override
  Future<void> deleteSharedNoteByNoteAndAuthor({
    required String noteId,
    required String authorId,
  }) async {
    final removed = sharedNotes.where(
      (row) => row['note_id'] == noteId && row['author_id'] == authorId,
    );
    final removedIds = removed.map((row) => row['id']).toSet();
    sharedNotes.removeWhere(
      (row) => row['note_id'] == noteId && row['author_id'] == authorId,
    );
    recipients.removeWhere((row) => removedIds.contains(row['shared_note_id']));
    likes.removeWhere((row) => removedIds.contains(row['shared_note_id']));
    comments.removeWhere((row) => removedIds.contains(row['shared_note_id']));
  }

  @override
  Future<List<Map<String, dynamic>>> selectSharedNotesAuthoredBy(
    String userId,
  ) async {
    return sharedNotes
        .where((row) => row['author_id'] == userId)
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> selectPublishedNoteIdRowsForAuthor(
    String userId,
  ) async {
    return sharedNotes
        .where((row) => row['author_id'] == userId)
        .map((row) => {'note_id': row['note_id']})
        .toList();
  }

  @override
  Future<void> upsertSharedNoteRecipients(
    List<Map<String, dynamic>> rows,
  ) async {
    for (final values in rows) {
      final exists = recipients.any(
        (row) =>
            row['shared_note_id'] == values['shared_note_id'] &&
            row['recipient_id'] == values['recipient_id'],
      );
      if (exists) continue;
      recipients.add({
        'created_at': DateTime.now().toUtc().toIso8601String(),
        ...values,
      });
    }
  }

  @override
  Future<List<String>> selectSharedNoteIdsForRecipient(String userId) async {
    return recipients
        .where((row) => row['recipient_id'] == userId)
        .map((row) => row['shared_note_id'].toString())
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> selectSharedNotesByIds(
    List<String> ids,
  ) async {
    return sharedNotes
        .where((row) => ids.contains(row['id']))
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> selectLikesForSharedNoteIds(
    List<String> ids,
  ) async {
    return likes
        .where((row) => ids.contains(row['shared_note_id']))
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  @override
  Future<Map<String, dynamic>?> selectLike({
    required String sharedNoteId,
    required String userId,
  }) async {
    final index = likes.indexWhere(
      (row) =>
          row['shared_note_id'] == sharedNoteId && row['user_id'] == userId,
    );
    if (index == -1) return null;
    return Map<String, dynamic>.from(likes[index]);
  }

  @override
  Future<void> insertLike({
    required String sharedNoteId,
    required String userId,
  }) async {
    likes.add({
      'shared_note_id': sharedNoteId,
      'user_id': userId,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  @override
  Future<void> deleteLike({
    required String sharedNoteId,
    required String userId,
  }) async {
    likes.removeWhere(
      (row) =>
          row['shared_note_id'] == sharedNoteId && row['user_id'] == userId,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> selectCommentCountRowsForSharedNoteIds(
    List<String> ids,
  ) async {
    return comments
        .where((row) => ids.contains(row['shared_note_id']))
        .map((row) => {'shared_note_id': row['shared_note_id']})
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> selectCommentsForSharedNote(
    String sharedNoteId,
  ) async {
    final matches = comments
        .where((row) => row['shared_note_id'] == sharedNoteId)
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
