import 'package:flutter/material.dart';

import '../../resources_and_services/notes_logic.dart';
import '../../theme/app_colors.dart';

class NoteListTile extends StatelessWidget {
  const NoteListTile({
    super.key,
    required this.note,
    required this.isPublished,
    required this.onTap,
    required this.onToggleFavorite,
    required this.onTogglePin,
    required this.onTogglePublish,
    required this.onConfirmDismiss,
  });

  final NoteItem note;
  final bool isPublished;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final VoidCallback onTogglePin;
  final VoidCallback onTogglePublish;
  final Future<bool?> Function() onConfirmDismiss;

  @override
  Widget build(BuildContext context) {
    final preview = note.content.trim().isEmpty
        ? 'No additional text'
        : note.content.trim().replaceAll('\n', ' ');
    final updatedText = NotesLogic.formatUpdatedTime(note.updatedAt);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Dismissible(
      key: ValueKey(note.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: cs.errorContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(Icons.delete_outline_rounded, color: cs.onErrorContainer),
      ),
      confirmDismiss: (_) => onConfirmDismiss(),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          if (note.isPinned) ...[
                            Icon(
                              Icons.push_pin_rounded,
                              size: 16,
                              color: cs.primary,
                            ),
                            const SizedBox(width: 6),
                          ],
                          Expanded(
                            child: Text(
                              note.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: note.isFavorite ? 'Unfavorite' : 'Favorite',
                      onPressed: onToggleFavorite,
                      icon: Icon(
                        note.isFavorite
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: note.isFavorite
                            ? AppColors.favoriteAccent
                            : cs.onSurfaceVariant,
                      ),
                    ),
                    IconButton(
                      tooltip: note.isPinned ? 'Unpin' : 'Pin',
                      onPressed: onTogglePin,
                      icon: Icon(
                        note.isPinned
                            ? Icons.push_pin_rounded
                            : Icons.push_pin_outlined,
                        color: note.isPinned ? cs.primary : cs.onSurfaceVariant,
                      ),
                    ),
                    IconButton(
                      tooltip: isPublished
                          ? 'Unpublish from friends'
                          : 'Publish to friends',
                      onPressed: onTogglePublish,
                      icon: Icon(
                        isPublished
                            ? Icons.public_rounded
                            : Icons.public_outlined,
                        color: isPublished ? cs.tertiary : cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Text(updatedText, style: theme.textTheme.bodySmall),
                const SizedBox(height: 8),
                Text(
                  preview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
                if (isPublished) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: cs.tertiaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Shared with friends',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: cs.onTertiaryContainer,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
