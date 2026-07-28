import 'package:flutter_test/flutter_test.dart';
import 'package:new_project/resources_and_services/educator_logic.dart';

import 'fakes/fake_educator_forum_posts_data_source.dart';

void main() {
  group('EducatorLogic forum post CRUD', () {
    late FakeEducatorForumPostsDataSource dataSource;
    late EducatorLogic logic;

    setUp(() {
      dataSource = FakeEducatorForumPostsDataSource()
        ..currentUserId = 'educator-1';
      logic = EducatorLogic(educatorForumPostsDataSource: dataSource);
    });

    group('fetchForumPostsForCurrentEducator', () {
      test('returns an empty list when signed out', () async {
        dataSource.currentUserId = null;
        final posts = await logic.fetchForumPostsForCurrentEducator();
        expect(posts, isEmpty);
      });

      test('only returns posts belonging to the current educator', () async {
        dataSource.rows.addAll([
          {
            'id': 'post-a',
            'educator_id': 'educator-1',
            'title': 'Mine',
            'description': '',
            'updated_at': '2024-01-01T00:00:00.000Z',
            'created_at': '2024-01-01T00:00:00.000Z',
          },
          {
            'id': 'post-b',
            'educator_id': 'educator-2',
            'title': "Someone else's",
            'description': '',
            'updated_at': '2024-01-01T00:00:00.000Z',
            'created_at': '2024-01-01T00:00:00.000Z',
          },
        ]);

        final posts = await logic.fetchForumPostsForCurrentEducator();

        expect(posts.map((p) => p.id), ['post-a']);
      });

      test('returns posts sorted newest-updated-first', () async {
        dataSource.rows.addAll([
          {
            'id': 'older',
            'educator_id': 'educator-1',
            'title': 'Older',
            'description': '',
            'updated_at': '2024-01-01T00:00:00.000Z',
            'created_at': '2024-01-01T00:00:00.000Z',
          },
          {
            'id': 'newer',
            'educator_id': 'educator-1',
            'title': 'Newer',
            'description': '',
            'updated_at': '2024-06-01T00:00:00.000Z',
            'created_at': '2024-06-01T00:00:00.000Z',
          },
        ]);

        final posts = await logic.fetchForumPostsForCurrentEducator();

        expect(posts.map((p) => p.id), ['newer', 'older']);
      });
    });

    group('fetchForumPostsForEducator', () {
      test('fetches by the given id regardless of the current session',
          () async {
        dataSource.rows.addAll([
          {
            'id': 'post-a',
            'educator_id': 'educator-1',
            'title': 'Mine',
            'description': '',
            'updated_at': '2024-01-01T00:00:00.000Z',
            'created_at': '2024-01-01T00:00:00.000Z',
          },
          {
            'id': 'post-b',
            'educator_id': 'educator-2',
            'title': "Someone else's",
            'description': '',
            'updated_at': '2024-01-01T00:00:00.000Z',
            'created_at': '2024-01-01T00:00:00.000Z',
          },
        ]);

        dataSource.currentUserId = null;
        final posts = await logic.fetchForumPostsForEducator('educator-2');

        expect(posts.map((p) => p.id), ['post-b']);
      });
    });

    group('createForumPost', () {
      test('throws when signed out', () {
        dataSource.currentUserId = null;
        expect(
          () => logic.createForumPost(title: 'Title', description: 'Desc'),
          throwsException,
        );
      });

      test('creates a trimmed post', () async {
        final post = await logic.createForumPost(
          title: '  Why does this rebuild?  ',
          description: '  Full post body here.  ',
        );

        expect(post.title, 'Why does this rebuild?');
        expect(post.description, 'Full post body here.');
        expect(dataSource.rows.single['educator_id'], 'educator-1');
      });
    });

    group('updateForumPost', () {
      test('updates title and description', () async {
        final created = await logic.createForumPost(
          title: 'Original',
          description: 'Original body',
        );

        await logic.updateForumPost(
          postId: created.id,
          title: 'Updated title',
          description: 'Updated body',
        );

        final posts = await logic.fetchForumPostsForCurrentEducator();
        expect(posts.single.title, 'Updated title');
        expect(posts.single.description, 'Updated body');
      });

      test('does nothing when the post id does not exist', () async {
        await expectLater(
          logic.updateForumPost(
            postId: 'nonexistent',
            title: 'x',
            description: 'y',
          ),
          completes,
        );
      });
    });

    group('deleteForumPost', () {
      test('removes the post', () async {
        final created = await logic.createForumPost(
          title: 'Delete me',
          description: '',
        );

        await logic.deleteForumPost(created.id);

        final posts = await logic.fetchForumPostsForCurrentEducator();
        expect(posts, isEmpty);
      });

      test('does nothing when the post id does not exist', () async {
        await expectLater(logic.deleteForumPost('nonexistent'), completes);
      });
    });

    group('fetchRecentForumPosts', () {
      test('maps rows across educators, including the embedded author',
          () async {
        dataSource.educators['educator-1'] = {
          'id': 'educator-1',
          'username': 'alice',
          'avatar_url': 'https://example.com/alice.png',
        };
        dataSource.educators['educator-2'] = {
          'id': 'educator-2',
          'username': 'bob',
        };
        dataSource.rows.addAll([
          {
            'id': 'post-a',
            'educator_id': 'educator-1',
            'title': "Alice's post",
            'description': '',
            'updated_at': '2024-01-01T00:00:00.000Z',
            'created_at': '2024-01-01T00:00:00.000Z',
          },
          {
            'id': 'post-b',
            'educator_id': 'educator-2',
            'title': "Bob's post",
            'description': '',
            'updated_at': '2024-06-01T00:00:00.000Z',
            'created_at': '2024-06-01T00:00:00.000Z',
          },
        ]);

        final results = await logic.fetchRecentForumPosts();

        expect(results, hasLength(2));
        expect(results.first.post.id, 'post-b');
        expect(results.first.educatorId, 'educator-2');
        expect(results.first.authorUsername, 'bob');
        expect(results.first.authorAvatarUrl, isNull);
        expect(results.last.authorUsername, 'alice');
        expect(results.last.authorAvatarUrl, 'https://example.com/alice.png');
      });

      test('respects the limit', () async {
        dataSource.educators['educator-1'] = {
          'id': 'educator-1',
          'username': 'alice',
        };
        dataSource.rows.addAll([
          {
            'id': 'post-a',
            'educator_id': 'educator-1',
            'title': 'A',
            'description': '',
            'updated_at': '2024-01-01T00:00:00.000Z',
            'created_at': '2024-01-01T00:00:00.000Z',
          },
          {
            'id': 'post-b',
            'educator_id': 'educator-1',
            'title': 'B',
            'description': '',
            'updated_at': '2024-06-01T00:00:00.000Z',
            'created_at': '2024-06-01T00:00:00.000Z',
          },
        ]);

        final results = await logic.fetchRecentForumPosts(limit: 1);

        expect(results, hasLength(1));
        expect(results.single.post.id, 'post-b');
      });
    });
  });
}
