import 'package:supabase_flutter/supabase_flutter.dart';

/// The raw data operations [NotesLogic][] needs for the friends feed
/// (published notes, who they're shared with, likes, and comments), kept
/// separate from `SupabaseClient` for the same reason as [NotesDataSource][]:
/// tests substitute an in-memory fake instead of a real Supabase project.
///
/// As with [FriendsDataSource][], every method only ever needs the current
/// user's id, not the full [User].
///
/// [NotesLogic]: notes_logic.dart
/// [NotesDataSource]: notes_data_source.dart
/// [FriendsDataSource]: friends_data_source.dart
abstract class FeedDataSource {
  String? get currentUserId;

  /// Inserts or updates the single shared-note row for a (note, author) pair
  /// and returns it (callers need the row's `id` to attach recipients).
  Future<Map<String, dynamic>> upsertSharedNote(Map<String, dynamic> values);

  Future<void> deleteSharedNoteByNoteAndAuthor({
    required String noteId,
    required String authorId,
  });

  Future<List<Map<String, dynamic>>> selectSharedNotesAuthoredBy(
    String userId,
  );

  /// Rows with just the `note_id` column, for
  /// `fetchPublishedNoteIdsForCurrentUser`.
  Future<List<Map<String, dynamic>>> selectPublishedNoteIdRowsForAuthor(
    String userId,
  );

  /// Adds recipients for a shared note. A pair already present is left
  /// untouched (never revokes existing recipients).
  Future<void> upsertSharedNoteRecipients(List<Map<String, dynamic>> rows);

  Future<List<String>> selectSharedNoteIdsForRecipient(String userId);

  Future<List<Map<String, dynamic>>> selectSharedNotesByIds(List<String> ids);

  Future<List<Map<String, dynamic>>> selectLikesForSharedNoteIds(
    List<String> ids,
  );

  Future<Map<String, dynamic>?> selectLike({
    required String sharedNoteId,
    required String userId,
  });

  Future<void> insertLike({
    required String sharedNoteId,
    required String userId,
  });

  Future<void> deleteLike({
    required String sharedNoteId,
    required String userId,
  });

  /// Rows with just the `shared_note_id` column, for aggregate comment
  /// counts across many shared notes (as opposed to
  /// [selectCommentsForSharedNote], which returns full rows for one).
  Future<List<Map<String, dynamic>>> selectCommentCountRowsForSharedNoteIds(
    List<String> ids,
  );

  Future<List<Map<String, dynamic>>> selectCommentsForSharedNote(
    String sharedNoteId,
  );

  Future<void> insertComment(Map<String, dynamic> values);
}

/// The real [FeedDataSource], backed by a Supabase project.
class SupabaseFeedDataSource implements FeedDataSource {
  SupabaseFeedDataSource(this._client);

  final SupabaseClient _client;

  static const _notesTable = 'shared_notes';
  static const _recipientsTable = 'shared_note_recipients';
  static const _likesTable = 'shared_note_likes';
  static const _commentsTable = 'shared_note_comments';
  static const _noteColumns = 'id,note_id,author_id,title,content,published_at';

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Future<Map<String, dynamic>> upsertSharedNote(
    Map<String, dynamic> values,
  ) {
    return _client
        .from(_notesTable)
        .upsert(values, onConflict: 'note_id,author_id')
        .select(_noteColumns)
        .single();
  }

  @override
  Future<void> deleteSharedNoteByNoteAndAuthor({
    required String noteId,
    required String authorId,
  }) async {
    await _client
        .from(_notesTable)
        .delete()
        .eq('note_id', noteId)
        .eq('author_id', authorId);
  }

  @override
  Future<List<Map<String, dynamic>>> selectSharedNotesAuthoredBy(
    String userId,
  ) async {
    final rows = await _client
        .from(_notesTable)
        .select(_noteColumns)
        .eq('author_id', userId)
        .order('published_at', ascending: false);
    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  @override
  Future<List<Map<String, dynamic>>> selectPublishedNoteIdRowsForAuthor(
    String userId,
  ) async {
    final rows = await _client
        .from(_notesTable)
        .select('note_id')
        .eq('author_id', userId);
    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  @override
  Future<void> upsertSharedNoteRecipients(
    List<Map<String, dynamic>> rows,
  ) async {
    if (rows.isEmpty) return;
    await _client
        .from(_recipientsTable)
        .upsert(rows, onConflict: 'shared_note_id,recipient_id');
  }

  @override
  Future<List<String>> selectSharedNoteIdsForRecipient(String userId) async {
    final rows = await _client
        .from(_recipientsTable)
        .select('shared_note_id')
        .eq('recipient_id', userId);
    return (rows as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map((row) => row['shared_note_id'].toString())
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> selectSharedNotesByIds(
    List<String> ids,
  ) async {
    if (ids.isEmpty) return [];
    final rows = await _client
        .from(_notesTable)
        .select(_noteColumns)
        .inFilter('id', ids)
        .order('published_at', ascending: false);
    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  @override
  Future<List<Map<String, dynamic>>> selectLikesForSharedNoteIds(
    List<String> ids,
  ) async {
    if (ids.isEmpty) return [];
    final rows = await _client
        .from(_likesTable)
        .select('shared_note_id,user_id')
        .inFilter('shared_note_id', ids);
    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  @override
  Future<Map<String, dynamic>?> selectLike({
    required String sharedNoteId,
    required String userId,
  }) {
    return _client
        .from(_likesTable)
        .select('shared_note_id,user_id')
        .eq('shared_note_id', sharedNoteId)
        .eq('user_id', userId)
        .maybeSingle();
  }

  @override
  Future<void> insertLike({
    required String sharedNoteId,
    required String userId,
  }) async {
    await _client.from(_likesTable).insert({
      'shared_note_id': sharedNoteId,
      'user_id': userId,
    });
  }

  @override
  Future<void> deleteLike({
    required String sharedNoteId,
    required String userId,
  }) async {
    await _client
        .from(_likesTable)
        .delete()
        .eq('shared_note_id', sharedNoteId)
        .eq('user_id', userId);
  }

  @override
  Future<List<Map<String, dynamic>>> selectCommentCountRowsForSharedNoteIds(
    List<String> ids,
  ) async {
    if (ids.isEmpty) return [];
    final rows = await _client
        .from(_commentsTable)
        .select('shared_note_id')
        .inFilter('shared_note_id', ids);
    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  @override
  Future<List<Map<String, dynamic>>> selectCommentsForSharedNote(
    String sharedNoteId,
  ) async {
    final rows = await _client
        .from(_commentsTable)
        .select('id,shared_note_id,user_id,content,created_at')
        .eq('shared_note_id', sharedNoteId)
        .order('created_at');
    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  @override
  Future<void> insertComment(Map<String, dynamic> values) async {
    await _client.from(_commentsTable).insert(values);
  }
}
