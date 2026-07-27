import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:new_project/resources_and_services/educator_logic.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'fakes/fake_educator_profile_data_source.dart';

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
  group('EducatorLogic profile', () {
    late FakeEducatorProfileDataSource dataSource;
    late EducatorLogic logic;

    setUp(() {
      dataSource = FakeEducatorProfileDataSource()
        ..currentUser = buildUser(email: 'alice@example.com');
      logic = EducatorLogic(educatorProfileDataSource: dataSource);
    });

    group('ensureEducatorForCurrentUser', () {
      test('does nothing when signed out', () async {
        dataSource.currentUser = null;
        await logic.ensureEducatorForCurrentUser();
        expect(dataSource.rows, isEmpty);
      });

      test('inserts a new educator using a valid preferredUsername', () async {
        await logic.ensureEducatorForCurrentUser(preferredUsername: 'Alice');

        expect(dataSource.rows.single['id'], 'user-1');
        expect(dataSource.rows.single['username'], 'alice');
      });

      test(
          'falls back to defaultUsernameForUser when preferredUsername is '
          'omitted', () async {
        await logic.ensureEducatorForCurrentUser();

        expect(dataSource.rows.single['username'], 'alice');
      });

      test(
          'falls back to a generated username when preferredUsername is '
          'an invalid format', () async {
        dataSource.currentUser = buildUser(id: 'abcdefgh-1234-5678');

        await logic.ensureEducatorForCurrentUser(preferredUsername: '!!');

        expect(dataSource.rows.single['username'], 'educator_abcdefgh');
      });

      test('updates the existing row when the username differs', () async {
        dataSource.rows.add({'id': 'user-1', 'username': 'old-name'});

        await logic.ensureEducatorForCurrentUser(preferredUsername: 'newname');

        expect(dataSource.rows.single['username'], 'newname');
      });

      test('does not write when the existing username already matches',
          () async {
        dataSource.rows.add({'id': 'user-1', 'username': 'alice'});

        await logic.ensureEducatorForCurrentUser(preferredUsername: 'Alice');

        expect(dataSource.rows.single, {'id': 'user-1', 'username': 'alice'});
      });
    });

    group('fetchCurrentEducatorProfile', () {
      test('throws when signed out', () {
        dataSource.currentUser = null;
        expect(() => logic.fetchCurrentEducatorProfile(), throwsException);
      });

      test('creates and returns a profile on first fetch', () async {
        final profile = await logic.fetchCurrentEducatorProfile();

        expect(profile.id, 'user-1');
        expect(profile.username, 'alice');
        expect(profile.avatarUrl, isNull);
      });

      test('returns the existing row on subsequent fetches', () async {
        dataSource.rows.add({
          'id': 'user-1',
          'username': 'alice',
          'avatar_url': 'https://example.com/a.png',
        });

        final profile = await logic.fetchCurrentEducatorProfile();

        expect(profile.avatarUrl, 'https://example.com/a.png');
      });
    });

    group('updateUsername', () {
      test('throws when signed out', () {
        dataSource.currentUser = null;
        expect(() => logic.updateUsername('newname'), throwsException);
      });

      test('rejects an invalid format', () {
        expect(() => logic.updateUsername('!!'), throwsException);
      });

      // The successful write path also calls the still-unabstracted
      // `_client.auth.updateUser`, so it can't be exercised here without a
      // real (or faked) Supabase client - same accepted gap as
      // NotesLogic.updateUsername (see notes_logic_profiles_test.dart).
    });

    group('uploadEducatorAvatar', () {
      test('throws when signed out', () {
        dataSource.currentUser = null;
        expect(
          () => logic.uploadEducatorAvatar(
            bytes: Uint8List(0),
            extension: 'png',
          ),
          throwsException,
        );
      });

      test('rejects an unsupported extension', () {
        dataSource.rows.add({'id': 'user-1', 'username': 'alice'});

        expect(
          () => logic.uploadEducatorAvatar(
            bytes: Uint8List(0),
            extension: '!!!',
          ),
          throwsException,
        );
      });

      test('uploads to a per-user object path and stores a cache-busted url',
          () async {
        dataSource.rows.add({'id': 'user-1', 'username': 'alice'});

        final profile = await logic.uploadEducatorAvatar(
          bytes: Uint8List.fromList([1, 2, 3]),
          extension: 'PNG',
        );

        expect(dataSource.uploadedAvatars.keys.single, 'user-1/avatar.png');
        expect(
            profile.avatarUrl, contains('educator-avatars/user-1/avatar.png'));
        expect(profile.avatarUrl, contains('?v='));
      });
    });
  });
}
