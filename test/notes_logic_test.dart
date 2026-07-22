import 'package:flutter_test/flutter_test.dart';
import 'package:new_project/resources_and_services/notes_logic.dart';
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

NoteItem buildNote({
  String id = 'note-1',
  String title = 'Untitled',
  String content = '',
  DateTime? updatedAt,
  bool isPinned = false,
  bool isFavorite = false,
}) {
  return NoteItem(
    id: id,
    title: title,
    content: content,
    updatedAt: updatedAt ?? DateTime(2024, 1, 1),
    isPinned: isPinned,
    isFavorite: isFavorite,
  );
}

void main() {
  group('isUserEmailConfirmed', () {
    test('returns false for a null user', () {
      expect(NotesLogic.isUserEmailConfirmed(null), isFalse);
    });

    test('returns false when email_confirmed_at is absent', () {
      final user = buildUser(emailConfirmedAt: null);
      expect(NotesLogic.isUserEmailConfirmed(user), isFalse);
    });

    test('returns false when email_confirmed_at is an empty string', () {
      final user = buildUser(emailConfirmedAt: '');
      expect(NotesLogic.isUserEmailConfirmed(user), isFalse);
    });

    test('returns false when email_confirmed_at is only whitespace', () {
      final user = buildUser(emailConfirmedAt: '   ');
      expect(NotesLogic.isUserEmailConfirmed(user), isFalse);
    });

    test('returns true when email_confirmed_at has a timestamp', () {
      final user = buildUser(emailConfirmedAt: '2024-03-01T00:00:00.000Z');
      expect(NotesLogic.isUserEmailConfirmed(user), isTrue);
    });
  });

  group('formatUpdatedTime', () {
    test('formats an afternoon time', () {
      expect(
        NotesLogic.formatUpdatedTime(DateTime(2024, 3, 15, 14, 30)),
        'Mar 15, 2:30 PM',
      );
    });

    test('formats a single-digit morning hour with zero-padded minutes', () {
      expect(
        NotesLogic.formatUpdatedTime(DateTime(2024, 1, 5, 9, 5)),
        'Jan 5, 9:05 AM',
      );
    });

    test('formats midnight as 12 AM', () {
      expect(
        NotesLogic.formatUpdatedTime(DateTime(2024, 12, 25, 0, 0)),
        'Dec 25, 12:00 AM',
      );
    });

    test('formats noon as 12 PM', () {
      expect(
        NotesLogic.formatUpdatedTime(DateTime(2024, 6, 1, 12, 0)),
        'Jun 1, 12:00 PM',
      );
    });
  });

  group('parseTimestamp', () {
    test('falls back to roughly now when the value is null', () {
      final before = DateTime.now().toUtc();
      final parsed = NotesLogic.parseTimestamp(null);
      final after = DateTime.now().toUtc();

      expect(parsed.isUtc, isTrue);
      expect(
        parsed.isAfter(before.subtract(const Duration(seconds: 5))),
        isTrue,
      );
      expect(parsed.isBefore(after.add(const Duration(seconds: 5))), isTrue);
    });

    test('parses a UTC ISO-8601 string', () {
      final parsed = NotesLogic.parseTimestamp('2024-03-15T10:00:00.000Z');
      expect(parsed, DateTime.parse('2024-03-15T10:00:00.000Z').toUtc());
    });

    test('converts a non-String value via toString()', () {
      // Supabase rows always hand back Strings for timestamp columns, but
      // the method accepts dynamic - confirm it still round-trips a value
      // whose toString() is a valid ISO-8601 string.
      final parsed = NotesLogic.parseTimestamp(
        DateTime.parse('2024-06-01T00:00:00.000Z'),
      );
      expect(parsed, DateTime.parse('2024-06-01T00:00:00.000Z').toUtc());
    });
  });

  group('userMessageForError', () {
    group('AuthException', () {
      test('maps "invalid" messages to a login error', () {
        expect(
          NotesLogic.userMessageForError(
            const AuthException('Invalid login credentials'),
          ),
          'Incorrect email or password. Please try again.',
        );
      });

      test('maps "password" messages to a login error', () {
        expect(
          NotesLogic.userMessageForError(
            const AuthException('Password is too weak'),
          ),
          'Incorrect email or password. Please try again.',
        );
      });

      test('maps "already" + "email" to an email-taken message', () {
        expect(
          NotesLogic.userMessageForError(
            const AuthException('Email already exists'),
          ),
          'That email is already registered.',
        );
      });

      test('maps "already" without "email" to a username-taken message', () {
        expect(
          NotesLogic.userMessageForError(
            const AuthException('Username already taken'),
          ),
          'That username is already taken.',
        );
      });

      test('maps "duplicate" to a username-taken message', () {
        expect(
          NotesLogic.userMessageForError(
            const AuthException('Duplicate entry'),
          ),
          'That username is already taken.',
        );
      });

      test('maps "confirm" messages to an activation-required message', () {
        expect(
          NotesLogic.userMessageForError(
            const AuthException('Email not confirmed'),
          ),
          'Your account needs email confirmation before login.',
        );
      });

      test('maps "rate limit" to a throttling message', () {
        expect(
          NotesLogic.userMessageForError(
            const AuthException('Rate limit exceeded'),
          ),
          'Too many attempts. Please wait a moment and try again.',
        );
      });

      test('maps "too many" to a throttling message', () {
        expect(
          NotesLogic.userMessageForError(
            const AuthException('Too many requests'),
          ),
          'Too many attempts. Please wait a moment and try again.',
        );
      });

      test('maps "smtp" to an admin-setup message', () {
        expect(
          NotesLogic.userMessageForError(
            const AuthException('SMTP provider error'),
          ),
          'Registration email could not be sent. Please ask the app admin '
          'to finish Supabase email provider/SMTP setup.',
        );
      });

      test('falls back to a generic auth failure message', () {
        expect(
          NotesLogic.userMessageForError(
            const AuthException('Something unexpected happened'),
          ),
          'Authentication failed. Please try again.',
        );
      });
    });

    group('PostgrestException', () {
      test('maps unique-violation code 23505', () {
        expect(
          NotesLogic.userMessageForError(
            const PostgrestException(message: 'duplicate key', code: '23505'),
          ),
          'That value is already in use.',
        );
      });

      test('maps permission-denied code 42501', () {
        expect(
          NotesLogic.userMessageForError(
            const PostgrestException(message: 'denied', code: '42501'),
          ),
          'You do not have permission to do that.',
        );
      });

      test('uses the fallback for other codes', () {
        expect(
          NotesLogic.userMessageForError(
            const PostgrestException(message: 'oops', code: '99999'),
            fallback: 'custom fallback',
          ),
          'custom fallback',
        );
      });
    });

    group('StorageException', () {
      test('maps "size" to an unsupported-file message', () {
        expect(
          NotesLogic.userMessageForError(
            const StorageException('File exceeds max size'),
          ),
          'That file is not supported. Use JPG, PNG, or WEBP up to 5MB.',
        );
      });

      test('maps "mime" to an unsupported-file message', () {
        expect(
          NotesLogic.userMessageForError(
            const StorageException('Unsupported mime type'),
          ),
          'That file is not supported. Use JPG, PNG, or WEBP up to 5MB.',
        );
      });

      test('falls back to a generic upload-failure message', () {
        expect(
          NotesLogic.userMessageForError(
            const StorageException('bucket not found'),
          ),
          'Unable to upload file right now. Please try again.',
        );
      });
    });

    group('generic errors', () {
      test('strips the "Exception: " prefix from a plain Exception', () {
        expect(
          NotesLogic.userMessageForError(Exception('Could not save note')),
          'Could not save note',
        );
      });

      test('uses the fallback when the stripped message is empty', () {
        expect(
          NotesLogic.userMessageForError(
            Exception(''),
            fallback: 'custom fallback',
          ),
          'custom fallback',
        );
      });

      test('collapses a raw AuthApiException string to a friendly message', () {
        expect(
          NotesLogic.userMessageForError(
            Exception('AuthApiException(message: bad request, code: 400)'),
          ),
          'Authentication failed. Please try again.',
        );
      });

      test('passes through a plain non-Exception object as-is', () {
        expect(NotesLogic.userMessageForError('raw string error'),
            'raw string error');
      });
    });
  });

  group('defaultUsernameForUser', () {
    test('prefers the username from user metadata, lowercased', () {
      final user = buildUser(userMetadata: {'username': 'JohnDoe'});
      expect(NotesLogic.defaultUsernameForUser(user), 'johndoe');
    });

    test('falls back to the email local-part when metadata is absent', () {
      final user = buildUser(email: 'Jane.Doe@Example.com');
      expect(NotesLogic.defaultUsernameForUser(user), 'jane.doe');
    });

    test('falls back to the email local-part when metadata username is blank',
        () {
      final user = buildUser(
        userMetadata: {'username': '   '},
        email: 'blankmeta@example.com',
      );
      expect(NotesLogic.defaultUsernameForUser(user), 'blankmeta');
    });

    test('returns "user" when there is no metadata and no email', () {
      final user = buildUser();
      expect(NotesLogic.defaultUsernameForUser(user), 'user');
    });

    test('returns "user" when the email has no local part before "@"', () {
      final user = buildUser(email: '@nodomain.com');
      expect(NotesLogic.defaultUsernameForUser(user), 'user');
    });
  });

  group('isValidUsername', () {
    test('accepts a typical username', () {
      expect(NotesLogic.isValidUsername('john_doe123'), isTrue);
    });

    test('accepts the minimum length of 3', () {
      expect(NotesLogic.isValidUsername('abc'), isTrue);
    });

    test('accepts the maximum length of 30', () {
      expect(NotesLogic.isValidUsername('a' * 30), isTrue);
    });

    test('rejects fewer than 3 characters', () {
      expect(NotesLogic.isValidUsername('jo'), isFalse);
    });

    test('rejects more than 30 characters', () {
      expect(NotesLogic.isValidUsername('a' * 31), isFalse);
    });

    test('rejects spaces', () {
      expect(NotesLogic.isValidUsername('john doe'), isFalse);
    });

    test('rejects disallowed symbols', () {
      expect(NotesLogic.isValidUsername('john@doe'), isFalse);
    });

    test('accepts dots, dashes, and underscores', () {
      expect(NotesLogic.isValidUsername('John.Doe-123_x'), isTrue);
    });

    test('trims surrounding whitespace before validating', () {
      expect(NotesLogic.isValidUsername('  john  '), isTrue);
    });
  });

  group('isValidEmail', () {
    test('accepts a typical email', () {
      expect(NotesLogic.isValidEmail('user@example.com'), isTrue);
    });

    test('accepts a plus-tag and multi-level domain', () {
      expect(
        NotesLogic.isValidEmail('user.name+tag@sub.example.co.uk'),
        isTrue,
      );
    });

    test('rejects a missing "@"', () {
      expect(NotesLogic.isValidEmail('invalid'), isFalse);
    });

    test('rejects a missing domain', () {
      expect(NotesLogic.isValidEmail('invalid@'), isFalse);
    });

    test('rejects a missing local part', () {
      expect(NotesLogic.isValidEmail('@example.com'), isFalse);
    });

    test('rejects a domain without a dot', () {
      expect(NotesLogic.isValidEmail('user@example'), isFalse);
    });

    test('rejects embedded spaces', () {
      expect(NotesLogic.isValidEmail('user @example.com'), isFalse);
    });

    test('trims whitespace and ignores case before validating', () {
      expect(NotesLogic.isValidEmail('  USER@EXAMPLE.COM  '), isTrue);
    });
  });

  group('NoteItem.fromMap', () {
    test('parses a complete row', () {
      final note = NoteItem.fromMap({
        'id': 'abc-123',
        'title': 'Groceries',
        'content': 'Milk, eggs',
        'updated_at': '2024-05-01T12:00:00.000Z',
        'created_at': '2024-04-01T12:00:00.000Z',
        'is_pinned': true,
        'is_favorite': true,
      });

      expect(note.id, 'abc-123');
      expect(note.title, 'Groceries');
      expect(note.content, 'Milk, eggs');
      expect(note.updatedAt, DateTime.parse('2024-05-01T12:00:00.000Z'));
      expect(note.isPinned, isTrue);
      expect(note.isFavorite, isTrue);
    });

    test('defaults title and content to empty strings when missing', () {
      final note = NoteItem.fromMap({
        'id': 1,
        'updated_at': '2024-05-01T12:00:00.000Z',
      });

      expect(note.id, '1');
      expect(note.title, '');
      expect(note.content, '');
    });

    test('falls back to created_at when updated_at is missing', () {
      final note = NoteItem.fromMap({
        'id': 'abc',
        'created_at': '2024-04-01T12:00:00.000Z',
      });

      expect(note.updatedAt, DateTime.parse('2024-04-01T12:00:00.000Z'));
    });

    test('treats any non-true value for is_pinned/is_favorite as false', () {
      final note = NoteItem.fromMap({
        'id': 'abc',
        'updated_at': '2024-05-01T12:00:00.000Z',
        'is_pinned': null,
        'is_favorite': 1,
      });

      expect(note.isPinned, isFalse);
      expect(note.isFavorite, isFalse);
    });
  });

  group('UserProfile.fromMap', () {
    test('uses the username from the row when present', () {
      final profile = UserProfile.fromMap(
        user: buildUser(email: 'fallback@example.com'),
        map: {'username': 'RowUsername', 'avatar_url': ' https://x/y.png '},
      );

      expect(profile.username, 'rowusername');
      expect(profile.avatarUrl, 'https://x/y.png');
    });

    test('falls back to defaultUsernameForUser when the row has none', () {
      final profile = UserProfile.fromMap(
        user: buildUser(email: 'fallback@example.com'),
        map: const {},
      );

      expect(profile.username, 'fallback');
    });

    test('leaves avatarUrl null when absent', () {
      final profile = UserProfile.fromMap(
        user: buildUser(email: 'fallback@example.com'),
        map: const {'username': 'someone'},
      );

      expect(profile.avatarUrl, isNull);
    });
  });

  group('ProfilePreview.fromMap', () {
    test('parses a complete row', () {
      final preview = ProfilePreview.fromMap({
        'id': 'user-9',
        'username': 'someone',
        'avatar_url': 'https://x/y.png',
      });

      expect(preview.id, 'user-9');
      expect(preview.username, 'someone');
      expect(preview.avatarUrl, 'https://x/y.png');
    });

    test('defaults username to an empty string and coerces id to String', () {
      final preview = ProfilePreview.fromMap({'id': 42});

      expect(preview.id, '42');
      expect(preview.username, '');
      expect(preview.avatarUrl, isNull);
    });
  });

  group('NotesLogic.filterNotes', () {
    final meetingNotes = buildNote(id: '1', title: 'Meeting notes');
    final groceries = buildNote(id: '2', title: 'Groceries', isPinned: true);
    final travelPlans =
        buildNote(id: '3', title: 'Travel plans', isFavorite: true);
    final notes = [meetingNotes, groceries, travelPlans];

    test('returns everything for an empty query with the "all" filter', () {
      final result = NotesLogic.filterNotes(
        notes: notes,
        searchQuery: '',
        filter: NoteQuickFilter.all,
      );
      expect(result.map((n) => n.id), unorderedEquals(['1', '2', '3']));
    });

    test('matches titles case-insensitively', () {
      final result = NotesLogic.filterNotes(
        notes: notes,
        searchQuery: 'MEETING',
        filter: NoteQuickFilter.all,
      );
      expect(result.map((n) => n.id), ['1']);
    });

    test('keeps only pinned notes for the "pinned" filter', () {
      final result = NotesLogic.filterNotes(
        notes: notes,
        searchQuery: '',
        filter: NoteQuickFilter.pinned,
      );
      expect(result.map((n) => n.id), ['2']);
    });

    test('keeps only favorite notes for the "favorites" filter', () {
      final result = NotesLogic.filterNotes(
        notes: notes,
        searchQuery: '',
        filter: NoteQuickFilter.favorites,
      );
      expect(result.map((n) => n.id), ['3']);
    });

    test('combines a search query with a filter', () {
      final result = NotesLogic.filterNotes(
        notes: notes,
        searchQuery: 'travel',
        filter: NoteQuickFilter.favorites,
      );
      expect(result.map((n) => n.id), ['3']);
    });

    test('returns an empty list when nothing matches', () {
      final result = NotesLogic.filterNotes(
        notes: notes,
        searchQuery: 'nonexistent',
        filter: NoteQuickFilter.all,
      );
      expect(result, isEmpty);
    });
  });

  group('NotesLogic.sortNotes', () {
    test('puts pinned notes before unpinned notes', () {
      final unpinned = buildNote(id: 'a', isPinned: false);
      final pinned = buildNote(id: 'b', isPinned: true);

      final sorted = NotesLogic.sortNotes([unpinned, pinned]);

      expect(sorted.map((n) => n.id), ['b', 'a']);
    });

    test('orders same-pin-state notes by updatedAt descending', () {
      final older = buildNote(id: 'old', updatedAt: DateTime(2024, 1, 1));
      final newer = buildNote(id: 'new', updatedAt: DateTime(2024, 6, 1));

      final sorted = NotesLogic.sortNotes([older, newer]);

      expect(sorted.map((n) => n.id), ['new', 'old']);
    });

    test('does not mutate the input list', () {
      final first = buildNote(id: 'first', updatedAt: DateTime(2024, 1, 1));
      final second = buildNote(id: 'second', updatedAt: DateTime(2024, 6, 1));
      final input = [first, second];

      NotesLogic.sortNotes(input);

      expect(input.map((n) => n.id), ['first', 'second']);
    });
  });
}
