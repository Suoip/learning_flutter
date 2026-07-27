import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'educator_forum_engagement_data_source.dart';
import 'educator_forum_posts_data_source.dart';
import 'educator_profile_data_source.dart';
import 'educator_videos_data_source.dart';
import 'profiles_data_source.dart';
import 'supabase_auth_response_helpers.dart' as auth_response;
import 'supabase_client.dart';

/// A single educator-authored video entry - title, description, and a
/// free-text duration placeholder like "12:34". Metadata only; no real
/// video file upload exists or is planned yet.
class EducatorVideoItem {
  const EducatorVideoItem({
    required this.id,
    required this.title,
    required this.description,
    required this.durationLabel,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final String? durationLabel;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory EducatorVideoItem.fromMap(Map<String, dynamic> map) {
    final createdValue = map['created_at'];
    final createdAt = createdValue == null
        ? DateTime.now().toUtc()
        : DateTime.parse(createdValue.toString()).toUtc();

    final updatedValue = map['updated_at'] ?? map['created_at'];
    final updatedAt = updatedValue == null
        ? createdAt
        : DateTime.parse(updatedValue.toString()).toUtc();

    final rawDuration = (map['duration_label'] as String?)?.trim();

    return EducatorVideoItem(
      id: map['id'].toString(),
      title: (map['title'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      durationLabel:
          (rawDuration == null || rawDuration.isEmpty) ? null : rawDuration,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// A single educator-authored forum post - title and body text only, no
/// video.
class ForumPostItem {
  const ForumPostItem({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ForumPostItem.fromMap(Map<String, dynamic> map) {
    final createdValue = map['created_at'];
    final createdAt = createdValue == null
        ? DateTime.now().toUtc()
        : DateTime.parse(createdValue.toString()).toUtc();

    final updatedValue = map['updated_at'] ?? map['created_at'];
    final updatedAt = updatedValue == null
        ? createdAt
        : DateTime.parse(updatedValue.toString()).toUtc();

    return ForumPostItem(
      id: map['id'].toString(),
      title: (map['title'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// A [ForumPostItem] plus its like/comment engagement - no author fields
/// needed, since a forum post's own author is always the educator whose
/// channel/dashboard it's being viewed from.
class ForumPostWithEngagement {
  const ForumPostWithEngagement({
    required this.post,
    required this.likeCount,
    required this.commentCount,
    required this.isLikedByCurrentUser,
  });

  final ForumPostItem post;
  final int likeCount;
  final int commentCount;
  final bool isLikedByCurrentUser;
}

/// A single comment on a forum post. Unlike a forum post's own author
/// (always an educator), a comment's author could be either account type -
/// any signed-in account can comment - so both username/avatar are
/// resolved at read time rather than assumed to come from `educators`.
class ForumPostCommentItem {
  const ForumPostCommentItem({
    required this.id,
    required this.forumPostId,
    required this.authorId,
    required this.authorUsername,
    required this.authorAvatarUrl,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String forumPostId;
  final String authorId;
  final String authorUsername;
  final String? authorAvatarUrl;
  final String content;
  final DateTime createdAt;
}

/// An educator's own profile: username + optional avatar. Mirrors
/// `UserProfile` in notes_logic.dart.
class EducatorProfile {
  const EducatorProfile({
    required this.id,
    required this.username,
    required this.avatarUrl,
  });

  final String id;
  final String username;
  final String? avatarUrl;

  factory EducatorProfile.fromMap({
    required User user,
    required Map<String, dynamic> map,
  }) {
    final usernameFromRow =
        (map['username'] ?? '').toString().trim().toLowerCase();

    return EducatorProfile(
      id: user.id,
      username: usernameFromRow.isEmpty
          ? EducatorLogic.defaultUsernameForUser(user)
          : usernameFromRow,
      avatarUrl: (map['avatar_url'] as String?)?.trim(),
    );
  }
}

/// Auth + video-content CRUD for SmartAcademy's educator accounts.
/// Deliberately independent of NotesLogic/the `profiles` table: educators
/// live in their own `public.educators` table, tagged apart from Notes
/// signups at the database trigger level via an `app` metadata field set
/// below. Shares only the small, generic Supabase-response-interpretation
/// helpers with Notes (see supabase_auth_response_helpers.dart), since those
/// don't reference either feature's own tables.
class EducatorLogic {
  EducatorLogic({
    SupabaseClient? client,
    EducatorVideosDataSource? educatorVideosDataSource,
    EducatorForumPostsDataSource? educatorForumPostsDataSource,
    EducatorProfileDataSource? educatorProfileDataSource,
    EducatorForumEngagementDataSource? educatorForumEngagementDataSource,
    ProfilesDataSource? profilesDataSource,
  })  : _explicitClient = client,
        _explicitEducatorVideosDataSource = educatorVideosDataSource,
        _explicitEducatorForumPostsDataSource = educatorForumPostsDataSource,
        _explicitEducatorProfileDataSource = educatorProfileDataSource,
        _explicitEducatorForumEngagementDataSource =
            educatorForumEngagementDataSource,
        _explicitProfilesDataSource = profilesDataSource;

  final SupabaseClient? _explicitClient;
  late final SupabaseClient _client = _explicitClient ?? AppSupabase.client;

  final EducatorVideosDataSource? _explicitEducatorVideosDataSource;
  late final EducatorVideosDataSource _educatorVideosDataSource =
      _explicitEducatorVideosDataSource ??
          SupabaseEducatorVideosDataSource(_client);

  final EducatorForumPostsDataSource? _explicitEducatorForumPostsDataSource;
  late final EducatorForumPostsDataSource _educatorForumPostsDataSource =
      _explicitEducatorForumPostsDataSource ??
          SupabaseEducatorForumPostsDataSource(_client);

  final EducatorProfileDataSource? _explicitEducatorProfileDataSource;
  late final EducatorProfileDataSource _educatorProfileDataSource =
      _explicitEducatorProfileDataSource ??
          SupabaseEducatorProfileDataSource(_client);

  final EducatorForumEngagementDataSource?
      _explicitEducatorForumEngagementDataSource;
  late final EducatorForumEngagementDataSource
      _educatorForumEngagementDataSource =
      _explicitEducatorForumEngagementDataSource ??
          SupabaseEducatorForumEngagementDataSource(_client);

  /// Used only to resolve a forum-post commenter's identity when they're
  /// not found in `educators` - a comment's author could be either a Notes
  /// user or an educator, since either account type is eligible to
  /// comment/like. A data-access-class dependency, not a `NotesLogic`
  /// dependency - matches this file's existing precedent of sharing generic
  /// helpers (see supabase_auth_response_helpers.dart) without coupling the
  /// two features' business logic.
  final ProfilesDataSource? _explicitProfilesDataSource;
  late final ProfilesDataSource _profilesDataSource =
      _explicitProfilesDataSource ?? SupabaseProfilesDataSource(_client);

  static const String activationRequiredMessage =
      'Please confirm your email to activate your educator account.';

  static const String notAnEducatorMessage =
      "This account isn't registered as an educator. Please sign out and "
      'register a new educator account to continue.';

  User? get currentUser => _client.auth.currentUser;

  static bool isUserEmailConfirmed(User? user) =>
      auth_response.isUserEmailConfirmed(user);

  /// Whether the current session actually has a `public.educators` row -
  /// deliberately a plain existence check, not [ensureEducatorForCurrentUser]
  /// (which would auto-create the row and silently defeat the point of this
  /// check). Used to proactively gate the educator dashboard for sessions
  /// that authenticated (e.g. via the shared-email-collision sign-in path)
  /// but were never actually registered as an educator.
  Future<bool> hasEducatorAccount() async {
    final user = _educatorProfileDataSource.currentUser;
    if (user == null) return false;

    final existing = await _educatorProfileDataSource.selectEducatorById(
      user.id,
    );
    return existing != null;
  }

  /// Looks up any educator by username - a plain public lookup, not scoped
  /// to the current session. Returns null (never throws) when the input is
  /// blank/invalid or no educator matches - this is a user-facing
  /// "not found" case for a search box, not an error.
  Future<EducatorProfile?> findEducatorByUsername(String username) async {
    final normalized = username.trim().toLowerCase();
    if (!isValidUsername(normalized)) return null;

    final row = await _educatorProfileDataSource.selectEducatorByUsername(
      normalized,
    );
    if (row == null) return null;

    return EducatorProfile(
      id: (row['id'] ?? '').toString(),
      username: (row['username'] ?? '').toString().trim().toLowerCase(),
      avatarUrl: (row['avatar_url'] as String?)?.trim(),
    );
  }

  /// Fetches any educator's public profile by id - an internal loader for
  /// the channel page, which only ever calls this with an id it already
  /// trusts to exist. Throws if no such educator is found.
  Future<EducatorProfile> fetchEducatorProfileById(String educatorId) async {
    final row = await _educatorProfileDataSource.selectEducatorById(
      educatorId,
    );
    if (row == null) {
      throw Exception('Educator not found.');
    }

    return EducatorProfile(
      id: educatorId,
      username: (row['username'] ?? '').toString().trim().toLowerCase(),
      avatarUrl: (row['avatar_url'] as String?)?.trim(),
    );
  }

  static bool shouldRejectSignIn({
    required AuthResponse response,
    required User? currentUser,
  }) =>
      auth_response.shouldRejectSignIn(
        response: response,
        currentUser: currentUser,
      );

  static auth_response.SignUpDecision interpretSignUpResponse({
    required AuthResponse response,
    required User? currentUser,
  }) =>
      auth_response.interpretSignUpResponse(
        response: response,
        currentUser: currentUser,
      );

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

  static String defaultUsernameForUser(User user) {
    final metadataUsername =
        (user.userMetadata?['username'] ?? '').toString().trim();
    if (metadataUsername.isNotEmpty) return metadataUsername.toLowerCase();

    final email = user.email ?? '';
    final splitIndex = email.indexOf('@');
    if (splitIndex <= 0) return 'educator';
    return email.substring(0, splitIndex).trim().toLowerCase();
  }

  static String userMessageForError(
    Object error, {
    String fallback = 'Something went wrong. Please try again.',
  }) {
    if (error is AuthException) {
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
      if (error.code == '23503') {
        return 'Your account is not registered as an educator yet. Try '
            'signing out and registering with a different email.';
      }
      return fallback;
    }

    final plain = error.toString().replaceFirst('Exception: ', '').trim();
    if (plain.isEmpty) return fallback;
    if (plain.contains('AuthApiException(') ||
        plain.contains('AuthException(')) {
      return 'Authentication failed. Please try again.';
    }
    return plain;
  }

  String _safeUsernameForUser(User user, {String? preferredUsername}) {
    final preferred = (preferredUsername ?? defaultUsernameForUser(user))
        .trim()
        .toLowerCase();
    if (isValidUsername(preferred)) return preferred;
    return 'educator_${user.id.substring(0, 8)}';
  }

  Future<void> ensureEducatorForCurrentUser({String? preferredUsername}) async {
    final user = _educatorProfileDataSource.currentUser;
    if (user == null) return;

    final safeUsername = _safeUsernameForUser(
      user,
      preferredUsername: preferredUsername,
    );

    final existing =
        await _educatorProfileDataSource.selectEducatorById(user.id);

    if (existing != null) {
      final currentUsername =
          (existing['username'] ?? '').toString().trim().toLowerCase();
      if (currentUsername == safeUsername) return;

      await _educatorProfileDataSource.updateEducatorById(user.id, {
        'username': safeUsername,
      });
      return;
    }

    await _educatorProfileDataSource.insertEducator({
      'id': user.id,
      'username': safeUsername,
      'avatar_url': null,
    });
  }

  Future<EducatorProfile> fetchCurrentEducatorProfile() async {
    final user = _educatorProfileDataSource.currentUser;
    if (user == null) {
      throw Exception('You are not logged in.');
    }

    await ensureEducatorForCurrentUser();

    final row = await _educatorProfileDataSource.selectEducatorById(user.id);
    if (row == null) {
      throw Exception('Profile not found.');
    }

    return EducatorProfile.fromMap(user: user, map: row);
  }

  Future<EducatorProfile> updateUsername(String username) async {
    final user = _educatorProfileDataSource.currentUser;
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

    await _educatorProfileDataSource.upsertEducator({
      'id': user.id,
      'username': normalized,
    }, onConflict: 'id');

    return fetchCurrentEducatorProfile();
  }

  static String extensionFromFileName(String fileName) {
    final normalized = fileName.trim().toLowerCase();
    final dotIndex = normalized.lastIndexOf('.');
    final rawExtension =
        dotIndex > -1 ? normalized.substring(dotIndex + 1) : 'jpg';
    final extension = rawExtension.replaceAll(RegExp(r'[^a-z0-9]'), '');
    return extension.isEmpty ? 'jpg' : extension;
  }

  Future<EducatorProfile> uploadEducatorAvatar({
    required Uint8List bytes,
    required String extension,
  }) async {
    final user = _educatorProfileDataSource.currentUser;
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
    final publicUrl =
        await _educatorProfileDataSource.uploadAvatarAndGetPublicUrl(
      objectPath: objectPath,
      bytes: bytes,
    );

    final timestamp = DateTime.now().toUtc().millisecondsSinceEpoch;
    final avatarUrl = '$publicUrl?v=$timestamp';

    // A plain update, not an upsert: the educator row is always created
    // before this screen is reachable (see ensureEducatorForCurrentUser),
    // and upserting here without `username` fails, since Postgres
    // validates the hypothetical INSERT half of an upsert - including
    // NOT NULL columns not present in the payload - before it even checks
    // for a conflict to fall back to UPDATE.
    await _educatorProfileDataSource.updateEducatorById(user.id, {
      'avatar_url': avatarUrl,
    });

    return fetchCurrentEducatorProfile();
  }

  Future<void> signOut() async => _client.auth.signOut();

  Future<void> resendSignupConfirmationEmail({required String email}) async {
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

  /// Like Notes: never reveals whether the email actually has an account.
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
      if (shouldRejectSignIn(response: response, currentUser: currentUser)) {
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
        data: {'username': normalized, 'app': 'smart_academy'},
        emailRedirectTo: AppSupabase.emailRedirectTo,
      );

      final decision = interpretSignUpResponse(
        response: response,
        currentUser: currentUser,
      );

      if (decision.alreadyRegistered) {
        throw Exception(
          'That email is already registered. Try logging in, or use '
          '"Forgot password" if you don\'t remember your password.',
        );
      }

      if (decision.shouldSignOut) {
        await _client.auth.signOut();
      }

      if (decision.completed) {
        await ensureEducatorForCurrentUser(preferredUsername: normalized);
        return true;
      }

      return false;
    } on AuthException catch (error) {
      throw Exception(userMessageForError(error));
    }
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

  static String formatUpdatedTime(DateTime dateTime) {
    return DateFormat('MMM d, h:mm a').format(dateTime.toLocal());
  }

  static List<EducatorVideoItem> _sortVideosNewestFirst(
    List<EducatorVideoItem> videos,
  ) {
    final sorted = [...videos];
    sorted.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sorted;
  }

  Future<List<EducatorVideoItem>> fetchVideosForCurrentEducator() async {
    final educatorId = _educatorVideosDataSource.currentUserId;
    if (educatorId == null) return [];

    return fetchVideosForEducator(educatorId);
  }

  /// Fetches any educator's videos by id - used by the public channel page.
  Future<List<EducatorVideoItem>> fetchVideosForEducator(
    String educatorId,
  ) async {
    final rows = await _educatorVideosDataSource.selectVideos(
      educatorId: educatorId,
    );
    final videos = rows.map((row) => EducatorVideoItem.fromMap(row)).toList();

    return _sortVideosNewestFirst(videos);
  }

  Future<EducatorVideoItem> createVideo({
    required String title,
    required String description,
    String? durationLabel,
  }) async {
    final educatorId = _educatorVideosDataSource.currentUserId;
    if (educatorId == null) {
      throw Exception('You are not logged in.');
    }

    final normalizedDuration = durationLabel?.trim();
    final inserted = await _educatorVideosDataSource.insertVideo({
      'educator_id': educatorId,
      'title': title.trim(),
      'description': description.trim(),
      'duration_label':
          (normalizedDuration == null || normalizedDuration.isEmpty)
              ? null
              : normalizedDuration,
    });

    return EducatorVideoItem.fromMap(inserted);
  }

  Future<void> updateVideo({
    required String videoId,
    required String title,
    required String description,
    String? durationLabel,
  }) async {
    final normalizedDuration = durationLabel?.trim();
    await _educatorVideosDataSource.updateVideoById(videoId, {
      'title': title.trim(),
      'description': description.trim(),
      'duration_label':
          (normalizedDuration == null || normalizedDuration.isEmpty)
              ? null
              : normalizedDuration,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> deleteVideo(String videoId) async {
    await _educatorVideosDataSource.deleteVideoById(videoId);
  }

  static List<ForumPostItem> _sortForumPostsNewestFirst(
    List<ForumPostItem> posts,
  ) {
    final sorted = [...posts];
    sorted.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sorted;
  }

  Future<List<ForumPostItem>> fetchForumPostsForCurrentEducator() async {
    final educatorId = _educatorForumPostsDataSource.currentUserId;
    if (educatorId == null) return [];

    return fetchForumPostsForEducator(educatorId);
  }

  /// Fetches any educator's forum posts by id - used by the public channel
  /// page.
  Future<List<ForumPostItem>> fetchForumPostsForEducator(
    String educatorId,
  ) async {
    final rows = await _educatorForumPostsDataSource.selectForumPosts(
      educatorId: educatorId,
    );
    final posts = rows.map((row) => ForumPostItem.fromMap(row)).toList();

    return _sortForumPostsNewestFirst(posts);
  }

  Future<ForumPostItem> createForumPost({
    required String title,
    required String description,
  }) async {
    final educatorId = _educatorForumPostsDataSource.currentUserId;
    if (educatorId == null) {
      throw Exception('You are not logged in.');
    }

    final inserted = await _educatorForumPostsDataSource.insertForumPost({
      'educator_id': educatorId,
      'title': title.trim(),
      'description': description.trim(),
    });

    return ForumPostItem.fromMap(inserted);
  }

  Future<void> updateForumPost({
    required String postId,
    required String title,
    required String description,
  }) async {
    await _educatorForumPostsDataSource.updateForumPostById(postId, {
      'title': title.trim(),
      'description': description.trim(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> deleteForumPost(String postId) async {
    await _educatorForumPostsDataSource.deleteForumPostById(postId);
  }

  /// Fetches an educator's forum posts along with their like/comment
  /// engagement. `currentUserId` (nullable) is only used to compute
  /// [ForumPostWithEngagement.isLikedByCurrentUser] - it must never gate the
  /// fetch itself, since the public channel page calls this while fully
  /// signed out.
  Future<List<ForumPostWithEngagement>>
      fetchForumPostsWithEngagementForEducator(
    String educatorId,
  ) async {
    final posts = await fetchForumPostsForEducator(educatorId);
    if (posts.isEmpty) return [];

    final ids = posts.map((post) => post.id).toList();
    final currentUserId = _educatorForumEngagementDataSource.currentUserId;

    final likesRows =
        await _educatorForumEngagementDataSource.selectLikesForForumPostIds(
      ids,
    );
    final commentCountRows = await _educatorForumEngagementDataSource
        .selectCommentCountRowsForForumPostIds(ids);

    final likeCounts = <String, int>{};
    final likedByCurrentUser = <String>{};
    for (final row in likesRows) {
      final postId = row['forum_post_id'].toString();
      likeCounts[postId] = (likeCounts[postId] ?? 0) + 1;
      if (currentUserId != null && row['user_id'].toString() == currentUserId) {
        likedByCurrentUser.add(postId);
      }
    }

    final commentCounts = <String, int>{};
    for (final row in commentCountRows) {
      final postId = row['forum_post_id'].toString();
      commentCounts[postId] = (commentCounts[postId] ?? 0) + 1;
    }

    return posts.map((post) {
      return ForumPostWithEngagement(
        post: post,
        likeCount: likeCounts[post.id] ?? 0,
        commentCount: commentCounts[post.id] ?? 0,
        isLikedByCurrentUser: likedByCurrentUser.contains(post.id),
      );
    }).toList();
  }

  /// Throws when signed out (unlike `NotesLogic.toggleFeedLike`'s silent
  /// no-op) - a signed-out visitor reaching this is a real, expected case
  /// on the public channel page, not dead code, so the UI needs a real
  /// signal to show a "sign in to like" message instead.
  Future<void> toggleForumPostLike(String forumPostId) async {
    final userId = _educatorForumEngagementDataSource.currentUserId;
    if (userId == null) {
      throw Exception('You are not logged in.');
    }

    final existing = await _educatorForumEngagementDataSource.selectLike(
      forumPostId: forumPostId,
      userId: userId,
    );

    if (existing == null) {
      await _educatorForumEngagementDataSource.insertLike(
        forumPostId: forumPostId,
        userId: userId,
      );
    } else {
      await _educatorForumEngagementDataSource.deleteLike(
        forumPostId: forumPostId,
        userId: userId,
      );
    }
  }

  /// Resolves a batch of user ids to display identity, checking `educators`
  /// first (already fully public) then falling back to `profiles` for ids
  /// not found there. The two id sets are provably disjoint - one shared
  /// `auth.users` pool, one trigger branch per signup - so this ordering
  /// only affects efficiency, never correctness.
  Future<Map<String, ({String username, String? avatarUrl})>>
      _resolveCommentAuthors(List<String> ids) async {
    if (ids.isEmpty) return {};

    final resolved = <String, ({String username, String? avatarUrl})>{};

    final educatorRows =
        await _educatorProfileDataSource.selectEducatorsByIds(ids);
    for (final row in educatorRows) {
      resolved[(row['id'] ?? '').toString()] = (
        username: (row['username'] ?? '').toString().trim().toLowerCase(),
        avatarUrl: (row['avatar_url'] as String?)?.trim(),
      );
    }

    final remainingIds = ids.where((id) => !resolved.containsKey(id)).toList();
    if (remainingIds.isNotEmpty) {
      final profileRows =
          await _profilesDataSource.selectProfilesByIds(remainingIds);
      for (final row in profileRows) {
        resolved[(row['id'] ?? '').toString()] = (
          username: (row['username'] ?? '').toString().trim().toLowerCase(),
          avatarUrl: (row['avatar_url'] as String?)?.trim(),
        );
      }
    }

    return resolved;
  }

  Future<List<ForumPostCommentItem>> fetchForumPostComments(
    String forumPostId,
  ) async {
    final rows = await _educatorForumEngagementDataSource
        .selectCommentsForForumPost(forumPostId);
    final authorIds =
        rows.map((row) => row['user_id'].toString()).toSet().toList();
    final authors = await _resolveCommentAuthors(authorIds);

    return rows.map((row) {
      final authorId = row['user_id'].toString();
      final author = authors[authorId];
      final createdValue = row['created_at'];
      return ForumPostCommentItem(
        id: row['id'].toString(),
        forumPostId: row['forum_post_id'].toString(),
        authorId: authorId,
        authorUsername: author?.username ?? 'unknown',
        authorAvatarUrl: author?.avatarUrl,
        content: (row['content'] ?? '').toString(),
        createdAt: createdValue == null
            ? DateTime.now().toUtc()
            : DateTime.parse(createdValue.toString()).toUtc(),
      );
    }).toList();
  }

  Future<void> addForumPostComment({
    required String forumPostId,
    required String content,
  }) async {
    final userId = _educatorForumEngagementDataSource.currentUserId;
    if (userId == null) {
      throw Exception('You are not logged in.');
    }
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      throw Exception('Comment cannot be empty.');
    }
    if (trimmed.length > 500) {
      throw Exception('Comment is too long (max 500 characters).');
    }
    await _educatorForumEngagementDataSource.insertComment({
      'forum_post_id': forumPostId,
      'user_id': userId,
      'content': trimmed,
    });
  }
}
