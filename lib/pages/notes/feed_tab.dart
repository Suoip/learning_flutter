import 'package:flutter/material.dart';

import '../../resources_and_services/notes_logic.dart';
import 'feed_item_card.dart';
import 'notes_empty_state.dart';

class FeedTab extends StatelessWidget {
  const FeedTab({
    super.key,
    required this.feed,
    required this.onToggleLike,
    required this.onOpenComments,
    required this.onRefresh,
  });

  final List<SharedNoteFeedItem> feed;
  final ValueChanged<SharedNoteFeedItem> onToggleLike;
  final ValueChanged<SharedNoteFeedItem> onOpenComments;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (feed.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 70, 20, 120),
          children: const [
            NotesEmptyState(
              icon: Icons.dynamic_feed_outlined,
              title: 'No shared notes yet',
              subtitle:
                  'When your friends publish notes, they will appear here.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        itemCount: feed.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = feed[index];
          return FeedItemCard(
            item: item,
            onToggleLike: () => onToggleLike(item),
            onOpenComments: () => onOpenComments(item),
          );
        },
      ),
    );
  }
}
