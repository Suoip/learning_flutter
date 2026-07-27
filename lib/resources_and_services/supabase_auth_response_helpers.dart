import 'package:supabase_flutter/supabase_flutter.dart';

/// What a sign-up call should do next, derived from the shape of Supabase's
/// response rather than requiring a real (or faked) Supabase client - see
/// [interpretSignUpResponse]. Shared verbatim between Notes and SmartAcademy
/// educator auth: this is generic Supabase Auth-response semantics, not tied
/// to either feature's own tables.
class SignUpDecision {
  const SignUpDecision({
    required this.alreadyRegistered,
    required this.shouldSignOut,
    required this.completed,
  });

  /// The email already belongs to a confirmed account - the caller should
  /// reject the sign-up with a friendly "already registered" error.
  final bool alreadyRegistered;

  /// There's a session (or a pre-existing current user) that should be
  /// signed out - the account still needs email confirmation, so it
  /// shouldn't be left signed in.
  final bool shouldSignOut;

  /// Sign-up is complete and usable immediately - the caller should ensure
  /// the profile/educator row exists and report success.
  final bool completed;
}

bool isUserEmailConfirmed(User? user) {
  if (user == null) return false;
  final confirmedAt = user.toJson()['email_confirmed_at'];
  return confirmedAt != null && confirmedAt.toString().trim().isNotEmpty;
}

/// Whether a just-completed sign-in should be rejected because the
/// account's email isn't confirmed yet. Takes the already-constructed
/// [AuthResponse] rather than making the real `signInWithPassword` call
/// itself, so this branch is unit-testable without a real (or faked)
/// Supabase client.
bool shouldRejectSignIn({
  required AuthResponse response,
  required User? currentUser,
}) {
  final signedInUser = response.user ?? currentUser;
  return !isUserEmailConfirmed(signedInUser);
}

/// Derives what a sign-up call should do after `signUp` returns, from the
/// response shape alone - same testability rationale as [shouldRejectSignIn].
/// Supabase's `signUp` deliberately obscures whether an email is already
/// registered (to prevent account-enumeration attacks): for an existing,
/// already-confirmed account it returns a user with an empty `identities`
/// list and no session, rather than an error - checked first below, since it
/// takes priority over the confirmation check that follows.
SignUpDecision interpretSignUpResponse({
  required AuthResponse response,
  required User? currentUser,
}) {
  if (response.user?.identities?.isEmpty ?? false) {
    return const SignUpDecision(
      alreadyRegistered: true,
      shouldSignOut: false,
      completed: false,
    );
  }

  final hasActiveSession = response.session != null || currentUser != null;
  final signedUpUser = response.user ?? currentUser;

  if (!isUserEmailConfirmed(signedUpUser)) {
    return SignUpDecision(
      alreadyRegistered: false,
      shouldSignOut: hasActiveSession,
      completed: false,
    );
  }

  return SignUpDecision(
    alreadyRegistered: false,
    shouldSignOut: false,
    completed: hasActiveSession,
  );
}
