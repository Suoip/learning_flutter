import 'package:flutter/material.dart';

/// Shared "nothing here yet" content for a whole-screen empty state (Notes
/// list, Feed) - not for smaller sub-section empty texts inside an
/// already-bounded card (e.g. Friends tab's "No friends yet."), which stay
/// as plain inline text since a full icon+card treatment there would look
/// nested/bloated rather than consistent.
class NotesEmptyState extends StatelessWidget {
  const NotesEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 40, color: cs.primary),
            const SizedBox(height: 12),
            Text(title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
