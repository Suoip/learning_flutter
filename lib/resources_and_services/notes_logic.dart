import 'dart:typed_data';

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

class UserProfile {
  const UserProfile({
    required this.id,
    required this.username,
    required this.avatarUrl,
  });

  final String id;
  final String username;
  final String? avatarUrl;

  factory UserProfile.fromMap({
    required User user,
    required Map<String, dynamic> map,
  }) {
    final usernameFromRow =
        (map['username'] ?? '').toString().trim().toLowerCase();

    return UserProfile(
      id: user.id,
      username: usernameFromRow.isEmpty
          ? NotesLogic.defaultUsernameForUser(user)
          : usernameFromRow,
      avatarUrl: (map['avatar_url'] as String?)?.trim(),
    );
  }
}

class NotesLogic {
  NotesLogic({SupabaseClient? client}) : _client = client ?? AppSupabase.client;

  final SupabaseClient _client;
  static const String _authDomain = 'notesapp.dev';
  static const String _profilesTable = 'profiles';
  static const String _avatarsBucket = 'profile-pictures';

  User? get currentUser => _client.auth.currentUser;

  static String formatUpdatedTime(DateTime dateTime) {
    return DateFormat('MMM d, h:mm a').format(dateTime.toLocal());
  }

  static String usernameToEmail(String username) {
    return '${username.trim().toLowerCase()}@$_authDomain';
  }

  static String defaultUsernameForUser(User user) {
    final metadataUsername =
        (user.userMetadata?['username'] ?? '').toString().trim();
    if (metadataUsername.isNotEmpty) return metadataUsername.toLowerCase();

    final email = user.email ?? '';
    final splitIndex = email.indexOf('@');
    if (splitIndex <= 0) return 'user';
    return email.substring(0, splitIndex).trim().toLowerCase();
  }

  static bool isValidUsername(String username) {
    final normalized = username.trim();
    final allowed = RegExp(r'^[a-zA-Z0-9_.-]{3,30}$');
    return allowed.hasMatch(normalized);
  }

  Future<void> ensureProfileForCurrentUser({String? preferredUsername}) async {
    final user = currentUser;
    if (user == null) return;

    final existing = await _client
        .from(_profilesTable)
        .select('id')
        .eq('id', user.id)
        .maybeSingle();

    if (existing != null) return;

    final fallback = (preferredUsername ?? defaultUsernameForUser(user))
        .trim()
        .toLowerCase();
    await _client.from(_profilesTable).insert({
      'id': user.id,
      'username': fallback,
      'avatar_url': null,
    });
  }

  Future<UserProfile> fetchCurrentProfile() async {
    final user = currentUser;
    if (user == null) {
      throw Exception('No logged-in user.');
    }

    await ensureProfileForCurrentUser();

    final row = await _client
        .from(_profilesTable)
        .select('id,username,avatar_url')
        .eq('id', user.id)
        .single();

    return UserProfile.fromMap(
      user: user,
      map: row,
    );
  }

  Future<UserProfile> updateUsername(String username) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('No logged-in user.');
    }

    final normalized = username.trim().toLowerCase();
    if (!isValidUsername(normalized)) {
      throw Exception('Use 3-30 chars: letters, numbers, _, -, .');
    }

    final nextEmail = usernameToEmail(normalized);
    try {
      await _client.auth.updateUser(
        UserAttributes(
          email: nextEmail,
          data: {'username': normalized},
        ),
      );
    } on AuthException catch (error) {
      final message = error.message.toLowerCase();
      if (message.contains('already') || message.contains('duplicate')) {
        throw Exception('Username is already taken.');
      }
      throw Exception(error.message);
    }

    await _client.from(_profilesTable).upsert({
      'id': user.id,
      'username': normalized,
    }, onConflict: 'id');

    return fetchCurrentProfile();
  }

  Future<void> updatePassword(String password) async {
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters.');
    }

    try {
      await _client.auth.updateUser(UserAttributes(password: password));
    } on AuthException catch (error) {
      throw Exception(error.message);
    }
  }

  Future<UserProfile> uploadProfileAvatar({
    required Uint8List bytes,
    required String extension,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('No logged-in user.');
    }

    final normalizedExtension = extension.trim().toLowerCase();
    final isValidExtension =
        RegExp(r'^[a-z0-9]{2,5}$').hasMatch(normalizedExtension);
    if (!isValidExtension) {
      throw Exception('Unsupported file extension.');
    }

    final objectPath = '${user.id}/avatar.$normalizedExtension';
    await _client.storage.from(_avatarsBucket).uploadBinary(
          objectPath,
          bytes,
          fileOptions: const FileOptions(
            upsert: true,
            cacheControl: '3600',
          ),
        );

    final timestamp = DateTime.now().toUtc().millisecondsSinceEpoch;
    final avatarUrl =
        '${_client.storage.from(_avatarsBucket).getPublicUrl(objectPath)}?v=$timestamp';

    await _client.from(_profilesTable).upsert({
      'id': user.id,
      'avatar_url': avatarUrl,
    }, onConflict: 'id');

    return fetchCurrentProfile();
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
      final matchesQuery =
          query.isEmpty || note.title.toLowerCase().contains(query);
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
    await ensureProfileForCurrentUser(preferredUsername: normalized);
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
      final canProceedToSignup = message.contains('invalid') ||
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

    await ensureProfileForCurrentUser(preferredUsername: normalized);
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
