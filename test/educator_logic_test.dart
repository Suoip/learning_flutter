import 'package:flutter_test/flutter_test.dart';
import 'package:new_project/resources_and_services/educator_logic.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Builds a minimal [User] for tests. Only the fields under test need to
/// vary; the rest are required by the constructor but irrelevant here.
User buildUser({
  String id = 'user-1',
  Map<String, dynamic>? userMetadata,
  String? email,
  String? emailConfirmedAt,
}) {
  return User(
    id: id,
    appMetadata: const {},
    userMetadata: userMetadata,
    aud: 'authenticated',
    createdAt: '2024-01-01T00:00:00.000Z',
    email: email,
    emailConfirmedAt: emailConfirmedAt,
  );
}

void main() {
  group('EducatorLogic.userMessageForError', () {
    group('AuthException', () {
      test('maps "invalid" messages to a login error', () {
        expect(
          EducatorLogic.userMessageForError(
            const AuthException('Invalid login credentials'),
          ),
          'Incorrect email or password. Please try again.',
        );
      });

      test('maps "password" messages to a login error', () {
        expect(
          EducatorLogic.userMessageForError(
            const AuthException('Password is too weak'),
          ),
          'Incorrect email or password. Please try again.',
        );
      });

      test('maps "already" + "email" to an email-taken message', () {
        expect(
          EducatorLogic.userMessageForError(
            const AuthException('Email already exists'),
          ),
          'That email is already registered.',
        );
      });

      test('maps "already" without "email" to a username-taken message', () {
        expect(
          EducatorLogic.userMessageForError(
            const AuthException('Username already taken'),
          ),
          'That username is already taken.',
        );
      });

      test('maps "duplicate" to a username-taken message', () {
        expect(
          EducatorLogic.userMessageForError(
            const AuthException('Duplicate entry'),
          ),
          'That username is already taken.',
        );
      });

      test('maps "confirm" messages to an activation-required message', () {
        expect(
          EducatorLogic.userMessageForError(
            const AuthException('Email not confirmed'),
          ),
          'Your account needs email confirmation before login.',
        );
      });

      test('maps "rate limit" to a throttling message', () {
        expect(
          EducatorLogic.userMessageForError(
            const AuthException('Rate limit exceeded'),
          ),
          'Too many attempts. Please wait a moment and try again.',
        );
      });

      test('maps "too many" to a throttling message', () {
        expect(
          EducatorLogic.userMessageForError(
            const AuthException('Too many requests'),
          ),
          'Too many attempts. Please wait a moment and try again.',
        );
      });

      test('maps "smtp" to an admin-setup message', () {
        expect(
          EducatorLogic.userMessageForError(
            const AuthException('SMTP provider error'),
          ),
          'Registration email could not be sent. Please ask the app admin '
          'to finish Supabase email provider/SMTP setup.',
        );
      });

      test('falls back to a generic auth failure message', () {
        expect(
          EducatorLogic.userMessageForError(
            const AuthException('Something unexpected happened'),
          ),
          'Authentication failed. Please try again.',
        );
      });

      test(
          'maps a same-as-old-password rejection (code: same_password) to '
          'its own message, not a login failure', () {
        expect(
          EducatorLogic.userMessageForError(
            const AuthException(
              'New password should be different from the old password.',
              code: 'same_password',
            ),
          ),
          'Your new password must be different from your current password.',
        );
      });
    });

    group('PostgrestException', () {
      test('maps unique-violation code 23505', () {
        expect(
          EducatorLogic.userMessageForError(
            const PostgrestException(message: 'duplicate key', code: '23505'),
          ),
          'That value is already in use.',
        );
      });

      test('maps permission-denied code 42501', () {
        expect(
          EducatorLogic.userMessageForError(
            const PostgrestException(message: 'denied', code: '42501'),
          ),
          'You do not have permission to do that.',
        );
      });

      test('uses the fallback for other codes', () {
        expect(
          EducatorLogic.userMessageForError(
            const PostgrestException(message: 'oops', code: '99999'),
            fallback: 'custom fallback',
          ),
          'custom fallback',
        );
      });
    });

    group('generic errors', () {
      test('strips the "Exception: " prefix from a plain Exception', () {
        expect(
          EducatorLogic.userMessageForError(Exception('Could not save')),
          'Could not save',
        );
      });

      test('uses the fallback when the stripped message is empty', () {
        expect(
          EducatorLogic.userMessageForError(
            Exception(''),
            fallback: 'custom fallback',
          ),
          'custom fallback',
        );
      });

      test('collapses a raw AuthApiException string to a friendly message', () {
        expect(
          EducatorLogic.userMessageForError(
            Exception('AuthApiException(message: bad request, code: 400)'),
          ),
          'Authentication failed. Please try again.',
        );
      });

      test('passes through a plain non-Exception object as-is', () {
        expect(
          EducatorLogic.userMessageForError('raw string error'),
          'raw string error',
        );
      });
    });
  });

  group('defaultUsernameForUser', () {
    test('prefers the username from user metadata, lowercased', () {
      final user = buildUser(userMetadata: {'username': 'JaneTeaches'});
      expect(EducatorLogic.defaultUsernameForUser(user), 'janeteaches');
    });

    test('falls back to the email local-part when metadata is absent', () {
      final user = buildUser(email: 'Jane.Doe@Example.com');
      expect(EducatorLogic.defaultUsernameForUser(user), 'jane.doe');
    });

    test('falls back to the email local-part when metadata username is blank',
        () {
      final user = buildUser(
        userMetadata: {'username': '   '},
        email: 'blankmeta@example.com',
      );
      expect(EducatorLogic.defaultUsernameForUser(user), 'blankmeta');
    });

    test('returns "educator" when there is no metadata and no email', () {
      final user = buildUser();
      expect(EducatorLogic.defaultUsernameForUser(user), 'educator');
    });

    test('returns "educator" when the email has no local part before "@"', () {
      final user = buildUser(email: '@nodomain.com');
      expect(EducatorLogic.defaultUsernameForUser(user), 'educator');
    });
  });

  group('isValidUsername', () {
    test('accepts a typical username', () {
      expect(EducatorLogic.isValidUsername('jane_teaches123'), isTrue);
    });

    test('accepts the minimum length of 3', () {
      expect(EducatorLogic.isValidUsername('abc'), isTrue);
    });

    test('accepts the maximum length of 30', () {
      expect(EducatorLogic.isValidUsername('a' * 30), isTrue);
    });

    test('rejects fewer than 3 characters', () {
      expect(EducatorLogic.isValidUsername('jo'), isFalse);
    });

    test('rejects more than 30 characters', () {
      expect(EducatorLogic.isValidUsername('a' * 31), isFalse);
    });

    test('rejects spaces', () {
      expect(EducatorLogic.isValidUsername('jane teaches'), isFalse);
    });

    test('rejects disallowed symbols', () {
      expect(EducatorLogic.isValidUsername('jane@teaches'), isFalse);
    });

    test('accepts dots, dashes, and underscores', () {
      expect(EducatorLogic.isValidUsername('Jane.Teaches-123_x'), isTrue);
    });

    test('trims surrounding whitespace before validating', () {
      expect(EducatorLogic.isValidUsername('  jane  '), isTrue);
    });
  });

  group('isValidEmail', () {
    test('accepts a typical email', () {
      expect(EducatorLogic.isValidEmail('educator@example.com'), isTrue);
    });

    test('accepts a plus-tag and multi-level domain', () {
      expect(
        EducatorLogic.isValidEmail('user.name+tag@sub.example.co.uk'),
        isTrue,
      );
    });

    test('rejects a missing "@"', () {
      expect(EducatorLogic.isValidEmail('invalid'), isFalse);
    });

    test('rejects a missing domain', () {
      expect(EducatorLogic.isValidEmail('invalid@'), isFalse);
    });

    test('rejects a missing local part', () {
      expect(EducatorLogic.isValidEmail('@example.com'), isFalse);
    });

    test('rejects a domain without a dot', () {
      expect(EducatorLogic.isValidEmail('user@example'), isFalse);
    });

    test('rejects embedded spaces', () {
      expect(EducatorLogic.isValidEmail('user @example.com'), isFalse);
    });

    test('trims whitespace and ignores case before validating', () {
      expect(EducatorLogic.isValidEmail('  USER@EXAMPLE.COM  '), isTrue);
    });
  });

  group(
      'EducatorLogic instance methods: guard clauses reachable without a '
      'Supabase client', () {
    final logic = EducatorLogic();

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
          email: 'educator@example.com',
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
