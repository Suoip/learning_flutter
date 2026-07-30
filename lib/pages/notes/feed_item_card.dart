import 'package:flutter/material.dart';

import '../../resources_and_services/notes_logic.dart';
import 'pop_on_change.dart';
import 'profile_avatar.dart';

class FeedItemCard extends StatelessWidget {
  const FeedItemCard({
    super.key,
    required this.item,
    required this.onToggleLike,
    required this.onOpenComments,
    required this.onOpenLikedBy,
  });

  final SharedNoteFeedItem item;
  final VoidCallback onToggleLike;
  final VoidCallback onOpenComments;
  final VoidCallback onOpenLikedBy;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpenComments,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ProfileAvatar(
                    username: item.authorUsername,
                    avatarUrl: item.authorAvatarUrl,
                    radius: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.isOwnPost ? 'You' : '@${item.authorUsername}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          NotesLogic.formatUpdatedTime(item.publishedAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.title,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(item.content.isEmpty ? '(No content)' : item.content),
              const SizedBox(height: 10),
              Row(
                children: [
                  IconButton(
                    tooltip: item.isLikedByCurrentUser ? 'Unlike' : 'Like',
                    onPressed: onToggleLike,
                    icon: PopOnChange(
                      active: item.isLikedByCurrentUser,
                      child: Icon(
                        item.isLikedByCurrentUser
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: item.isLikedByCurrentUser
                            ? Colors.pink.shade500
                            : cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: onOpenLikedBy,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        '${item.likeCount}',
                        key: ValueKey(item.likeCount),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    tooltip: 'Comments',
                    onPressed: onOpenComments,
                    icon: const Icon(Icons.mode_comment_outlined),
                  ),
                  Text('${item.commentCount}'),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Read-only',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: cs.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
