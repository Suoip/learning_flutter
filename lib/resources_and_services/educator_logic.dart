import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'educator_forum_posts_data_source.dart';
import 'educator_profile_data_source.dart';
import 'educator_videos_data_source.dart';
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
  })  : _explicitClient = client,
        _explicitEducatorVideosDataSource = educatorVideosDataSource,
        _explicitEducatorForumPostsDataSource = educatorForumPostsDataSource,
        _explicitEducatorProfileDataSource = educatorProfileDataSource;

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
}
