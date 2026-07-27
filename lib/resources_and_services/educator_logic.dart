import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_auth_response_helpers.dart' as auth_response;
import 'supabase_client.dart';

/// Auth for SmartAcademy's educator accounts - register, login, forgot
/// password. Deliberately independent of NotesLogic/the `profiles` table:
/// educators live in their own `public.educators` table, tagged apart from
/// Notes signups at the database trigger level via an `app` metadata field
/// set below. Shares only the small, generic Supabase-response-interpretation
/// helpers with Notes (see supabase_auth_response_helpers.dart), since those
/// don't reference either feature's own tables.
class EducatorLogic {
  EducatorLogic({SupabaseClient? client}) : _explicitClient = client;

  final SupabaseClient? _explicitClient;
  late final SupabaseClient _client = _explicitClient ?? AppSupabase.client;

  static const String activationRequiredMessage =
      'Please confirm your email to activate your educator account.';

  User? get currentUser => _client.auth.currentUser;

  static bool isUserEmailConfirmed(User? user) =>
      auth_response.isUserEmailConfirmed(user);

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
    final user = _client.auth.currentUser;
    if (user == null) return;

    final safeUsername = _safeUsernameForUser(
      user,
      preferredUsername: preferredUsername,
    );

    final existing = await _client
        .from('educators')
        .select('id,username')
        .eq('id', user.id)
        .maybeSingle();

    if (existing != null) {
      final currentUsername =
          (existing['username'] ?? '').toString().trim().toLowerCase();
      if (currentUsername == safeUsername) return;

      await _client
          .from('educators')
          .update({'username': safeUsername}).eq('id', user.id);
      return;
    }

    await _client.from('educators').insert({
      'id': user.id,
      'username': safeUsername,
    });
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
}
