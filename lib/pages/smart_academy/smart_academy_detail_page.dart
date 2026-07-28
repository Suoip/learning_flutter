import 'package:flutter/material.dart';

import '../../resources_and_services/educator_logic.dart';
import 'educator_channel_page.dart';
import 'expandable_text.dart';
import 'forum_post_comments_sheet.dart';
import 'smart_academy_entry.dart';

/// Full detail page for a single SmartAcademy entry - a video (with a
/// placeholder player) or a forum post (text only). Both share the same
/// title/author/description structure, so one page serves both kinds
/// rather than duplicating near-identical layouts. Forum entries gain live
/// like/comment engagement (reusing the exact same logic/widgets already
/// built for `EducatorChannelPage` - `forumPostId` alone is enough, no
/// educator-scoping needed); videos stay a static read-only preview, since
/// there's no engagement or real playback to add yet.
class SmartAcademyDetailPage extends StatefulWidget {
  const SmartAcademyDetailPage({super.key, required this.entry});

  final SmartAcademyEntry entry;

  @override
  State<SmartAcademyDetailPage> createState() => _SmartAcademyDetailPageState();
}

class _SmartAcademyDetailPageState extends State<SmartAcademyDetailPage> {
  final EducatorLogic _logic = EducatorLogic();

  bool get _isVideo => widget.entry.kind == SmartAcademyEntryKind.video;

  ForumPostWithEngagement? _engagement;
  bool _loadingEngagement = false;
  String? _engagementError;

  @override
  void initState() {
    super.initState();
    if (!_isVideo) _loadEngagement();
  }

  Future<void> _loadEngagement() async {
    setState(() {
      _loadingEngagement = true;
      _engagementError = null;
    });

    try {
      final engagement = await _logic.fetchForumPostWithEngagementById(
        widget.entry.id,
      );
      if (!mounted) return;
      setState(() {
        _engagement = engagement;
        _loadingEngagement = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingEngagement = false;
        _engagementError = EducatorLogic.userMessageForError(
          error,
          fallback: 'Could not load engagement.',
        );
      });
    }
  }

  Future<void> _toggleLike() async {
    if (_logic.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to like posts.')),
      );
      return;
    }

    try {
      await _logic.toggleForumPostLike(widget.entry.id);
      await _loadEngagement();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            EducatorLogic.userMessageForError(
              error,
              fallback: 'Could not update your like.',
            ),
          ),
        ),
      );
    }
  }

  void _openComments() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ForumPostCommentsSheet(
        logic: _logic,
        forumPostId: widget.entry.id,
      ),
    ).then((_) => _loadEngagement());
  }

  void _openAuthorChannel() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            EducatorChannelPage(educatorId: widget.entry.educatorId),
      ),
    );
  }

  Widget _buildEngagementRow(ColorScheme cs) {
    if (_loadingEngagement) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_engagementError != null) {
      return Text(
        _engagementError!,
        style: TextStyle(color: cs.error),
      );
    }

    final engagement = _engagement;
    if (engagement == null) return const SizedBox.shrink();

    return Row(
      children: [
        IconButton(
          tooltip: engagement.isLikedByCurrentUser ? 'Unlike' : 'Like',
          onPressed: _toggleLike,
          icon: Icon(
            engagement.isLikedByCurrentUser
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            color: engagement.isLikedByCurrentUser
                ? Colors.pink.shade500
                : cs.onSurfaceVariant,
          ),
        ),
        Text('${engagement.likeCount}'),
        const SizedBox(width: 10),
        IconButton(
          tooltip: 'Comments',
          onPressed: _openComments,
          icon: const Icon(Icons.mode_comment_outlined),
        ),
        Text('${engagement.commentCount}'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final entry = widget.entry;

    return Scaffold(
      appBar: AppBar(title: Text(_isVideo ? 'Video' : 'Forum post')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isVideo) ...[
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
                InkWell(
                  onTap: _openAuthorChannel,
                  child: Text(
                    'by ${entry.authorName}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 20),
                Text(
                  _isVideo ? 'Description' : 'Post',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ExpandableText(text: entry.description, trimLines: 4),
                if (!_isVideo) ...[
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  _buildEngagementRow(cs),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
