import 'package:flutter_test/flutter_test.dart';
import 'package:new_project/resources_and_services/notes_logic.dart';

import 'fakes/fake_notes_data_source.dart';

void main() {
  group('NotesLogic notes CRUD', () {
    late FakeNotesDataSource dataSource;
    late NotesLogic logic;

    setUp(() {
      dataSource = FakeNotesDataSource()..currentUserId = 'user-1';
      logic = NotesLogic(notesDataSource: dataSource);
    });

    group('fetchNotesForCurrentUser', () {
      test('returns an empty list when signed out', () async {
        dataSource.currentUserId = null;
        final notes = await logic.fetchNotesForCurrentUser();
        expect(notes, isEmpty);
      });

      test('only returns notes belonging to the current user', () async {
        dataSource.rows.addAll([
          {
            'id': 'note-a',
            'user_id': 'user-1',
            'title': 'Mine',
            'content': '',
            'updated_at': '2024-01-01T00:00:00.000Z',
            'created_at': '2024-01-01T00:00:00.000Z',
            'is_pinned': false,
            'is_favorite': false,
          },
          {
            'id': 'note-b',
            'user_id': 'user-2',
            'title': 'Someone else\'s',
            'content': '',
            'updated_at': '2024-01-01T00:00:00.000Z',
            'created_at': '2024-01-01T00:00:00.000Z',
            'is_pinned': false,
            'is_favorite': false,
          },
        ]);

        final notes = await logic.fetchNotesForCurrentUser();

        expect(notes.map((n) => n.id), ['note-a']);
      });

      test('returns notes sorted pinned-first (delegates to sortNotes)',
          () async {
        dataSource.rows.addAll([
          {
            'id': 'older-pinned',
            'user_id': 'user-1',
            'title': 'Old but pinned',
            'content': '',
            'updated_at': '2024-01-01T00:00:00.000Z',
            'created_at': '2024-01-01T00:00:00.000Z',
            'is_pinned': true,
            'is_favorite': false,
          },
          {
            'id': 'newer-unpinned',
            'user_id': 'user-1',
            'title': 'New but unpinned',
            'content': '',
            'updated_at': '2024-06-01T00:00:00.000Z',
            'created_at': '2024-06-01T00:00:00.000Z',
            'is_pinned': false,
            'is_favorite': false,
          },
        ]);

        final notes = await logic.fetchNotesForCurrentUser();

        expect(notes.map((n) => n.id), ['older-pinned', 'newer-unpinned']);
      });
    });

    group('createNote', () {
      test('throws when signed out', () {
        dataSource.currentUserId = null;
        expect(() => logic.createNote('Title'), throwsException);
      });

      test('creates a trimmed, unpinned, unfavorited, empty-content note',
          () async {
        final note = await logic.createNote('  Groceries  ');

        expect(note.title, 'Groceries');
        expect(note.content, '');
        expect(note.isPinned, isFalse);
        expect(note.isFavorite, isFalse);
        expect(dataSource.rows.single['user_id'], 'user-1');
      });
    });

    group('updateNote', () {
      test('updates the title and content of an existing note', () async {
        final created = await logic.createNote('Original');

        await logic.updateNote(
          noteId: created.id,
          title: 'Updated title',
          content: 'Updated content',
        );

        final notes = await logic.fetchNotesForCurrentUser();
        expect(notes.single.title, 'Updated title');
        expect(notes.single.content, 'Updated content');
      });

      test('does nothing when the note id does not exist', () async {
        await expectLater(
          logic.updateNote(
            noteId: 'nonexistent',
            title: 'x',
            content: 'y',
          ),
          completes,
        );
      });
    });

    group('togglePin', () {
      test('flips isPinned from false to true and back', () async {
        final created = await logic.createNote('Pin me');
        expect(created.isPinned, isFalse);

        await logic.togglePin(created);
        var notes = await logic.fetchNotesForCurrentUser();
        expect(notes.single.isPinned, isTrue);

        await logic.togglePin(notes.single);
        notes = await logic.fetchNotesForCurrentUser();
        expect(notes.single.isPinned, isFalse);
      });
    });

    group('toggleFavorite', () {
      test('flips isFavorite from false to true and back', () async {
        final created = await logic.createNote('Favorite me');
        expect(created.isFavorite, isFalse);

        await logic.toggleFavorite(created);
        var notes = await logic.fetchNotesForCurrentUser();
        expect(notes.single.isFavorite, isTrue);

        await logic.toggleFavorite(notes.single);
        notes = await logic.fetchNotesForCurrentUser();
        expect(notes.single.isFavorite, isFalse);
      });
    });

    group('deleteNote', () {
      test('removes the note', () async {
        final created = await logic.createNote('Delete me');

        await logic.deleteNote(created.id);

        final notes = await logic.fetchNotesForCurrentUser();
        expect(notes, isEmpty);
      });

      test('does nothing when the note id does not exist', () async {
        await expectLater(logic.deleteNote('nonexistent'), completes);
      });
    });
  });
}
