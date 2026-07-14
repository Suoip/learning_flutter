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

class ProfilePreview {
  const ProfilePreview({
    required this.id,
    required this.username,
    required this.avatarUrl,
  });

  final String id;
  final String username;
  final String? avatarUrl;

  factory ProfilePreview.fromMap(Map<String, dynamic> map) {
    return ProfilePreview(
      id: map['id'].toString(),
      username: (map['username'] ?? '').toString(),
      avatarUrl: (map['avatar_url'] as String?)?.trim(),
    );
  }
}

class FriendRequestItem {
  const FriendRequestItem({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
    required this.counterpart,
    required this.isIncoming,
  });

  final String id;
  final String senderId;
  final String receiverId;
  final String status;
  final DateTime createdAt;
  final ProfilePreview counterpart;
  final bool isIncoming;
}

class FriendItem {
  const FriendItem({
    required this.friendshipId,
    required this.friend,
    required this.createdAt,
  });

  final String friendshipId;
  final ProfilePreview friend;
  final DateTime createdAt;
}

class SharedNoteFeedItem {
  const SharedNoteFeedItem({
    required this.id,
    required this.noteId,
    required this.authorId,
    required this.authorUsername,
    required this.authorAvatarUrl,
    required this.title,
    required this.content,
    required this.publishedAt,
    required this.likeCount,
    required this.commentCount,
    required this.isLikedByCurrentUser,
  });

  final String id;
  final String noteId;
  final String authorId;
  final String authorUsername;
  final String? authorAvatarUrl;
  final String title;
  final String content;
  final DateTime publishedAt;
  final int likeCount;
  final int commentCount;
  final bool isLikedByCurrentUser;
}

class FeedCommentItem {
  const FeedCommentItem({
    required this.id,
    required this.sharedNoteId,
    required this.authorId,
    required this.authorUsername,
    required this.authorAvatarUrl,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String sharedNoteId;
  final String authorId;
  final String authorUsername;
  final String? authorAvatarUrl;
  final String content;
  final DateTime createdAt;
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

  static DateTime parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now().toUtc();
    return DateTime.parse(value.toString()).toUtc();
  }

  static String userMessageForError(
    Object error, {
    String fallback = 'Something went wrong. Please try again.',
  }) {
    if (error is AuthException) {
      final message = error.message.toLowerCase();
      if (message.contains('invalid login') ||
          message.contains('invalid credentials') ||
          message.contains('invalid') ||
          message.contains('password')) {
        return 'Incorrect username or password. Please try again.';
      }
      if (message.contains('already') || message.contains('duplicate')) {
        return 'That username is already taken.';
      }
      if (message.contains('confirm') || message.contains('not confirmed')) {
        return 'Your account needs email confirmation before login.';
      }
      if (message.contains('rate limit') || message.contains('too many')) {
        return 'Too many attempts. Please wait a moment and try again.';
      }
      return 'Authentication failed. Please try again.';
    }

    if (error is PostgrestException) {
      if (error.code == '23505') return 'That value is already in use.';
      if (error.code == '42501') {
        return 'You do not have permission to do that.';
      }
      return fallback;
    }

    if (error is StorageException) {
      final message = error.message.toLowerCase();
      if (message.contains('size') || message.contains('mime')) {
        return 'That file is not supported. Use JPG, PNG, or WEBP up to 5MB.';
      }
      return 'Unable to upload file right now. Please try again.';
    }

    final plain = error.toString().replaceFirst('Exception: ', '').trim();
    if (plain.isEmpty) return fallback;
    if (plain.contains('AuthApiException(') ||
        plain.contains('AuthException(')) {
      return 'Authentication failed. Please try again.';
    }
    return plain;
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
      throw Exception('You are not logged in.');
    }

    await ensureProfileForCurrentUser();

    final row = await _client
        .from(_profilesTable)
        .select('id,username,avatar_url')
        .eq('id', user.id)
        .single();

    return UserProfile.fromMap(user: user, map: row);
  }

  Future<UserProfile> updateUsername(String username) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('You are not logged in.');
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
      throw Exception(userMessageForError(error));
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
      throw Exception(userMessageForError(error));
    }
  }

  Future<UserProfile> uploadProfileAvatar({
    required Uint8List bytes,
    required String extension,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('You are not logged in.');
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
      throw Exception('You are not logged in.');
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
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (error) {
      throw Exception(userMessageForError(error));
    }
    await ensureProfileForCurrentUser(preferredUsername: normalized);
  }

  Future<void> signUpWithUsername({
    required String username,
    required String password,
  }) async {
    final normalized = username.trim().toLowerCase();
    final email = usernameToEmail(normalized);

    try {
      await signInWithUsername(username: normalized, password: password);
      return;
    } on Exception catch (_) {}

    try {
      await _client.auth.signUp(
        email: email,
        password: password,
        data: {'username': normalized},
      );
    } on AuthException catch (error) {
      throw Exception(userMessageForError(error));
    }

    if (currentUser == null) {
      try {
        await signInWithUsername(username: normalized, password: password);
      } on Exception catch (error) {
        throw Exception(userMessageForError(error));
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

  String _pairLow(String a, String b) => a.compareTo(b) <= 0 ? a : b;

  String _pairHigh(String a, String b) => a.compareTo(b) <= 0 ? b : a;

  Future<List<ProfilePreview>> searchUsersByUsername(String query) async {
    final user = currentUser;
    if (user == null) return [];

    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return [];

    final rows = await _client
        .from('profiles')
        .select('id,username,avatar_url')
        .ilike('username', '%$normalized%')
        .neq('id', user.id)
        .order('username')
        .limit(20);

    return (rows as List<dynamic>)
        .map((row) => ProfilePreview.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<bool> _areFriends(String userA, String userB) async {
    final low = _pairLow(userA, userB);
    final high = _pairHigh(userA, userB);
    final row = await _client
        .from('friendships')
        .select('id')
        .eq('user_low_id', low)
        .eq('user_high_id', high)
        .maybeSingle();
    return row != null;
  }

  Future<void> sendFriendRequestByUsername(String username) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('You are not logged in.');
    }

    final normalized = username.trim().toLowerCase();
    if (!isValidUsername(normalized)) {
      throw Exception('Enter a valid username.');
    }

    final target = await _client
        .from('profiles')
        .select('id,username')
        .eq('username', normalized)
        .maybeSingle();
    if (target == null) {
      throw Exception('No user found with that username.');
    }

    final targetId = target['id'].toString();
    if (targetId == user.id) {
      throw Exception('You cannot send a friend request to yourself.');
    }

    if (await _areFriends(user.id, targetId)) {
      throw Exception('You are already friends.');
    }

    final existing = await _client
        .from('friend_requests')
        .select('id')
        .or('and(sender_id.eq.${user.id},receiver_id.eq.$targetId),and(sender_id.eq.$targetId,receiver_id.eq.${user.id})')
        .eq('status', 'pending')
        .maybeSingle();
    if (existing != null) {
      throw Exception('A pending friend request already exists.');
    }

    await _client.from('friend_requests').insert({
      'sender_id': user.id,
      'receiver_id': targetId,
      'status': 'pending',
    });
  }

  Future<List<FriendRequestItem>> fetchIncomingFriendRequests() async {
    final user = currentUser;
    if (user == null) return [];

    final rows = await _client
        .from('friend_requests')
        .select('id,sender_id,receiver_id,status,created_at')
        .eq('receiver_id', user.id)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    final data = (rows as List<dynamic>).cast<Map<String, dynamic>>();
    final senderIds =
        data.map((e) => e['sender_id'].toString()).toSet().toList();
    final profiles = await _loadProfiles(senderIds);

    return data.map((row) {
      final senderId = row['sender_id'].toString();
      return FriendRequestItem(
        id: row['id'].toString(),
        senderId: senderId,
        receiverId: row['receiver_id'].toString(),
        status: row['status'].toString(),
        createdAt: parseTimestamp(row['created_at']),
        counterpart: profiles[senderId] ??
            ProfilePreview(id: senderId, username: 'unknown', avatarUrl: null),
        isIncoming: true,
      );
    }).toList();
  }

  Future<List<FriendRequestItem>> fetchOutgoingFriendRequests() async {
    final user = currentUser;
    if (user == null) return [];

    final rows = await _client
        .from('friend_requests')
        .select('id,sender_id,receiver_id,status,created_at')
        .eq('sender_id', user.id)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    final data = (rows as List<dynamic>).cast<Map<String, dynamic>>();
    final receiverIds =
        data.map((e) => e['receiver_id'].toString()).toSet().toList();
    final profiles = await _loadProfiles(receiverIds);

    return data.map((row) {
      final receiverId = row['receiver_id'].toString();
      return FriendRequestItem(
        id: row['id'].toString(),
        senderId: row['sender_id'].toString(),
        receiverId: receiverId,
        status: row['status'].toString(),
        createdAt: parseTimestamp(row['created_at']),
        counterpart: profiles[receiverId] ??
            ProfilePreview(
              id: receiverId,
              username: 'unknown',
              avatarUrl: null,
            ),
        isIncoming: false,
      );
    }).toList();
  }

  Future<Map<String, ProfilePreview>> _loadProfiles(List<String> ids) async {
    if (ids.isEmpty) return {};
    final rows = await _client
        .from('profiles')
        .select('id,username,avatar_url')
        .inFilter('id', ids);

    final map = <String, ProfilePreview>{};
    for (final item in (rows as List<dynamic>).cast<Map<String, dynamic>>()) {
      final profile = ProfilePreview.fromMap(item);
      map[profile.id] = profile;
    }
    return map;
  }

  Future<void> respondToFriendRequest({
    required String requestId,
    required bool accept,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('You are not logged in.');
    }

    final request = await _client
        .from('friend_requests')
        .select('id,sender_id,receiver_id,status')
        .eq('id', requestId)
        .single();

    final senderId = request['sender_id'].toString();
    final receiverId = request['receiver_id'].toString();
    final status = request['status'].toString();

    if (receiverId != user.id || status != 'pending') {
      throw Exception('This request can no longer be updated.');
    }

    if (accept) {
      await _client
          .from('friend_requests')
          .update({'status': 'accepted'}).eq('id', requestId);
      final low = _pairLow(senderId, receiverId);
      final high = _pairHigh(senderId, receiverId);
      await _client.from('friendships').upsert({
        'user_low_id': low,
        'user_high_id': high,
      }, onConflict: 'user_low_id,user_high_id');
    } else {
      await _client
          .from('friend_requests')
          .update({'status': 'declined'}).eq('id', requestId);
    }
  }

  Future<List<FriendItem>> fetchFriends() async {
    final user = currentUser;
    if (user == null) return [];

    final rows = await _client
        .from('friendships')
        .select('id,user_low_id,user_high_id,created_at')
        .or('user_low_id.eq.${user.id},user_high_id.eq.${user.id}')
        .order('created_at', ascending: false);

    final data = (rows as List<dynamic>).cast<Map<String, dynamic>>();
    final friendIds = <String>{};
    for (final row in data) {
      final low = row['user_low_id'].toString();
      final high = row['user_high_id'].toString();
      friendIds.add(low == user.id ? high : low);
    }
    final profiles = await _loadProfiles(friendIds.toList());

    return data.map((row) {
      final low = row['user_low_id'].toString();
      final high = row['user_high_id'].toString();
      final friendId = low == user.id ? high : low;
      return FriendItem(
        friendshipId: row['id'].toString(),
        friend: profiles[friendId] ??
            ProfilePreview(id: friendId, username: 'unknown', avatarUrl: null),
        createdAt: parseTimestamp(row['created_at']),
      );
    }).toList();
  }

  Future<int> fetchIncomingRequestCount() async {
    final user = currentUser;
    if (user == null) return 0;
    final rows = await _client
        .from('friend_requests')
        .select('id')
        .eq('receiver_id', user.id)
        .eq('status', 'pending');
    return (rows as List<dynamic>).length;
  }

  Future<void> publishNoteToFriends(NoteItem note) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('You are not logged in.');
    }

    final friends = await fetchFriends();
    if (friends.isEmpty) {
      throw Exception('Add at least one friend before publishing notes.');
    }

    final rows = friends
        .map((friend) => {
              'note_id': note.id,
              'author_id': user.id,
              'recipient_id': friend.friend.id,
              'title': note.title,
              'content': note.content,
              'published_at': DateTime.now().toUtc().toIso8601String(),
            })
        .toList();

    await _client.from('shared_notes').upsert(
          rows,
          onConflict: 'note_id,author_id,recipient_id',
        );
  }

  Future<void> unpublishNoteFromFriends(String noteId) async {
    final user = currentUser;
    if (user == null) return;
    await _client
        .from('shared_notes')
        .delete()
        .eq('note_id', noteId)
        .eq('author_id', user.id);
  }

  Future<Set<String>> fetchPublishedNoteIdsForCurrentUser() async {
    final user = currentUser;
    if (user == null) return {};

    final rows = await _client
        .from('shared_notes')
        .select('note_id')
        .eq('author_id', user.id);

    return (rows as List<dynamic>)
        .map((row) => row['note_id'].toString())
        .toSet();
  }

  Future<List<SharedNoteFeedItem>> fetchFriendsFeed() async {
    final user = currentUser;
    if (user == null) return [];

    final rows = await _client
        .from('shared_notes')
        .select('id,note_id,author_id,title,content,published_at')
        .eq('recipient_id', user.id)
        .order('published_at', ascending: false)
        .limit(100);

    final items = (rows as List<dynamic>).cast<Map<String, dynamic>>();
    if (items.isEmpty) return [];

    final authorIds =
        items.map((e) => e['author_id'].toString()).toSet().toList();
    final profiles = await _loadProfiles(authorIds);
    final sharedIds = items.map((e) => e['id'].toString()).toList();

    final likesRows = await _client
        .from('shared_note_likes')
        .select('shared_note_id,user_id')
        .inFilter('shared_note_id', sharedIds);
    final commentsRows = await _client
        .from('shared_note_comments')
        .select('shared_note_id')
        .inFilter('shared_note_id', sharedIds);

    final likeCounts = <String, int>{};
    final commentCounts = <String, int>{};
    final likedByCurrentUser = <String>{};

    for (final row
        in (likesRows as List<dynamic>).cast<Map<String, dynamic>>()) {
      final sharedId = row['shared_note_id'].toString();
      likeCounts[sharedId] = (likeCounts[sharedId] ?? 0) + 1;
      if (row['user_id'].toString() == user.id) {
        likedByCurrentUser.add(sharedId);
      }
    }
    for (final row
        in (commentsRows as List<dynamic>).cast<Map<String, dynamic>>()) {
      final sharedId = row['shared_note_id'].toString();
      commentCounts[sharedId] = (commentCounts[sharedId] ?? 0) + 1;
    }

    return items.map((row) {
      final sharedId = row['id'].toString();
      final authorId = row['author_id'].toString();
      final author = profiles[authorId];
      return SharedNoteFeedItem(
        id: sharedId,
        noteId: row['note_id'].toString(),
        authorId: authorId,
        authorUsername: author?.username ?? 'unknown',
        authorAvatarUrl: author?.avatarUrl,
        title: (row['title'] ?? '').toString(),
        content: (row['content'] ?? '').toString(),
        publishedAt: parseTimestamp(row['published_at']),
        likeCount: likeCounts[sharedId] ?? 0,
        commentCount: commentCounts[sharedId] ?? 0,
        isLikedByCurrentUser: likedByCurrentUser.contains(sharedId),
      );
    }).toList();
  }

  Future<void> toggleFeedLike(String sharedNoteId) async {
    final user = currentUser;
    if (user == null) return;

    final existing = await _client
        .from('shared_note_likes')
        .select('shared_note_id,user_id')
        .eq('shared_note_id', sharedNoteId)
        .eq('user_id', user.id)
        .maybeSingle();

    if (existing == null) {
      await _client.from('shared_note_likes').insert({
        'shared_note_id': sharedNoteId,
        'user_id': user.id,
      });
    } else {
      await _client
          .from('shared_note_likes')
          .delete()
          .eq('shared_note_id', sharedNoteId)
          .eq('user_id', user.id);
    }
  }

  Future<List<FeedCommentItem>> fetchFeedComments(String sharedNoteId) async {
    final rows = await _client
        .from('shared_note_comments')
        .select('id,shared_note_id,user_id,content,created_at')
        .eq('shared_note_id', sharedNoteId)
        .order('created_at');

    final items = (rows as List<dynamic>).cast<Map<String, dynamic>>();
    final authorIds =
        items.map((e) => e['user_id'].toString()).toSet().toList();
    final profiles = await _loadProfiles(authorIds);

    return items.map((row) {
      final authorId = row['user_id'].toString();
      final author = profiles[authorId];
      return FeedCommentItem(
        id: row['id'].toString(),
        sharedNoteId: row['shared_note_id'].toString(),
        authorId: authorId,
        authorUsername: author?.username ?? 'unknown',
        authorAvatarUrl: author?.avatarUrl,
        content: (row['content'] ?? '').toString(),
        createdAt: parseTimestamp(row['created_at']),
      );
    }).toList();
  }

  Future<void> addFeedComment({
    required String sharedNoteId,
    required String content,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('You are not logged in.');
    }
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      throw Exception('Comment cannot be empty.');
    }
    if (trimmed.length > 500) {
      throw Exception('Comment is too long (max 500 characters).');
    }
    await _client.from('shared_note_comments').insert({
      'shared_note_id': sharedNoteId,
      'user_id': user.id,
      'content': trimmed,
    });
  }
}
