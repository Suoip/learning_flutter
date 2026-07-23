import 'package:flutter_test/flutter_test.dart';
import 'package:new_project/resources_and_services/notes_logic.dart';

import 'fakes/fake_friends_data_source.dart';
import 'fakes/fake_profiles_data_source.dart';

void main() {
  group('NotesLogic friends', () {
    late FakeFriendsDataSource friendsDataSource;
    late FakeProfilesDataSource profilesDataSource;
    late NotesLogic logic;

    setUp(() {
      friendsDataSource = FakeFriendsDataSource()..currentUserId = 'user-1';
      profilesDataSource = FakeProfilesDataSource()
        ..rows.addAll([
          {'id': 'user-1', 'username': 'alice'},
          {'id': 'user-2', 'username': 'bob'},
        ]);
      logic = NotesLogic(
        friendsDataSource: friendsDataSource,
        profilesDataSource: profilesDataSource,
      );
    });

    group('sendFriendRequestByUsername', () {
      test('throws when signed out', () {
        friendsDataSource.currentUserId = null;
        expect(
          () => logic.sendFriendRequestByUsername('bob'),
          throwsException,
        );
      });

      test('throws on an invalid username format', () {
        expect(() => logic.sendFriendRequestByUsername('a'), throwsException);
      });

      test('throws when no profile matches that username', () async {
        await expectLater(
          logic.sendFriendRequestByUsername('nobody'),
          throwsException,
        );
      });

      test('throws when sending to yourself', () async {
        await expectLater(
          logic.sendFriendRequestByUsername('alice'),
          throwsException,
        );
      });

      test('throws when already friends', () async {
        await friendsDataSource.upsertFriendship(
          lowId: 'user-1',
          highId: 'user-2',
        );

        await expectLater(
          logic.sendFriendRequestByUsername('bob'),
          throwsException,
        );
      });

      test('throws when a pending request already exists in either direction',
          () async {
        await friendsDataSource.insertFriendRequest({
          'sender_id': 'user-2',
          'receiver_id': 'user-1',
          'status': 'pending',
        });

        await expectLater(
          logic.sendFriendRequestByUsername('bob'),
          throwsException,
        );
      });

      test(
          'inserts a pending request from the current user to the target, '
          'normalizing the username', () async {
        await logic.sendFriendRequestByUsername('Bob');

        expect(friendsDataSource.requests.single['sender_id'], 'user-1');
        expect(friendsDataSource.requests.single['receiver_id'], 'user-2');
        expect(friendsDataSource.requests.single['status'], 'pending');
      });
    });

    group('fetchIncomingFriendRequests', () {
      test('returns an empty list when signed out', () async {
        friendsDataSource.currentUserId = null;
        expect(await logic.fetchIncomingFriendRequests(), isEmpty);
      });

      test(
          'returns pending requests sent to the current user, with the '
          'counterpart profile', () async {
        await friendsDataSource.insertFriendRequest({
          'sender_id': 'user-2',
          'receiver_id': 'user-1',
          'status': 'pending',
        });

        final result = await logic.fetchIncomingFriendRequests();

        expect(result.single.isIncoming, isTrue);
        expect(result.single.counterpart.username, 'bob');
      });

      test('excludes non-pending requests', () async {
        await friendsDataSource.insertFriendRequest({
          'sender_id': 'user-2',
          'receiver_id': 'user-1',
          'status': 'declined',
        });

        expect(await logic.fetchIncomingFriendRequests(), isEmpty);
      });
    });

    group('fetchOutgoingFriendRequests', () {
      test(
          'returns pending requests sent by the current user, with the '
          'counterpart profile', () async {
        await friendsDataSource.insertFriendRequest({
          'sender_id': 'user-1',
          'receiver_id': 'user-2',
          'status': 'pending',
        });

        final result = await logic.fetchOutgoingFriendRequests();

        expect(result.single.isIncoming, isFalse);
        expect(result.single.counterpart.username, 'bob');
      });
    });

    group('respondToFriendRequest', () {
      test('throws when signed out', () {
        friendsDataSource.currentUserId = null;
        expect(
          () => logic.respondToFriendRequest(requestId: 'x', accept: true),
          throwsException,
        );
      });

      test('throws when the request does not exist', () async {
        await expectLater(
          logic.respondToFriendRequest(requestId: 'nonexistent', accept: true),
          throwsException,
        );
      });

      test('throws when the current user is not the receiver', () async {
        await friendsDataSource.insertFriendRequest({
          'sender_id': 'user-1',
          'receiver_id': 'user-2',
          'status': 'pending',
        });
        final requestId = friendsDataSource.requests.single['id'] as String;

        await expectLater(
          logic.respondToFriendRequest(requestId: requestId, accept: true),
          throwsException,
        );
      });

      test('accepting creates a friendship and marks the request accepted',
          () async {
        await friendsDataSource.insertFriendRequest({
          'sender_id': 'user-2',
          'receiver_id': 'user-1',
          'status': 'pending',
        });
        final requestId = friendsDataSource.requests.single['id'] as String;

        await logic.respondToFriendRequest(requestId: requestId, accept: true);

        expect(friendsDataSource.requests.single['status'], 'accepted');
        expect(friendsDataSource.friendships, hasLength(1));
        final friendship = friendsDataSource.friendships.single;
        expect(
          {friendship['user_low_id'], friendship['user_high_id']},
          {'user-1', 'user-2'},
        );
      });

      test(
          'declining marks the request declined without creating a '
          'friendship', () async {
        await friendsDataSource.insertFriendRequest({
          'sender_id': 'user-2',
          'receiver_id': 'user-1',
          'status': 'pending',
        });
        final requestId = friendsDataSource.requests.single['id'] as String;

        await logic.respondToFriendRequest(
          requestId: requestId,
          accept: false,
        );

        expect(friendsDataSource.requests.single['status'], 'declined');
        expect(friendsDataSource.friendships, isEmpty);
      });
    });

    group('cancelFriendRequest', () {
      test('throws when signed out', () {
        friendsDataSource.currentUserId = null;
        expect(() => logic.cancelFriendRequest('x'), throwsException);
      });

      test('throws when the current user is not the sender', () async {
        await friendsDataSource.insertFriendRequest({
          'sender_id': 'user-2',
          'receiver_id': 'user-1',
          'status': 'pending',
        });
        final requestId = friendsDataSource.requests.single['id'] as String;

        await expectLater(
          logic.cancelFriendRequest(requestId),
          throwsException,
        );
      });

      test('marks a pending request cancelled', () async {
        await friendsDataSource.insertFriendRequest({
          'sender_id': 'user-1',
          'receiver_id': 'user-2',
          'status': 'pending',
        });
        final requestId = friendsDataSource.requests.single['id'] as String;

        await logic.cancelFriendRequest(requestId);

        expect(friendsDataSource.requests.single['status'], 'cancelled');
      });

      test('a cancelled request no longer blocks sending a new one', () async {
        await logic.sendFriendRequestByUsername('bob');
        final requestId = friendsDataSource.requests.single['id'] as String;
        await logic.cancelFriendRequest(requestId);

        await expectLater(
          logic.sendFriendRequestByUsername('bob'),
          completes,
        );
        expect(friendsDataSource.requests, hasLength(2));
      });
    });

    group('fetchFriends', () {
      test('returns an empty list when signed out', () async {
        friendsDataSource.currentUserId = null;
        expect(await logic.fetchFriends(), isEmpty);
      });

      test('returns the friend when the current user is the low id', () async {
        await friendsDataSource.upsertFriendship(
          lowId: 'user-1',
          highId: 'user-2',
        );

        final result = await logic.fetchFriends();

        expect(result.single.friend.username, 'bob');
      });

      test('returns the friend when the current user is the high id', () async {
        friendsDataSource.currentUserId = 'user-2';
        await friendsDataSource.upsertFriendship(
          lowId: 'user-1',
          highId: 'user-2',
        );

        final result = await logic.fetchFriends();

        expect(result.single.friend.username, 'alice');
      });
    });

    group('removeFriend', () {
      test('throws when signed out', () {
        friendsDataSource.currentUserId = null;
        expect(() => logic.removeFriend('x'), throwsException);
      });

      test('deletes the friendship', () async {
        await friendsDataSource.upsertFriendship(
          lowId: 'user-1',
          highId: 'user-2',
        );
        final friendshipId =
            friendsDataSource.friendships.single['id'] as String;

        await logic.removeFriend(friendshipId);

        expect(friendsDataSource.friendships, isEmpty);
      });
    });

    group('fetchIncomingRequestCount', () {
      test('returns 0 when signed out', () async {
        friendsDataSource.currentUserId = null;
        expect(await logic.fetchIncomingRequestCount(), 0);
      });

      test('counts only pending incoming requests', () async {
        await friendsDataSource.insertFriendRequest({
          'sender_id': 'user-2',
          'receiver_id': 'user-1',
          'status': 'pending',
        });
        await friendsDataSource.insertFriendRequest({
          'sender_id': 'user-1',
          'receiver_id': 'user-2',
          'status': 'pending',
        });

        expect(await logic.fetchIncomingRequestCount(), 1);
      });
    });
  });
}
