import 'package:flutter_test/flutter_test.dart';
import 'package:new_project/resources_and_services/educator_logic.dart';

import 'fakes/fake_educator_videos_data_source.dart';

void main() {
  group('EducatorLogic video CRUD', () {
    late FakeEducatorVideosDataSource dataSource;
    late EducatorLogic logic;

    setUp(() {
      dataSource = FakeEducatorVideosDataSource()..currentUserId = 'educator-1';
      logic = EducatorLogic(educatorVideosDataSource: dataSource);
    });

    group('fetchVideosForCurrentEducator', () {
      test('returns an empty list when signed out', () async {
        dataSource.currentUserId = null;
        final videos = await logic.fetchVideosForCurrentEducator();
        expect(videos, isEmpty);
      });

      test('only returns videos belonging to the current educator', () async {
        dataSource.rows.addAll([
          {
            'id': 'video-a',
            'educator_id': 'educator-1',
            'title': 'Mine',
            'description': '',
            'duration_label': null,
            'updated_at': '2024-01-01T00:00:00.000Z',
            'created_at': '2024-01-01T00:00:00.000Z',
          },
          {
            'id': 'video-b',
            'educator_id': 'educator-2',
            'title': "Someone else's",
            'description': '',
            'duration_label': null,
            'updated_at': '2024-01-01T00:00:00.000Z',
            'created_at': '2024-01-01T00:00:00.000Z',
          },
        ]);

        final videos = await logic.fetchVideosForCurrentEducator();

        expect(videos.map((v) => v.id), ['video-a']);
      });

      test('returns videos sorted newest-updated-first', () async {
        dataSource.rows.addAll([
          {
            'id': 'older',
            'educator_id': 'educator-1',
            'title': 'Older',
            'description': '',
            'duration_label': null,
            'updated_at': '2024-01-01T00:00:00.000Z',
            'created_at': '2024-01-01T00:00:00.000Z',
          },
          {
            'id': 'newer',
            'educator_id': 'educator-1',
            'title': 'Newer',
            'description': '',
            'duration_label': null,
            'updated_at': '2024-06-01T00:00:00.000Z',
            'created_at': '2024-06-01T00:00:00.000Z',
          },
        ]);

        final videos = await logic.fetchVideosForCurrentEducator();

        expect(videos.map((v) => v.id), ['newer', 'older']);
      });
    });

    group('createVideo', () {
      test('throws when signed out', () {
        dataSource.currentUserId = null;
        expect(
          () => logic.createVideo(title: 'Title', description: 'Desc'),
          throwsException,
        );
      });

      test('creates a trimmed video with a null duration when omitted',
          () async {
        final video = await logic.createVideo(
          title: '  Dart Basics  ',
          description: '  Intro to Dart  ',
        );

        expect(video.title, 'Dart Basics');
        expect(video.description, 'Intro to Dart');
        expect(video.durationLabel, isNull);
        expect(dataSource.rows.single['educator_id'], 'educator-1');
      });

      test('stores a trimmed duration label when provided', () async {
        final video = await logic.createVideo(
          title: 'Title',
          description: 'Desc',
          durationLabel: '  12:34  ',
        );

        expect(video.durationLabel, '12:34');
      });

      test('stores a null duration when given an empty/blank string', () async {
        final video = await logic.createVideo(
          title: 'Title',
          description: 'Desc',
          durationLabel: '   ',
        );

        expect(video.durationLabel, isNull);
      });
    });

    group('updateVideo', () {
      test('updates title, description, and duration label', () async {
        final created = await logic.createVideo(
          title: 'Original',
          description: 'Original description',
        );

        await logic.updateVideo(
          videoId: created.id,
          title: 'Updated title',
          description: 'Updated description',
          durationLabel: '05:00',
        );

        final videos = await logic.fetchVideosForCurrentEducator();
        expect(videos.single.title, 'Updated title');
        expect(videos.single.description, 'Updated description');
        expect(videos.single.durationLabel, '05:00');
      });

      test('does nothing when the video id does not exist', () async {
        await expectLater(
          logic.updateVideo(
            videoId: 'nonexistent',
            title: 'x',
            description: 'y',
          ),
          completes,
        );
      });
    });

    group('deleteVideo', () {
      test('removes the video', () async {
        final created = await logic.createVideo(
          title: 'Delete me',
          description: '',
        );

        await logic.deleteVideo(created.id);

        final videos = await logic.fetchVideosForCurrentEducator();
        expect(videos, isEmpty);
      });

      test('does nothing when the video id does not exist', () async {
        await expectLater(logic.deleteVideo('nonexistent'), completes);
      });
    });
  });
}
