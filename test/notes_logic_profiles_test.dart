import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:new_project/resources_and_services/notes_logic.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'fakes/fake_profiles_data_source.dart';

/// Builds a minimal [User] for tests. Only the fields under test need to
/// vary; the rest are required by the constructor but irrelevant here.
User buildUser({
  String id = 'user-1',
  Map<String, dynamic>? userMetadata,
  String? email,
}) {
  return User(
    id: id,
    appMetadata: const {},
    userMetadata: userMetadata,
    aud: 'authenticated',
    createdAt: '2024-01-01T00:00:00.000Z',
    email: email,
  );
}

void main() {
  group('NotesLogic profiles', () {
    late FakeProfilesDataSource dataSource;
    late NotesLogic logic;

    setUp(() {
      dataSource = FakeProfilesDataSource()
        ..currentUser = buildUser(email: 'alice@example.com');
      logic = NotesLogic(profilesDataSource: dataSource);
    });

    group('ensureProfileForCurrentUser', () {
      test('does nothing when signed out', () async {
        dataSource.currentUser = null;
        await logic.ensureProfileForCurrentUser();
        expect(dataSource.rows, isEmpty);
      });

      test('inserts a new profile using a valid preferredUsername', () async {
        await logic.ensureProfileForCurrentUser(preferredUsername: 'Alice');

        expect(dataSource.rows.single['id'], 'user-1');
        expect(dataSource.rows.single['username'], 'alice');
      });

      test(
          'falls back to defaultUsernameForUser when preferredUsername is '
          'omitted', () async {
        await logic.ensureProfileForCurrentUser();

        expect(dataSource.rows.single['username'], 'alice');
      });

      test(
          'falls back to a generated username when preferredUsername is '
          'an invalid format', () async {
        dataSource.currentUser = buildUser(id: 'abcdefgh-1234-5678');

        await logic.ensureProfileForCurrentUser(preferredUsername: '!!');

        expect(dataSource.rows.single['username'], 'user_abcdefgh');
      });

      test('updates the existing row when the username differs', () async {
        dataSource.rows.add({'id': 'user-1', 'username': 'old-name'});

        await logic.ensureProfileForCurrentUser(preferredUsername: 'newname');

        expect(dataSource.rows.single['username'], 'newname');
      });

      test('does not write when the existing username already matches',
          () async {
        dataSource.rows.add({'id': 'user-1', 'username': 'alice'});

        await logic.ensureProfileForCurrentUser(preferredUsername: 'Alice');

        expect(dataSource.rows.single, {'id': 'user-1', 'username': 'alice'});
      });
    });

    group('fetchCurrentProfile', () {
      test('throws when signed out', () {
        dataSource.currentUser = null;
        expect(() => logic.fetchCurrentProfile(), throwsException);
      });

      test('creates and returns a profile on first call', () async {
        final profile = await logic.fetchCurrentProfile();

        expect(profile.id, 'user-1');
        expect(profile.username, 'alice');
        expect(profile.avatarUrl, isNull);
      });

      test('returns a trimmed avatarUrl when the row has one', () async {
        dataSource.rows.add({
          'id': 'user-1',
          'username': 'alice',
          'avatar_url': '  https://example.com/a.jpg  ',
        });

        final profile = await logic.fetchCurrentProfile();

        expect(profile.avatarUrl, 'https://example.com/a.jpg');
      });
    });

    group('updateUsername', () {
      test('throws when signed out', () {
        dataSource.currentUser = null;
        expect(() => logic.updateUsername('newname'), throwsException);
      });

      test('throws on an invalid username format', () {
        expect(() => logic.updateUsername('a'), throwsException);
      });

      // The successful write path also calls the still-unabstracted
      // `_client.auth.updateUser`, so it can't be exercised here without a
      // real (or faked) Supabase client - deferred to the future Auth data
      // source PR.
    });

    group('uploadProfileAvatar', () {
      test('throws when signed out', () {
        dataSource.currentUser = null;
        expect(
          () => logic.uploadProfileAvatar(
            bytes: Uint8List(0),
            extension: 'png',
          ),
          throwsException,
        );
      });

      test('throws on an unsupported extension format', () {
        // The extension check only validates shape (2-5 lowercase
        // alphanumeric chars), not a real image-type allowlist.
        expect(
          () => logic.uploadProfileAvatar(
            bytes: Uint8List(0),
            extension: 'a',
          ),
          throwsException,
        );
      });

      test(
          'uploads to <userId>/avatar.<ext> and persists a cache-busted '
          'URL', () async {
        // uploadProfileAvatar is only reachable in the real app after a
        // profile row already exists (see its own comment on why it's a
        // plain update, not an upsert) - seed one to match that.
        dataSource.rows.add({
          'id': 'user-1',
          'username': 'alice',
          'avatar_url': null,
        });
        final bytes = Uint8List.fromList([1, 2, 3]);

        final profile = await logic.uploadProfileAvatar(
          bytes: bytes,
          extension: 'PNG',
        );

        expect(dataSource.uploadedAvatars.keys.single, 'user-1/avatar.png');
        expect(dataSource.uploadedAvatars.values.single, bytes);
        expect(
          profile.avatarUrl,
          startsWith(
            'https://fake-storage.test/profile-pictures/user-1/avatar.png?v=',
          ),
        );
      });
    });

    group('searchUsersByUsername', () {
      setUp(() {
        // 'user-1' is the signed-in current user (see the top-level
        // setUp); its own 'alice' row exists here specifically to verify
        // the self-exclusion test below.
        dataSource.rows.addAll([
          {'id': 'user-1', 'username': 'alice'},
          {'id': 'user-2', 'username': 'alicia'},
          {'id': 'user-3', 'username': 'bob'},
        ]);
      });

      test('returns an empty list when signed out', () async {
        dataSource.currentUser = null;
        expect(await logic.searchUsersByUsername('ali'), isEmpty);
      });

      test('returns an empty list for an empty query', () async {
        expect(await logic.searchUsersByUsername('   '), isEmpty);
      });

      test(
          'matches usernames case-insensitively and substring-wise, '
          'excluding the current user', () async {
        final results = await logic.searchUsersByUsername('ALI');
        expect(results.map((p) => p.username), ['alicia']);
      });

      test('excludes the current user even when their own username matches',
          () async {
        final results = await logic.searchUsersByUsername('alice');
        expect(results, isEmpty);
      });
    });
  });
}
