import 'package:new_project/resources_and_services/notes_data_source.dart';

/// An in-memory [NotesDataSource] for tests, standing in for a real
/// Supabase project. Mirrors the bits of real Supabase behavior that
/// matter for [NotesLogic][]'s tests: `updateNoteById`/`deleteNoteById`
/// silently do nothing if the id doesn't match any row, exactly like a
/// real `.update()`/`.delete()` with no matching rows would.
///
/// [NotesLogic]: ../../lib/resources_and_services/notes_logic.dart
class FakeNotesDataSource implements NotesDataSource {
  final List<Map<String, dynamic>> rows = [];
  int _nextId = 1;

  @override
  String? currentUserId;

  @override
  Future<List<Map<String, dynamic>>> selectNotes({
    required String userId,
  }) async {
    return rows
        .where((row) => row['user_id'] == userId)
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> insertNote(Map<String, dynamic> values) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final row = {
      'id': 'note-${_nextId++}',
      'created_at': now,
      'updated_at': now,
      ...values,
    };
    rows.add(row);
    return Map<String, dynamic>.from(row);
  }

  @override
  Future<void> updateNoteById(String id, Map<String, dynamic> values) async {
    final index = rows.indexWhere((row) => row['id'] == id);
    if (index == -1) return;
    rows[index] = {...rows[index], ...values};
  }

  @override
  Future<void> deleteNoteById(String id) async {
    rows.removeWhere((row) => row['id'] == id);
  }
}
