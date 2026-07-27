import 'package:flutter/material.dart';

import '../../resources_and_services/educator_logic.dart';
import 'educator_dashboard_placeholder_page.dart';
import 'smart_academy_activation_required_page.dart';
import 'smart_academy_auth_page.dart';
import 'smart_academy_detail_page.dart';
import 'smart_academy_entry.dart';

/// SmartAcademy's main hub: a YouTube-style grid of placeholder education
/// videos, plus a separate forum-style section of text-only posts. Static
/// sample data only for now - no backend yet. Public/browsable without an
/// account; the AppBar action is the only entry point into educator auth.
class SmartAcademyPage extends StatefulWidget {
  const SmartAcademyPage({super.key});

  @override
  State<SmartAcademyPage> createState() => _SmartAcademyPageState();
}

class _SmartAcademyPageState extends State<SmartAcademyPage> {
  final EducatorLogic _logic = EducatorLogic();

  static int _videoColumnsForWidth(double width) {
    if (width >= 1600) return 5;
    if (width >= 1200) return 4;
    if (width >= 840) return 3;
    if (width >= 480) return 2;
    return 1;
  }

  void _openEntry(BuildContext context, SmartAcademyEntry entry) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SmartAcademyDetailPage(entry: entry),
      ),
    );
  }

  Future<void> _openEducatorArea() async {
    final user = _logic.currentUser;

    if (user == null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SmartAcademyAuthPage(
            onAuthenticated: () async {
              if (!mounted) return;
              Navigator.of(context).pop();
            },
          ),
        ),
      );
      if (!mounted) return;
      setState(() {});
      return;
    }

    if (!EducatorLogic.isUserEmailConfirmed(user)) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SmartAcademyActivationRequiredPage(
            onSignOut: () async {
              await _logic.signOut();
              if (!mounted) return;
              Navigator.of(context).pop();
            },
          ),
        ),
      );
      if (!mounted) return;
      setState(() {});
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EducatorDashboardPlaceholderPage(
          username: EducatorLogic.defaultUsernameForUser(user),
          onSignOut: () async {
            await _logic.signOut();
            if (!mounted) return;
            Navigator.of(context).pop();
          },
        ),
      ),
    );
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = _logic.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartAcademy'),
        actions: [
          IconButton(
            tooltip: user == null ? 'Educator sign in' : 'Educator dashboard',
            onPressed: _openEducatorArea,
            icon: Icon(
              user == null ? Icons.login_rounded : Icons.school_outlined,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Videos', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = _videoColumnsForWidth(constraints.maxWidth);
                const spacing = 12.0;
                final cardWidth =
                    (constraints.maxWidth - ((columns - 1) * spacing)) /
                        columns;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: sampleVideoEntries.map((entry) {
                    return SizedBox(
                      width: cardWidth,
                      child: _VideoCard(
                        entry: entry,
                        onTap: () => _openEntry(context, entry),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 32),
            Text('Forum', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Column(
              children: sampleForumEntries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ForumEntryCard(
                    entry: entry,
                    onTap: () => _openEntry(context, entry),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  const _VideoCard({required this.entry, required this.onTap});

  final SmartAcademyEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                children: [
                  Container(
                    color: cs.surfaceContainerHighest,
                    child: Center(
                      child: Icon(
                        Icons.play_circle_fill_rounded,
                        size: 40,
                        color: cs.primary,
                      ),
                    ),
                  ),
                  if (entry.durationLabel != null)
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
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
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(entry.authorName, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ForumEntryCard extends StatelessWidget {
  const _ForumEntryCard({required this.entry, required this.onTap});

  final SmartAcademyEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: cs.tertiary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.forum_rounded, color: cs.tertiary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'by ${entry.authorName}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
