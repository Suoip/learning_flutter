import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_client.dart';

enum NoteQuickFilter { all, pinned, favorites }

class NoteItem {
  const NoteItem({
    required this.id,
    required this.title,
    required this.content,
    required this.updatedAt,
    required this.isPinned,
    required this.isFavorite,
  });

  final String id;
  final String title;
  final String content;
  final DateTime updatedAt;
  final bool isPinned;
  final bool isFavorite;

  factory NoteItem.fromMap(Map<String, dynamic> map) {
    final updatedValue = map['updated_at'] ?? map['created_at'];
    final updatedAt = updatedValue == null
        ? DateTime.now().toUtc()
        : DateTime.parse(updatedValue.toString()).toUtc();

    return NoteItem(
      id: map['id'].toString(),
      title: (map['title'] ?? '').toString(),
      content: (map['content'] ?? '').toString(),
      updatedAt: updatedAt,
      isPinned: map['is_pinned'] == true,
      isFavorite: map['is_favorite'] == true,
    );
  }
}

class NotesLogic {
  NotesLogic({SupabaseClient? client}) : _client = client ?? AppSupabase.client;

  final SupabaseClient _client;
  static const String _authDomain = 'notesapp.dev';

  User? get currentUser => _client.auth.currentUser;

  static String formatUpdatedTime(DateTime dateTime) {
    return DateFormat('MMM d, h:mm a').format(dateTime.toLocal());
  }

  static String usernameToEmail(String username) {
    return '${username.trim().toLowerCase()}@$_authDomain';
  }

  Future<List<NoteItem>> fetchNotesForCurrentUser() async {
    final user = currentUser;
    if (user == null) return [];

    final rows = await _client
        .from('notes')
        .select('id,title,content,updated_at,created_at,is_pinned,is_favorite')
        .eq('user_id', user.id)
        .order('updated_at', ascending: false);

    final notes = (rows as List<dynamic>)
        .map((row) => NoteItem.fromMap(row as Map<String, dynamic>))
        .toList();

    return sortNotes(notes);
  }

  List<NoteItem> filterNotes({
    required List<NoteItem> notes,
    required String searchQuery,
    required NoteQuickFilter filter,
  }) {
    final query = searchQuery.trim().toLowerCase();

    final filtered = notes.where((note) {
      final matchesQuery = query.isEmpty || note.title.toLowerCase().contains(query);
      if (!matchesQuery) return false;

      switch (filter) {
        case NoteQuickFilter.all:
          return true;
        case NoteQuickFilter.pinned:
          return note.isPinned;
        case NoteQuickFilter.favorites:
          return note.isFavorite;
      }
    }).toList();

    return sortNotes(filtered);
  }

  Future<NoteItem> createNote(String title) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('No logged-in user.');
    }

    final inserted = await _client
        .from('notes')
        .insert({
          'user_id': user.id,
          'title': title.trim(),
          'content': '',
          'is_pinned': false,
          'is_favorite': false,
        })
        .select('id,title,content,updated_at,created_at,is_pinned,is_favorite')
        .single();

    return NoteItem.fromMap(inserted);
  }

  Future<void> updateNote({
    required String noteId,
    required String title,
    required String content,
  }) async {
    await _client.from('notes').update({
      'title': title,
      'content': content,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', noteId);
  }

  Future<void> togglePin(NoteItem note) async {
    await _client.from('notes').update({
      'is_pinned': !note.isPinned,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', note.id);
  }

  Future<void> toggleFavorite(NoteItem note) async {
    await _client.from('notes').update({
      'is_favorite': !note.isFavorite,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', note.id);
  }

  Future<void> deleteNote(String noteId) async {
    await _client.from('notes').delete().eq('id', noteId);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> signInWithUsername({
    required String username,
    required String password,
  }) async {
    final normalized = username.trim().toLowerCase();
    final email = usernameToEmail(normalized);
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUpWithUsername({
    required String username,
    required String password,
  }) async {
    final normalized = username.trim().toLowerCase();
    final email = usernameToEmail(normalized);

    // Avoid unnecessary sign-up requests (which can trigger email rate limits)
    // when this username/password account already exists.
    try {
      await signInWithUsername(username: normalized, password: password);
      return;
    } on AuthException catch (error) {
      final message = error.message.toLowerCase();
      final canProceedToSignup =
          message.contains('invalid') ||
          message.contains('credentials') ||
          message.contains('password');

      if (!canProceedToSignup) {
        throw Exception(error.message);
      }
    }

    try {
      await _client.auth.signUp(
        email: email,
        password: password,
        data: {'username': normalized},
      );
    } on AuthException catch (error) {
      final message = error.message.toLowerCase();
      if (message.contains('already')) {
        throw Exception('Username is already taken.');
      }
      if (message.contains('rate limit')) {
        throw Exception(
          'Email rate limit exceeded. If you recently created this account, use Login. '
          'Otherwise wait a minute and disable email confirmation in Supabase Auth settings.',
        );
      }
      throw Exception(error.message);
    }

    if (currentUser == null) {
      try {
        await signInWithUsername(username: normalized, password: password);
      } on AuthException catch (error) {
        final message = error.message.toLowerCase();
        if (message.contains('confirm') || message.contains('not confirmed')) {
          throw Exception(
            'Account created but email confirmation is enabled in Supabase. '
            'Disable email confirmation for username/password flow.',
          );
        }
        throw Exception(error.message);
      }
    }
  }

  List<NoteItem> sortNotes(List<NoteItem> notes) {
    final sorted = [...notes];
    sorted.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return sorted;
  }
}
