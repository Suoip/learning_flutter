import 'package:flutter_test/flutter_test.dart';
import 'package:new_project/resources_and_services/educator_logic.dart';

import 'fakes/fake_educator_forum_engagement_data_source.dart';
import 'fakes/fake_educator_forum_posts_data_source.dart';
import 'fakes/fake_educator_profile_data_source.dart';
import 'fakes/fake_profiles_data_source.dart';

Map<String, dynamic> _post({
  String id = 'post-a',
  String educatorId = 'educator-1',
}) {
  return {
    'id': id,
    'educator_id': educatorId,
    'title': 'Post',
    'description': '',
    'updated_at': '2024-01-01T00:00:00.000Z',
    'created_at': '2024-01-01T00:00:00.000Z',
  };
}

Map<String, dynamic> _comment({
  String id = 'c1',
  String forumPostId = 'post-a',
  required String userId,
}) {
  return {
    'id': id,
    'forum_post_id': forumPostId,
    'user_id': userId,
    'content': 'hi',
    'created_at': '2024-01-01T00:00:00.000Z',
  };
}

void main() {
  group('EducatorLogic forum engagement', () {
    late FakeEducatorForumPostsDataSource postsDataSource;
    late FakeEducatorForumEngagementDataSource engagementDataSource;
    late FakeEducatorProfileDataSource educatorProfileDataSource;
    late FakeProfilesDataSource profilesDataSource;
    late EducatorLogic logic;

    setUp(() {
      postsDataSource = FakeEducatorForumPostsDataSource()
        ..currentUserId = 'educator-1';
      engagementDataSource = FakeEducatorForumEngagementDataSource()
        ..currentUserId = 'educator-1';
      educatorProfileDataSource = FakeEducatorProfileDataSource();
      profilesDataSource = FakeProfilesDataSource();
      logic = EducatorLogic(
        educatorForumPostsDataSource: postsDataSource,
        educatorForumEngagementDataSource: engagementDataSource,
        educatorProfileDataSource: educatorProfileDataSource,
        profilesDataSource: profilesDataSource,
      );
    });

    group('fetchForumPostsWithEngagementForEducator', () {
      test('returns posts with zeroed engagement when none exists', () async {
        postsDataSource.rows.add(_post());

        final results =
            await logic.fetchForumPostsWithEngagementForEducator('educator-1');

        expect(results, hasLength(1));
        expect(results.single.likeCount, 0);
        expect(results.single.commentCount, 0);
        expect(results.single.isLikedByCurrentUser, isFalse);
      });

      test('tallies like and comment counts, and marks liked-by-me', () async {
        postsDataSource.rows.add(_post());
        engagementDataSource.likes.addAll([
          {'forum_post_id': 'post-a', 'user_id': 'educator-1'},
          {'forum_post_id': 'post-a', 'user_id': 'reader-1'},
        ]);
        engagementDataSource.comments.add(
          _comment(userId: 'reader-1'),
        );

        final results =
            await logic.fetchForumPostsWithEngagementForEducator('educator-1');

        expect(results.single.likeCount, 2);
        expect(results.single.commentCount, 1);
        expect(results.single.isLikedByCurrentUser, isTrue);
      });

      test('still returns results when signed out (does not gate the fetch)',
          () async {
        postsDataSource.rows.add(_post());
        engagementDataSource.currentUserId = null;

        final results =
            await logic.fetchForumPostsWithEngagementForEducator('educator-1');

        expect(results, hasLength(1));
        expect(results.single.isLikedByCurrentUser, isFalse);
      });
    });

    group('toggleForumPostLike', () {
      test('throws when signed out', () {
        engagementDataSource.currentUserId = null;
        expect(
          () => logic.toggleForumPostLike('post-a'),
          throwsException,
        );
      });

      test('likes when not already liked', () async {
        await logic.toggleForumPostLike('post-a');

        expect(engagementDataSource.likes, hasLength(1));
        expect(engagementDataSource.likes.single['user_id'], 'educator-1');
      });

      test('unlikes when already liked', () async {
        engagementDataSource.likes.add({
          'forum_post_id': 'post-a',
          'user_id': 'educator-1',
        });

        await logic.toggleForumPostLike('post-a');

        expect(engagementDataSource.likes, isEmpty);
      });
    });

    group('fetchForumPostComments', () {
      test('resolves an educator-authored comment via the educators table',
          () async {
        educatorProfileDataSource.rows.add({
          'id': 'educator-2',
          'username': 'bob',
        });
        engagementDataSource.comments.add(_comment(userId: 'educator-2'));

        final comments = await logic.fetchForumPostComments('post-a');

        expect(comments.single.authorUsername, 'bob');
      });

      test('resolves a Notes-user-authored comment via profiles', () async {
        profilesDataSource.rows.add({
          'id': 'notes-user-1',
          'username': 'alice',
        });
        engagementDataSource.comments.add(_comment(userId: 'notes-user-1'));

        final comments = await logic.fetchForumPostComments('post-a');

        expect(comments.single.authorUsername, 'alice');
      });

      test('falls back to unknown when neither table resolves the author',
          () async {
        engagementDataSource.comments.add(_comment(userId: 'ghost'));

        final comments = await logic.fetchForumPostComments('post-a');

        expect(comments.single.authorUsername, 'unknown');
      });
    });

    group('addForumPostComment', () {
      test('throws when signed out', () {
        engagementDataSource.currentUserId = null;
        expect(
          () => logic.addForumPostComment(
            forumPostId: 'post-a',
            content: 'hi',
          ),
          throwsException,
        );
      });

      test('throws when content is blank', () {
        expect(
          () => logic.addForumPostComment(
            forumPostId: 'post-a',
            content: '   ',
          ),
          throwsException,
        );
      });

      test('throws when content exceeds 500 characters', () {
        expect(
          () => logic.addForumPostComment(
            forumPostId: 'post-a',
            content: 'a' * 501,
          ),
          throwsException,
        );
      });

      test('inserts a trimmed comment for the current user', () async {
        await logic.addForumPostComment(
          forumPostId: 'post-a',
          content: '  hello  ',
        );

        expect(engagementDataSource.comments.single['content'], 'hello');
        expect(engagementDataSource.comments.single['user_id'], 'educator-1');
      });
    });

    group('fetchForumPostWithEngagementById', () {
      test('throws when no post exists for the id', () {
        expect(
          () => logic.fetchForumPostWithEngagementById('missing'),
          throwsException,
        );
      });

      test('returns the post with correct like/comment counts', () async {
        postsDataSource.rows.add(_post());
        engagementDataSource.likes.addAll([
          {'forum_post_id': 'post-a', 'user_id': 'educator-1'},
          {'forum_post_id': 'post-a', 'user_id': 'reader-1'},
        ]);
        engagementDataSource.comments.add(_comment(userId: 'reader-1'));

        final result = await logic.fetchForumPostWithEngagementById('post-a');

        expect(result.post.id, 'post-a');
        expect(result.likeCount, 2);
        expect(result.commentCount, 1);
        expect(result.isLikedByCurrentUser, isTrue);
      });

      test('is false for isLikedByCurrentUser when signed out', () async {
        postsDataSource.rows.add(_post());
        engagementDataSource.currentUserId = null;
        engagementDataSource.likes.add({
          'forum_post_id': 'post-a',
          'user_id': 'reader-1',
        });

        final result = await logic.fetchForumPostWithEngagementById('post-a');

        expect(result.likeCount, 1);
        expect(result.isLikedByCurrentUser, isFalse);
      });
    });
  });
}
