import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'friends_data_source.dart';
import 'notes_data_source.dart';
import 'profiles_data_source.dart';
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
  NotesLogic({
    SupabaseClient? client,
    NotesDataSource? notesDataSource,
    ProfilesDataSource? profilesDataSource,
    FriendsDataSource? friendsDataSource,
  })  : _explicitClient = client,
        _explicitNotesDataSource = notesDataSource,
        _explicitProfilesDataSource = profilesDataSource,
        _explicitFriendsDataSource = friendsDataSource;

  final SupabaseClient? _explicitClient;

  // Lazy: only resolves AppSupabase.client (which requires Supabase to be
  // initialized) the first time something actually needs it. Each data
  // source field below is lazy for the same reason and builds on this - a
  // test that injects one fake data source and never touches the others
  // never forces AppSupabase.client to resolve, even without an explicit
  // `client`, because the unused fields' `late` initializers never run.
  late final SupabaseClient _client = _explicitClient ?? AppSupabase.client;

  final NotesDataSource? _explicitNotesDataSource;
  late final NotesDataSource _notesDataSource =
      _explicitNotesDataSource ?? SupabaseNotesDataSource(_client);

  final ProfilesDataSource? _explicitProfilesDataSource;
  late final ProfilesDataSource _profilesDataSource =
      _explicitProfilesDataSource ?? SupabaseProfilesDataSource(_client);

  final FriendsDataSource? _explicitFriendsDataSource;
  late final FriendsDataSource _friendsDataSource =
      _explicitFriendsDataSource ?? SupabaseFriendsDataSource(_client);
  static const String activationRequiredMessage =
      'Please confirm your email to activate your account.';

  User? get currentUser => _client.auth.currentUser;

  static bool isUserEmailConfirmed(User? user) {
    if (user == null) return false;
    final confirmedAt = user.toJson()['email_confirmed_at'];
    return confirmedAt != null && confirmedAt.toString().trim().isNotEmpty;
  }

  static String formatUpdatedTime(DateTime dateTime) {
    return DateFormat('MMM d, h:mm a').format(dateTime.toLocal());
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
      // Checked before the message-based matches below: Supabase's own
      // wording for this ("New password should be different from the old
      // password.") contains "password" too and would otherwise be
      // misreported as a login failure. `code` is Supabase's own stable
      // error identifier for this condition - more robust than matching
      // on message text, which is just prose meant for logging.
      if (error.code == 'same_password') {
        return 'Your new password must be different from your current password.';
      }

      final message = error.message.toLowerCase();
      if (message.contains('invalid login') ||
          message.contains('invalid credentials') ||
          message.contains('invalid') ||
          message.contains('password')) {
        return 'Incorrect email or password. Please try again.';
      }
      if (message.contains('already') || message.contains('duplicate')) {
        if (message.contains('email')) {
          return 'That email is already registered.';
        }
        return 'That username is already taken.';
      }
      if (message.contains('confirm') || message.contains('not confirmed')) {
        return 'Your account needs email confirmation before login.';
      }
      if (message.contains('rate limit') || message.contains('too many')) {
        return 'Too many attempts. Please wait a moment and try again.';
      }
      if (message.contains('email address not authorized') ||
          message.contains('smtp') ||
          message.contains('email provider is disabled') ||
          message.contains('signups not allowed')) {
        return 'Registration email could not be sent. Please ask the app admin to finish Supabase email provider/SMTP setup.';
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

  static bool isValidEmail(String email) {
    final normalized = email.trim().toLowerCase();
    final pattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return pattern.hasMatch(normalized);
  }

  /// Derives a safe, lowercase file extension (without the dot) from a
  /// picked file's name, defaulting to "jpg" if none can be determined.
  ///
  /// Callers must pass the file's *name* (e.g. `XFile.name`), not its
  /// *path* - on web, `XFile.path` is a blob: URL rather than the original
  /// filename, so parsing an extension out of it picks up stray dots from
  /// the page origin instead of the real file extension.
  static String extensionFromFileName(String fileName) {
    final normalized = fileName.trim().toLowerCase();
    final dotIndex = normalized.lastIndexOf('.');
    final rawExtension =
        dotIndex > -1 ? normalized.substring(dotIndex + 1) : 'jpg';
    final extension = rawExtension.replaceAll(RegExp(r'[^a-z0-9]'), '');
    return extension.isEmpty ? 'jpg' : extension;
  }

  String _safeUsernameForUser(User user, {String? preferredUsername}) {
    final preferred = (preferredUsername ?? defaultUsernameForUser(user))
        .trim()
        .toLowerCase();

    if (isValidUsername(preferred)) return preferred;
    return 'user_${user.id.substring(0, 8)}';
  }

  Future<void> ensureProfileForCurrentUser({String? preferredUsername}) async {
    final user = _profilesDataSource.currentUser;
    if (user == null) return;

    final safeUsername = _safeUsernameForUser(
      user,
      preferredUsername: preferredUsername,
    );

    final existing = await _profilesDataSource.selectProfileById(user.id);

    if (existing != null) {
      final currentUsername =
          (existing['username'] ?? '').toString().trim().toLowerCase();
      if (currentUsername == safeUsername) return;

      await _profilesDataSource.updateProfileById(user.id, {
        'username': safeUsername,
      });
      return;
    }

    await _profilesDataSource.insertProfile({
      'id': user.id,
      'username': safeUsername,
      'avatar_url': null,
    });
  }

  Future<UserProfile> fetchCurrentProfile() async {
    final user = _profilesDataSource.currentUser;
    if (user == null) {
      throw Exception('You are not logged in.');
    }

    await ensureProfileForCurrentUser();

    final row = await _profilesDataSource.selectProfileById(user.id);
    if (row == null) {
      throw Exception('Profile not found.');
    }

    return UserProfile.fromMap(user: user, map: row);
  }

  Future<UserProfile> updateUsername(String username) async {
    final user = _profilesDataSource.currentUser;
    if (user == null) {
      throw Exception('You are not logged in.');
    }

    final normalized = username.trim().toLowerCase();
    if (!isValidUsername(normalized)) {
      throw Exception('Use 3-30 chars: letters, numbers, _, -, .');
    }

    try {
      await _client.auth.updateUser(
        UserAttributes(data: {'username': normalized}),
      );
    } on AuthException catch (error) {
      throw Exception(userMessageForError(error));
    }

    await _profilesDataSource.upsertProfile({
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
    final user = _profilesDataSource.currentUser;
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
    final publicUrl = await _profilesDataSource.uploadAvatarAndGetPublicUrl(
      objectPath: objectPath,
      bytes: bytes,
    );

    final timestamp = DateTime.now().toUtc().millisecondsSinceEpoch;
    final avatarUrl = '$publicUrl?v=$timestamp';

    // A plain update, not an upsert: the profile row is always created
    // before this screen is reachable (see ensureProfileForCurrentUser),
    // and upserting here without `username` fails, since Postgres
    // validates the hypothetical INSERT half of an upsert - including
    // NOT NULL columns not present in the payload - before it even checks
    // for a conflict to fall back to UPDATE.
    await _profilesDataSource.updateProfileById(user.id, {
      'avatar_url': avatarUrl,
    });

    return fetchCurrentProfile();
  }

  Future<List<NoteItem>> fetchNotesForCurrentUser() async {
    final userId = _notesDataSource.currentUserId;
    if (userId == null) return [];

    final rows = await _notesDataSource.selectNotes(userId: userId);
    final notes = rows.map((row) => NoteItem.fromMap(row)).toList();

    return sortNotes(notes);
  }

  static List<NoteItem> filterNotes({
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
    final userId = _notesDataSource.currentUserId;
    if (userId == null) {
      throw Exception('You are not logged in.');
    }

    final inserted = await _notesDataSource.insertNote({
      'user_id': userId,
      'title': title.trim(),
      'content': '',
      'is_pinned': false,
      'is_favorite': false,
    });

    return NoteItem.fromMap(inserted);
  }

  Future<void> updateNote({
    required String noteId,
    required String title,
    required String content,
  }) async {
    await _notesDataSource.updateNoteById(noteId, {
      'title': title,
      'content': content,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> togglePin(NoteItem note) async {
    await _notesDataSource.updateNoteById(note.id, {
      'is_pinned': !note.isPinned,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> toggleFavorite(NoteItem note) async {
    await _notesDataSource.updateNoteById(note.id, {
      'is_favorite': !note.isFavorite,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> deleteNote(String noteId) async {
    await _notesDataSource.deleteNoteById(noteId);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> resendSignupConfirmationEmail({
    required String email,
  }) async {
    final normalized = email.trim().toLowerCase();
    if (!isValidEmail(normalized)) {
      throw Exception('Enter a valid email address.');
    }

    try {
      await _client.auth.resend(
        type: OtpType.signup,
        email: normalized,
        emailRedirectTo: AppSupabase.emailRedirectTo,
      );
    } on AuthException catch (error) {
      throw Exception(userMessageForError(error));
    }
  }

  /// Sends a password-reset email. Like Supabase's signup flow, this never
  /// reveals whether the email actually has an account - it succeeds
  /// regardless, so the UI should show a neutral message either way.
  Future<void> sendPasswordResetEmail({required String email}) async {
    final normalized = email.trim().toLowerCase();
    if (!isValidEmail(normalized)) {
      throw Exception('Enter a valid email address.');
    }

    try {
      await _client.auth.resetPasswordForEmail(
        normalized,
        redirectTo: AppSupabase.emailRedirectTo,
      );
    } on AuthException catch (error) {
      throw Exception(userMessageForError(error));
    }
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final normalized = email.trim().toLowerCase();
    if (!isValidEmail(normalized)) {
      throw Exception('Enter a valid email address.');
    }

    try {
      final response = await _client.auth.signInWithPassword(
        email: normalized,
        password: password,
      );
      final signedInUser = response.user ?? currentUser;
      if (!isUserEmailConfirmed(signedInUser)) {
        await _client.auth.signOut();
        throw Exception(activationRequiredMessage);
      }
    } on AuthException catch (error) {
      throw Exception(userMessageForError(error));
    }
  }

  Future<bool> signUpWithUsername({
    required String username,
    required String email,
    required String password,
  }) async {
    final normalized = username.trim().toLowerCase();
    final normalizedEmail = email.trim().toLowerCase();

    if (!isValidUsername(normalized)) {
      throw Exception('Use 3-30 chars: letters, numbers, _, -, .');
    }
    if (!isValidEmail(normalizedEmail)) {
      throw Exception('Enter a valid email address.');
    }

    try {
      final response = await _client.auth.signUp(
        email: normalizedEmail,
        password: password,
        data: {'username': normalized},
        emailRedirectTo: AppSupabase.emailRedirectTo,
      );

      // Supabase deliberately obscures whether an email is already
      // registered, to prevent account-enumeration attacks: for an
      // existing, already-confirmed account it returns a user with an
      // empty `identities` list and no session, rather than an error.
      // This is the documented way to detect that case client-side -
      // without it, this would silently fall through to the "check your
      // email to confirm" path below even though no account was created
      // and no email was sent.
      if (response.user?.identities?.isEmpty ?? false) {
        throw Exception(
          'That email is already registered. Try logging in, or use '
          '"Forgot password" if you don\'t remember your password.',
        );
      }

      final signedUpUser = response.user ?? currentUser;
      if (!isUserEmailConfirmed(signedUpUser)) {
        if (response.session != null || currentUser != null) {
          await _client.auth.signOut();
        }
        return false;
      }

      if (response.session != null || currentUser != null) {
        await ensureProfileForCurrentUser(preferredUsername: normalized);
        return true;
      }

      return false;
    } on AuthException catch (error) {
      throw Exception(userMessageForError(error));
    }
  }

  static List<NoteItem> sortNotes(List<NoteItem> notes) {
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
    final user = _profilesDataSource.currentUser;
    if (user == null) return [];

    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return [];

    final rows = await _profilesDataSource.searchProfilesByUsername(
      query: normalized,
      excludeUserId: user.id,
    );

    return rows.map((row) => ProfilePreview.fromMap(row)).toList();
  }

  Future<bool> _areFriends(String userA, String userB) async {
    final low = _pairLow(userA, userB);
    final high = _pairHigh(userA, userB);
    final row = await _friendsDataSource.selectFriendshipByPair(
      lowId: low,
      highId: high,
    );
    return row != null;
  }

  Future<void> sendFriendRequestByUsername(String username) async {
    final userId = _friendsDataSource.currentUserId;
    if (userId == null) {
      throw Exception('You are not logged in.');
    }

    final normalized = username.trim().toLowerCase();
    if (!isValidUsername(normalized)) {
      throw Exception('Enter a valid username.');
    }

    final target = await _profilesDataSource.selectProfileByUsername(
      normalized,
    );
    if (target == null) {
      throw Exception('No user found with that username.');
    }

    final targetId = target['id'].toString();
    if (targetId == userId) {
      throw Exception('You cannot send a friend request to yourself.');
    }

    if (await _areFriends(userId, targetId)) {
      throw Exception('You are already friends.');
    }

    final existing = await _friendsDataSource.selectPendingRequestBetween(
      userA: userId,
      userB: targetId,
    );
    if (existing != null) {
      throw Exception('A pending friend request already exists.');
    }

    await _friendsDataSource.insertFriendRequest({
      'sender_id': userId,
      'receiver_id': targetId,
      'status': 'pending',
    });
  }

  Future<List<FriendRequestItem>> fetchIncomingFriendRequests() async {
    final userId = _friendsDataSource.currentUserId;
    if (userId == null) return [];

    final data = await _friendsDataSource.selectPendingRequestsForReceiver(
      userId,
    );
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
    final userId = _friendsDataSource.currentUserId;
    if (userId == null) return [];

    final data = await _friendsDataSource.selectPendingRequestsForSender(
      userId,
    );
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
    final rows = await _profilesDataSource.selectProfilesByIds(ids);

    final map = <String, ProfilePreview>{};
    for (final item in rows) {
      final profile = ProfilePreview.fromMap(item);
      map[profile.id] = profile;
    }
    return map;
  }

  Future<void> respondToFriendRequest({
    required String requestId,
    required bool accept,
  }) async {
    final userId = _friendsDataSource.currentUserId;
    if (userId == null) {
      throw Exception('You are not logged in.');
    }

    final request = await _friendsDataSource.selectFriendRequestById(
      requestId,
    );
    if (request == null) {
      throw Exception('This request can no longer be updated.');
    }

    final senderId = request['sender_id'].toString();
    final receiverId = request['receiver_id'].toString();
    final status = request['status'].toString();

    if (receiverId != userId || status != 'pending') {
      throw Exception('This request can no longer be updated.');
    }

    if (accept) {
      await _friendsDataSource.updateFriendRequestStatus(
        requestId,
        'accepted',
      );
      final low = _pairLow(senderId, receiverId);
      final high = _pairHigh(senderId, receiverId);
      await _friendsDataSource.upsertFriendship(lowId: low, highId: high);
    } else {
      await _friendsDataSource.updateFriendRequestStatus(
        requestId,
        'declined',
      );
    }
  }

  Future<void> cancelFriendRequest(String requestId) async {
    final userId = _friendsDataSource.currentUserId;
    if (userId == null) {
      throw Exception('You are not logged in.');
    }

    final request = await _friendsDataSource.selectFriendRequestById(
      requestId,
    );
    if (request == null) {
      throw Exception('This request can no longer be cancelled.');
    }

    final senderId = request['sender_id'].toString();
    final status = request['status'].toString();

    if (senderId != userId || status != 'pending') {
      throw Exception('This request can no longer be cancelled.');
    }

    await _friendsDataSource.updateFriendRequestStatus(
      requestId,
      'cancelled',
    );
  }

  Future<List<FriendItem>> fetchFriends() async {
    final userId = _friendsDataSource.currentUserId;
    if (userId == null) return [];

    final data = await _friendsDataSource.selectFriendshipsForUser(userId);
    final friendIds = <String>{};
    for (final row in data) {
      final low = row['user_low_id'].toString();
      final high = row['user_high_id'].toString();
      friendIds.add(low == userId ? high : low);
    }
    final profiles = await _loadProfiles(friendIds.toList());

    return data.map((row) {
      final low = row['user_low_id'].toString();
      final high = row['user_high_id'].toString();
      final friendId = low == userId ? high : low;
      return FriendItem(
        friendshipId: row['id'].toString(),
        friend: profiles[friendId] ??
            ProfilePreview(id: friendId, username: 'unknown', avatarUrl: null),
        createdAt: parseTimestamp(row['created_at']),
      );
    }).toList();
  }

  Future<void> removeFriend(String friendshipId) async {
    final userId = _friendsDataSource.currentUserId;
    if (userId == null) {
      throw Exception('You are not logged in.');
    }
    await _friendsDataSource.deleteFriendshipById(friendshipId);
  }

  Future<int> fetchIncomingRequestCount() async {
    final userId = _friendsDataSource.currentUserId;
    if (userId == null) return 0;
    return _friendsDataSource.countPendingRequestsForReceiver(userId);
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
