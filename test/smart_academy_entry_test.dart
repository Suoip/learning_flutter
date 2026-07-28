import 'package:flutter_test/flutter_test.dart';
import 'package:new_project/pages/smart_academy/smart_academy_entry.dart';

void main() {
  group('filterSmartAcademyEntries', () {
    const dartVideo = SmartAcademyEntry(
      id: 'v1',
      kind: SmartAcademyEntryKind.video,
      title: 'Dart Null Safety in 12 Minutes',
      authorName: 'Priya Raman',
      description: '',
      durationLabel: '12:34',
    );
    const flutterVideo = SmartAcademyEntry(
      id: 'v2',
      kind: SmartAcademyEntryKind.video,
      title: 'Flutter Layouts Explained',
      authorName: 'Diego Fuentes',
      description: '',
      durationLabel: '18:07',
    );
    const forumPost = SmartAcademyEntry(
      id: 'f1',
      kind: SmartAcademyEntryKind.forum,
      title: 'Why is my build slow?',
      authorName: 'jordan_codes',
      description: '',
    );
    final entries = [dartVideo, flutterVideo, forumPost];

    test('returns everything for an empty query', () {
      final result = filterSmartAcademyEntries(
        entries: entries,
        searchQuery: '',
      );
      expect(result.map((e) => e.id), ['v1', 'v2', 'f1']);
    });

    test('matches titles case-insensitively', () {
      final result = filterSmartAcademyEntries(
        entries: entries,
        searchQuery: 'FLUTTER',
      );
      expect(result.map((e) => e.id), ['v2']);
    });

    test('matches author names case-insensitively', () {
      final result = filterSmartAcademyEntries(
        entries: entries,
        searchQuery: 'jordan',
      );
      expect(result.map((e) => e.id), ['f1']);
    });

    test('trims surrounding whitespace before matching', () {
      final result = filterSmartAcademyEntries(
        entries: entries,
        searchQuery: '  dart  ',
      );
      expect(result.map((e) => e.id), ['v1']);
    });

    test('returns an empty list when nothing matches', () {
      final result = filterSmartAcademyEntries(
        entries: entries,
        searchQuery: 'nonexistent',
      );
      expect(result, isEmpty);
    });
  });
}
