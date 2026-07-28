import 'package:flutter_test/flutter_test.dart';
import 'package:new_project/resources_and_services/educator_logic.dart';

import 'fakes/fake_educator_profile_data_source.dart';
import 'fakes/fake_educator_video_engagement_data_source.dart';
import 'fakes/fake_educator_videos_data_source.dart';
import 'fakes/fake_profiles_data_source.dart';

Map<String, dynamic> _video({
  String id = 'video-a',
  String educatorId = 'educator-1',
}) {
  return {
    'id': id,
    'educator_id': educatorId,
    'title': 'Video',
    'description': '',
    'duration_label': null,
    'updated_at': '2024-01-01T00:00:00.000Z',
    'created_at': '2024-01-01T00:00:00.000Z',
  };
}

Map<String, dynamic> _comment({
  String id = 'c1',
  String videoId = 'video-a',
  required String userId,
}) {
  return {
    'id': id,
    'video_id': videoId,
    'user_id': userId,
    'content': 'hi',
    'created_at': '2024-01-01T00:00:00.000Z',
  };
}

void main() {
  group('EducatorLogic video engagement', () {
    late FakeEducatorVideosDataSource videosDataSource;
    late FakeEducatorVideoEngagementDataSource engagementDataSource;
    late FakeEducatorProfileDataSource educatorProfileDataSource;
    late FakeProfilesDataSource profilesDataSource;
    late EducatorLogic logic;

    setUp(() {
      videosDataSource = FakeEducatorVideosDataSource()
        ..currentUserId = 'educator-1';
      engagementDataSource = FakeEducatorVideoEngagementDataSource()
        ..currentUserId = 'educator-1';
      educatorProfileDataSource = FakeEducatorProfileDataSource();
      profilesDataSource = FakeProfilesDataSource();
      logic = EducatorLogic(
        educatorVideosDataSource: videosDataSource,
        educatorVideoEngagementDataSource: engagementDataSource,
        educatorProfileDataSource: educatorProfileDataSource,
        profilesDataSource: profilesDataSource,
      );
    });

    group('fetchVideosWithEngagementForEducator', () {
      test('returns videos with zeroed engagement when none exists', () async {
        videosDataSource.rows.add(_video());

        final results =
            await logic.fetchVideosWithEngagementForEducator('educator-1');

        expect(results, hasLength(1));
        expect(results.single.likeCount, 0);
        expect(results.single.commentCount, 0);
        expect(results.single.isLikedByCurrentUser, isFalse);
      });

      test('tallies like and comment counts, and marks liked-by-me', () async {
        videosDataSource.rows.add(_video());
        engagementDataSource.likes.addAll([
          {'video_id': 'video-a', 'user_id': 'educator-1'},
          {'video_id': 'video-a', 'user_id': 'reader-1'},
        ]);
        engagementDataSource.comments.add(_comment(userId: 'reader-1'));

        final results =
            await logic.fetchVideosWithEngagementForEducator('educator-1');

        expect(results.single.likeCount, 2);
        expect(results.single.commentCount, 1);
        expect(results.single.isLikedByCurrentUser, isTrue);
      });

      test('still returns results when signed out (does not gate the fetch)',
          () async {
        videosDataSource.rows.add(_video());
        engagementDataSource.currentUserId = null;

        final results =
            await logic.fetchVideosWithEngagementForEducator('educator-1');

        expect(results, hasLength(1));
        expect(results.single.isLikedByCurrentUser, isFalse);
      });
    });

    group('toggleVideoLike', () {
      test('throws when signed out', () {
        engagementDataSource.currentUserId = null;
        expect(
          () => logic.toggleVideoLike('video-a'),
          throwsException,
        );
      });

      test('likes when not already liked', () async {
        await logic.toggleVideoLike('video-a');

        expect(engagementDataSource.likes, hasLength(1));
        expect(engagementDataSource.likes.single['user_id'], 'educator-1');
      });

      test('unlikes when already liked', () async {
        engagementDataSource.likes.add({
          'video_id': 'video-a',
          'user_id': 'educator-1',
        });

        await logic.toggleVideoLike('video-a');

        expect(engagementDataSource.likes, isEmpty);
      });
    });

    group('fetchVideoComments', () {
      test('resolves an educator-authored comment via the educators table',
          () async {
        educatorProfileDataSource.rows.add({
          'id': 'educator-2',
          'username': 'bob',
        });
        engagementDataSource.comments.add(_comment(userId: 'educator-2'));

        final comments = await logic.fetchVideoComments('video-a');

        expect(comments.single.authorUsername, 'bob');
      });

      test('resolves a Notes-user-authored comment via profiles', () async {
        profilesDataSource.rows.add({
          'id': 'notes-user-1',
          'username': 'alice',
        });
        engagementDataSource.comments.add(_comment(userId: 'notes-user-1'));

        final comments = await logic.fetchVideoComments('video-a');

        expect(comments.single.authorUsername, 'alice');
      });

      test('falls back to unknown when neither table resolves the author',
          () async {
        engagementDataSource.comments.add(_comment(userId: 'ghost'));

        final comments = await logic.fetchVideoComments('video-a');

        expect(comments.single.authorUsername, 'unknown');
      });
    });

    group('addVideoComment', () {
      test('throws when signed out', () {
        engagementDataSource.currentUserId = null;
        expect(
          () => logic.addVideoComment(videoId: 'video-a', content: 'hi'),
          throwsException,
        );
      });

      test('throws when content is blank', () {
        expect(
          () => logic.addVideoComment(videoId: 'video-a', content: '   '),
          throwsException,
        );
      });

      test('throws when content exceeds 500 characters', () {
        expect(
          () => logic.addVideoComment(videoId: 'video-a', content: 'a' * 501),
          throwsException,
        );
      });

      test('inserts a trimmed comment for the current user', () async {
        await logic.addVideoComment(videoId: 'video-a', content: '  hello  ');

        expect(engagementDataSource.comments.single['content'], 'hello');
        expect(engagementDataSource.comments.single['user_id'], 'educator-1');
      });
    });

    group('fetchVideoWithEngagementById', () {
      test('throws when no video exists for the id', () {
        expect(
          () => logic.fetchVideoWithEngagementById('missing'),
          throwsException,
        );
      });

      test('returns the video with correct like/comment counts', () async {
        videosDataSource.rows.add(_video());
        engagementDataSource.likes.addAll([
          {'video_id': 'video-a', 'user_id': 'educator-1'},
          {'video_id': 'video-a', 'user_id': 'reader-1'},
        ]);
        engagementDataSource.comments.add(_comment(userId: 'reader-1'));

        final result = await logic.fetchVideoWithEngagementById('video-a');

        expect(result.video.id, 'video-a');
        expect(result.likeCount, 2);
        expect(result.commentCount, 1);
        expect(result.isLikedByCurrentUser, isTrue);
      });

      test('is false for isLikedByCurrentUser when signed out', () async {
        videosDataSource.rows.add(_video());
        engagementDataSource.currentUserId = null;
        engagementDataSource.likes.add({
          'video_id': 'video-a',
          'user_id': 'reader-1',
        });

        final result = await logic.fetchVideoWithEngagementById('video-a');

        expect(result.likeCount, 1);
        expect(result.isLikedByCurrentUser, isFalse);
      });
    });
  });
}
