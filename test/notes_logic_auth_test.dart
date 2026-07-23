import 'package:flutter_test/flutter_test.dart';
import 'package:new_project/resources_and_services/notes_logic.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Builds a minimal [User] for tests. Only the fields under test need to
/// vary; the rest are required by the constructor but irrelevant here.
User buildUser({
  String id = 'user-1',
  String? emailConfirmedAt,
  List<UserIdentity>? identities,
}) {
  return User(
    id: id,
    appMetadata: const {},
    userMetadata: null,
    aud: 'authenticated',
    createdAt: '2024-01-01T00:00:00.000Z',
    emailConfirmedAt: emailConfirmedAt,
    identities: identities,
  );
}

Session buildSession(User user) {
  return Session(accessToken: 'token', tokenType: 'bearer', user: user);
}

void main() {
  group('NotesLogic.shouldRejectSignIn', () {
    test('does not reject a confirmed user from the response', () {
      final user = buildUser(emailConfirmedAt: '2024-01-01T00:00:00.000Z');
      final rejected = NotesLogic.shouldRejectSignIn(
        response: AuthResponse(user: user),
        currentUser: null,
      );
      expect(rejected, isFalse);
    });

    test('rejects an unconfirmed user from the response', () {
      final user = buildUser(emailConfirmedAt: null);
      final rejected = NotesLogic.shouldRejectSignIn(
        response: AuthResponse(user: user),
        currentUser: null,
      );
      expect(rejected, isTrue);
    });

    test('falls back to currentUser when the response has no user', () {
      final confirmed = buildUser(emailConfirmedAt: '2024-01-01T00:00:00.000Z');
      final rejected = NotesLogic.shouldRejectSignIn(
        response: AuthResponse(),
        currentUser: confirmed,
      );
      expect(rejected, isFalse);
    });

    test('rejects when neither the response nor currentUser has a user', () {
      final rejected = NotesLogic.shouldRejectSignIn(
        response: AuthResponse(),
        currentUser: null,
      );
      expect(rejected, isTrue);
    });
  });

  group('NotesLogic.interpretSignUpResponse', () {
    test(
        'detects an already-registered confirmed account via empty '
        'identities, regardless of confirmation/session state', () {
      final user = buildUser(identities: const []);
      final decision = NotesLogic.interpretSignUpResponse(
        response: AuthResponse(user: user, session: buildSession(user)),
        currentUser: null,
      );
      expect(decision.alreadyRegistered, isTrue);
      expect(decision.shouldSignOut, isFalse);
      expect(decision.completed, isFalse);
    });

    test('unconfirmed with an active session: signs out, not completed', () {
      final user = buildUser(emailConfirmedAt: null);
      final decision = NotesLogic.interpretSignUpResponse(
        response: AuthResponse(user: user, session: buildSession(user)),
        currentUser: null,
      );
      expect(decision.alreadyRegistered, isFalse);
      expect(decision.shouldSignOut, isTrue);
      expect(decision.completed, isFalse);
    });

    test(
        'unconfirmed with no session and no currentUser: nothing to sign '
        'out, not completed', () {
      final user = buildUser(emailConfirmedAt: null);
      final decision = NotesLogic.interpretSignUpResponse(
        response: AuthResponse(user: user),
        currentUser: null,
      );
      expect(decision.alreadyRegistered, isFalse);
      expect(decision.shouldSignOut, isFalse);
      expect(decision.completed, isFalse);
    });

    test('confirmed with an active session: completed, no sign-out', () {
      final user = buildUser(emailConfirmedAt: '2024-01-01T00:00:00.000Z');
      final decision = NotesLogic.interpretSignUpResponse(
        response: AuthResponse(user: user, session: buildSession(user)),
        currentUser: null,
      );
      expect(decision.alreadyRegistered, isFalse);
      expect(decision.shouldSignOut, isFalse);
      expect(decision.completed, isTrue);
    });

    test(
        'a pre-existing currentUser (no response.user, no response '
        'session) both resolves the confirmation check and counts as an '
        'active session: completed', () {
      final currentUser = buildUser(
        id: 'user-2',
        emailConfirmedAt: '2024-01-01T00:00:00.000Z',
      );
      final decision = NotesLogic.interpretSignUpResponse(
        response: AuthResponse(),
        currentUser: currentUser,
      );
      expect(decision.completed, isTrue);
    });

    test(
        'confirmed with no session and no currentUser: not completed '
        '(nothing to run ensureProfileForCurrentUser under)', () {
      final user = buildUser(emailConfirmedAt: '2024-01-01T00:00:00.000Z');
      final decision = NotesLogic.interpretSignUpResponse(
        response: AuthResponse(user: user),
        currentUser: null,
      );
      expect(decision.alreadyRegistered, isFalse);
      expect(decision.shouldSignOut, isFalse);
      expect(decision.completed, isFalse);
    });
  });

  group(
      'NotesLogic instance methods: guard clauses reachable without a '
      'Supabase client', () {
    final logic = NotesLogic();

    test('resendSignupConfirmationEmail throws on an invalid email', () {
      expect(
        () => logic.resendSignupConfirmationEmail(email: 'not-an-email'),
        throwsException,
      );
    });

    test('sendPasswordResetEmail throws on an invalid email', () {
      expect(
        () => logic.sendPasswordResetEmail(email: 'not-an-email'),
        throwsException,
      );
    });

    test('updatePassword throws when shorter than 6 characters', () {
      expect(() => logic.updatePassword('abc'), throwsException);
    });

    test('signInWithEmail throws on an invalid email', () {
      expect(
        () => logic.signInWithEmail(email: 'not-an-email', password: 'x'),
        throwsException,
      );
    });

    test('signUpWithUsername throws on an invalid username', () {
      expect(
        () => logic.signUpWithUsername(
          username: 'a',
          email: 'user@example.com',
          password: 'password123',
        ),
        throwsException,
      );
    });

    test('signUpWithUsername throws on an invalid email', () {
      expect(
        () => logic.signUpWithUsername(
          username: 'validname',
          email: 'not-an-email',
          password: 'password123',
        ),
        throwsException,
      );
    });
  });
}
