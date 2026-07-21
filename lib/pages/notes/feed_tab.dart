import 'package:flutter/material.dart';

import '../../resources_and_services/notes_logic.dart';
import 'feed_item_card.dart';

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
    final cs = Theme.of(context).colorScheme;
    if (feed.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 70, 20, 120),
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side:
                    BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: const Padding(
                padding: EdgeInsets.all(22),
                child: Column(
                  children: [
                    Icon(Icons.dynamic_feed_outlined, size: 36),
                    SizedBox(height: 8),
                    Text(
                      'No shared notes yet',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'When your friends publish notes, they will appear here.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
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
