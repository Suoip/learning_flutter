/// Distinguishes SmartAcademy hub entries that have an associated video from
/// text-only, forum-style entries.
enum SmartAcademyEntryKind { video, forum }

/// A single hub entry - a real educator-authored video (metadata only, no
/// file upload yet) or forum post. `educatorId` links back to the authoring
/// educator's public channel page.
class SmartAcademyEntry {
  const SmartAcademyEntry({
    required this.id,
    required this.kind,
    required this.title,
    required this.authorName,
    required this.educatorId,
    required this.description,
    this.durationLabel,
  });

  final String id;
  final SmartAcademyEntryKind kind;
  final String title;
  final String authorName;
  final String educatorId;
  final String description;

  /// Video-only, e.g. "12:34". Null for forum entries.
  final String? durationLabel;
}

/// Which hub section(s) to show. Since Videos and Forum are already kept as
/// two separate lists/sections (a deliberate PR #18 decision, not merged
/// into one feed), this only decides which section(s) render - it doesn't
/// re-tag entries by kind.
enum SmartAcademyHubFilter { all, videos, forum }

/// Matches if [searchQuery] is empty, or if it's contained (case-insensitive)
/// in an entry's title or author name.
List<SmartAcademyEntry> filterSmartAcademyEntries({
  required List<SmartAcademyEntry> entries,
  required String searchQuery,
}) {
  final query = searchQuery.trim().toLowerCase();
  if (query.isEmpty) return entries;

  return entries.where((entry) {
    return entry.title.toLowerCase().contains(query) ||
        entry.authorName.toLowerCase().contains(query);
  }).toList();
}
