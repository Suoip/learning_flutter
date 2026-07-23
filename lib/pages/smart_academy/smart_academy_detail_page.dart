import 'package:flutter/material.dart';

import 'expandable_text.dart';
import 'smart_academy_entry.dart';

/// Full detail page for a single SmartAcademy entry - a video (with a
/// placeholder player) or a forum post (text only). Both share the same
/// title/author/description structure, so one page serves both kinds
/// rather than duplicating near-identical layouts.
class SmartAcademyDetailPage extends StatelessWidget {
  const SmartAcademyDetailPage({super.key, required this.entry});

  final SmartAcademyEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isVideo = entry.kind == SmartAcademyEntryKind.video;

    return Scaffold(
      appBar: AppBar(title: Text(isVideo ? 'Video' : 'Forum post')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isVideo) ...[
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.play_circle_fill_rounded,
                              size: 64,
                              color: cs.primary,
                            ),
                          ),
                        ),
                        if (entry.durationLabel != null)
                          Positioned(
                            right: 12,
                            bottom: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: cs.scrim.withValues(alpha: 0.72),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                entry.durationLabel!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.onSurface,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                Text(entry.title, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  'by ${entry.authorName}',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 20),
                Text(
                  isVideo ? 'Description' : 'Post',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ExpandableText(text: entry.description, trimLines: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
