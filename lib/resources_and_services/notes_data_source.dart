import 'package:supabase_flutter/supabase_flutter.dart';

/// The raw data operations [NotesLogic][] needs to manage notes, kept
/// separate from `SupabaseClient` so tests can substitute an in-memory
/// fake instead of a real Supabase project. `SupabaseClient`'s table
/// queries use a fluent builder API (`.from().select().eq().order()...`)
/// that's painful to mock directly, since each chained call returns a
/// different builder type - this interface sidesteps that by only
/// exposing the handful of operations actually used, at the level of
/// plain maps in and out.
///
/// [NotesLogic]: notes_logic.dart
abstract class NotesDataSource {
  /// The currently authenticated user's id, or null if signed out.
  String? get currentUserId;

  Future<List<Map<String, dynamic>>> selectNotes({required String userId});

  Future<Map<String, dynamic>> insertNote(Map<String, dynamic> values);

  Future<void> updateNoteById(String id, Map<String, dynamic> values);

  Future<void> deleteNoteById(String id);
}

/// The real [NotesDataSource], backed by a Supabase project.
class SupabaseNotesDataSource implements NotesDataSource {
  SupabaseNotesDataSource(this._client);

  final SupabaseClient _client;

  static const _columns =
      'id,title,content,updated_at,created_at,is_pinned,is_favorite';

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Future<List<Map<String, dynamic>>> selectNotes({
    required String userId,
  }) async {
    final rows = await _client
        .from('notes')
        .select(_columns)
        .eq('user_id', userId)
        .order('updated_at', ascending: false);
    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  @override
  Future<Map<String, dynamic>> insertNote(Map<String, dynamic> values) {
    return _client.from('notes').insert(values).select(_columns).single();
  }

  @override
  Future<void> updateNoteById(String id, Map<String, dynamic> values) async {
    await _client.from('notes').update(values).eq('id', id);
  }

  @override
  Future<void> deleteNoteById(String id) async {
    await _client.from('notes').delete().eq('id', id);
  }
}
