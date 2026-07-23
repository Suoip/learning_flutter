import 'package:flutter_test/flutter_test.dart';
import 'package:new_project/resources_and_services/notes_logic.dart';

import 'fakes/fake_feed_data_source.dart';
import 'fakes/fake_friends_data_source.dart';
import 'fakes/fake_profiles_data_source.dart';

NoteItem buildNote({
  String id = 'note-1',
  String title = 'Untitled',
  String content = '',
}) {
  return NoteItem(
    id: id,
    title: title,
    content: content,
    updatedAt: DateTime(2024, 1, 1),
    isPinned: false,
    isFavorite: false,
  );
}

void main() {
  group('NotesLogic feed', () {
    late FakeFeedDataSource feedDataSource;
    late FakeFriendsDataSource friendsDataSource;
    late FakeProfilesDataSource profilesDataSource;
    late NotesLogic logic;

    setUp(() {
      feedDataSource = FakeFeedDataSource()..currentUserId = 'user-1';
      friendsDataSource = FakeFriendsDataSource()..currentUserId = 'user-1';
      profilesDataSource = FakeProfilesDataSource()
        ..rows.addAll([
          {'id': 'user-1', 'username': 'alice'},
          {'id': 'user-2', 'username': 'bob'},
        ]);
      logic = NotesLogic(
        feedDataSource: feedDataSource,
        friendsDataSource: friendsDataSource,
        profilesDataSource: profilesDataSource,
      );
    });

    group('publishNoteToFriends', () {
      test('throws when signed out', () {
        feedDataSource.currentUserId = null;
        expect(
          () => logic.publishNoteToFriends(buildNote()),
          throwsException,
        );
      });

      test('throws when there are no friends to publish to', () async {
        await expectLater(
          logic.publishNoteToFriends(buildNote()),
          throwsException,
        );
      });

      test('creates one shared-note row and one recipient row per friend',
          () async {
        await friendsDataSource.upsertFriendship(
          lowId: 'user-1',
          highId: 'user-2',
        );

        await logic.publishNoteToFriends(
          buildNote(id: 'note-1', title: 'Title', content: 'Content'),
        );

        expect(feedDataSource.sharedNotes, hasLength(1));
        final sharedNote = feedDataSource.sharedNotes.single;
        expect(sharedNote['note_id'], 'note-1');
        expect(sharedNote['author_id'], 'user-1');
        expect(sharedNote['title'], 'Title');
        expect(sharedNote['content'], 'Content');

        expect(feedDataSource.recipients, hasLength(1));
        expect(
          feedDataSource.recipients.single['shared_note_id'],
          sharedNote['id'],
        );
        expect(feedDataSource.recipients.single['recipient_id'], 'user-2');
      });

      test(
          'republishing updates the existing row and does not duplicate '
          'recipients', () async {
        await friendsDataSource.upsertFriendship(
          lowId: 'user-1',
          highId: 'user-2',
        );

        await logic.publishNoteToFriends(
          buildNote(id: 'note-1', title: 'Original'),
        );
        await logic.publishNoteToFriends(
          buildNote(id: 'note-1', title: 'Updated'),
        );

        expect(feedDataSource.sharedNotes, hasLength(1));
        expect(feedDataSource.sharedNotes.single['title'], 'Updated');
        expect(feedDataSource.recipients, hasLength(1));
      });
    });

    group('unpublishNoteFromFriends', () {
      test('deletes the shared note and its recipients/likes/comments',
          () async {
        await friendsDataSource.upsertFriendship(
          lowId: 'user-1',
          highId: 'user-2',
        );
        await logic.publishNoteToFriends(buildNote(id: 'note-1'));
        final sharedNoteId = feedDataSource.sharedNotes.single['id'] as String;
        await logic.toggleFeedLike(sharedNoteId);
        await logic.addFeedComment(sharedNoteId: sharedNoteId, content: 'hi');

        await logic.unpublishNoteFromFriends('note-1');

        expect(feedDataSource.sharedNotes, isEmpty);
        expect(feedDataSource.recipients, isEmpty);
        expect(feedDataSource.likes, isEmpty);
        expect(feedDataSource.comments, isEmpty);
      });
    });

    group('fetchPublishedNoteIdsForCurrentUser', () {
      test('returns an empty set when signed out', () async {
        feedDataSource.currentUserId = null;
        expect(await logic.fetchPublishedNoteIdsForCurrentUser(), isEmpty);
      });

      test('returns every note id the current user has published', () async {
        await friendsDataSource.upsertFriendship(
          lowId: 'user-1',
          highId: 'user-2',
        );
        await logic.publishNoteToFriends(buildNote(id: 'note-1'));
        await logic.publishNoteToFriends(buildNote(id: 'note-2'));

        expect(
          await logic.fetchPublishedNoteIdsForCurrentUser(),
          {'note-1', 'note-2'},
        );
      });
    });

    group('fetchFriendsFeed', () {
      test('returns an empty list when signed out', () async {
        feedDataSource.currentUserId = null;
        expect(await logic.fetchFriendsFeed(), isEmpty);
      });

      test(
          'includes the current user\'s own published notes, marked '
          'isOwnPost', () async {
        await friendsDataSource.upsertFriendship(
          lowId: 'user-1',
          highId: 'user-2',
        );
        await logic.publishNoteToFriends(buildNote(id: 'note-1'));

        final feed = await logic.fetchFriendsFeed();

        expect(feed.single.isOwnPost, isTrue);
        expect(feed.single.authorUsername, 'alice');
      });

      test(
          'includes notes shared to the current user by a friend, not '
          'marked isOwnPost', () async {
        feedDataSource.sharedNotes.add({
          'id': 'shared-99',
          'note_id': 'note-99',
          'author_id': 'user-2',
          'title': 'Bob\'s note',
          'content': 'Hello',
          'published_at': '2024-02-01T00:00:00.000Z',
        });
        feedDataSource.recipients.add({
          'shared_note_id': 'shared-99',
          'recipient_id': 'user-1',
          'created_at': '2024-02-01T00:00:00.000Z',
        });

        final feed = await logic.fetchFriendsFeed();

        expect(feed.single.isOwnPost, isFalse);
        expect(feed.single.authorUsername, 'bob');
      });

      test(
          'merges own and shared-to-me posts, sorted by publishedAt '
          'descending', () async {
        feedDataSource.sharedNotes.addAll([
          {
            'id': 'shared-older',
            'note_id': 'note-a',
            'author_id': 'user-1',
            'title': 'Older',
            'content': '',
            'published_at': '2024-01-01T00:00:00.000Z',
          },
          {
            'id': 'shared-newer',
            'note_id': 'note-b',
            'author_id': 'user-2',
            'title': 'Newer',
            'content': '',
            'published_at': '2024-06-01T00:00:00.000Z',
          },
        ]);
        feedDataSource.recipients.add({
          'shared_note_id': 'shared-newer',
          'recipient_id': 'user-1',
          'created_at': '2024-06-01T00:00:00.000Z',
        });

        final feed = await logic.fetchFriendsFeed();

        expect(feed.map((e) => e.id), ['shared-newer', 'shared-older']);
      });

      test(
          'aggregates likes and comments from multiple friends on the same '
          'shared note (not fragmented per recipient)', () async {
        await friendsDataSource.upsertFriendship(
          lowId: 'user-1',
          highId: 'user-2',
        );
        await logic.publishNoteToFriends(buildNote(id: 'note-1'));
        final sharedNoteId = feedDataSource.sharedNotes.single['id'] as String;
        feedDataSource.likes.add({
          'shared_note_id': sharedNoteId,
          'user_id': 'user-2',
        });
        feedDataSource.comments.add({
          'id': 'comment-1',
          'shared_note_id': sharedNoteId,
          'user_id': 'user-2',
          'content': 'Nice note!',
          'created_at': '2024-01-02T00:00:00.000Z',
        });

        final feed = await logic.fetchFriendsFeed();

        expect(feed.single.likeCount, 1);
        expect(feed.single.commentCount, 1);
        expect(feed.single.isLikedByCurrentUser, isFalse);
      });

      test(
          'deduplicates a shared note that would otherwise appear in both '
          'the authored and shared-to-me sets', () async {
        feedDataSource.sharedNotes.add({
          'id': 'shared-1',
          'note_id': 'note-1',
          'author_id': 'user-1',
          'title': 'Mine',
          'content': '',
          'published_at': '2024-01-01T00:00:00.000Z',
        });
        // Not something the app would ever insert - a recipient row naming
        // the note's own author - but nothing at the DB level forbids it,
        // so the merge logic must not produce a duplicate card for it.
        feedDataSource.recipients.add({
          'shared_note_id': 'shared-1',
          'recipient_id': 'user-1',
          'created_at': '2024-01-01T00:00:00.000Z',
        });

        final feed = await logic.fetchFriendsFeed();

        expect(feed, hasLength(1));
      });
    });

    group('toggleFeedLike', () {
      test(
          'inserts a like when none exists, then removes it on a second '
          'call', () async {
        await logic.toggleFeedLike('shared-1');
        expect(feedDataSource.likes, hasLength(1));

        await logic.toggleFeedLike('shared-1');
        expect(feedDataSource.likes, isEmpty);
      });
    });

    group('addFeedComment', () {
      test('throws when signed out', () {
        feedDataSource.currentUserId = null;
        expect(
          () => logic.addFeedComment(sharedNoteId: 'shared-1', content: 'hi'),
          throwsException,
        );
      });

      test('throws on empty content', () {
        expect(
          () => logic.addFeedComment(sharedNoteId: 'shared-1', content: '  '),
          throwsException,
        );
      });

      test('throws on content over 500 characters', () {
        expect(
          () => logic.addFeedComment(
            sharedNoteId: 'shared-1',
            content: 'a' * 501,
          ),
          throwsException,
        );
      });

      test('adds a trimmed comment', () async {
        await logic.addFeedComment(
          sharedNoteId: 'shared-1',
          content: '  Nice!  ',
        );

        expect(feedDataSource.comments.single['content'], 'Nice!');
        expect(feedDataSource.comments.single['user_id'], 'user-1');
      });
    });

    group('fetchFeedComments', () {
      test('returns comments with author profile, in chronological order',
          () async {
        feedDataSource.comments.addAll([
          {
            'id': 'comment-2',
            'shared_note_id': 'shared-1',
            'user_id': 'user-2',
            'content': 'Second',
            'created_at': '2024-01-02T00:00:00.000Z',
          },
          {
            'id': 'comment-1',
            'shared_note_id': 'shared-1',
            'user_id': 'user-1',
            'content': 'First',
            'created_at': '2024-01-01T00:00:00.000Z',
          },
        ]);

        final comments = await logic.fetchFeedComments('shared-1');

        expect(comments.map((c) => c.content), ['First', 'Second']);
        expect(comments.first.authorUsername, 'alice');
        expect(comments.last.authorUsername, 'bob');
      });
    });
  });
}
