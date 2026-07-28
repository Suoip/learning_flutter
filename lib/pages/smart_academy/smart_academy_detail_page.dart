import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../resources_and_services/educator_logic.dart';
import 'educator_channel_page.dart';
import 'educator_profile_avatar.dart';
import 'expandable_text.dart';
import 'smart_academy_entry.dart';

/// A unified shape for rendering either a [VideoCommentItem] or a
/// [ForumPostCommentItem] without the widget tree needing to branch on kind -
/// both already carry the exact same fields.
class _CommentDisplay {
  const _CommentDisplay({
    required this.authorUsername,
    required this.authorAvatarUrl,
    required this.content,
    required this.createdAt,
  });

  final String authorUsername;
  final String? authorAvatarUrl;
  final String content;
  final DateTime createdAt;
}

/// Full detail page for a single SmartAcademy entry - a video (with a
/// placeholder player) or a forum post (text only). Both share the same
/// title/author/description structure, so one page serves both kinds rather
/// than duplicating near-identical layouts. Both kinds now also share the
/// same like + inline, scroll-to-see comments section, YouTube-watch-page
/// style - no modal sheet, the comment list is just part of the same
/// scrollable column.
class SmartAcademyDetailPage extends StatefulWidget {
  const SmartAcademyDetailPage({super.key, required this.entry});

  final SmartAcademyEntry entry;

  @override
  State<SmartAcademyDetailPage> createState() => _SmartAcademyDetailPageState();
}

class _SmartAcademyDetailPageState extends State<SmartAcademyDetailPage> {
  final EducatorLogic _logic = EducatorLogic();
  final TextEditingController _commentController = TextEditingController();

  bool get _isVideo => widget.entry.kind == SmartAcademyEntryKind.video;

  int _likeCount = 0;
  int _commentCount = 0;
  bool _isLiked = false;
  bool _loadingEngagement = true;
  String? _engagementError;

  List<_CommentDisplay> _comments = [];
  bool _loadingComments = true;
  String? _commentsError;
  bool _postingComment = false;

  @override
  void initState() {
    super.initState();
    _loadEngagement();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadEngagement() async {
    setState(() {
      _loadingEngagement = true;
      _engagementError = null;
    });

    try {
      final int likeCount;
      final int commentCount;
      final bool isLiked;
      if (_isVideo) {
        final engagement =
            await _logic.fetchVideoWithEngagementById(widget.entry.id);
        likeCount = engagement.likeCount;
        commentCount = engagement.commentCount;
        isLiked = engagement.isLikedByCurrentUser;
      } else {
        final engagement =
            await _logic.fetchForumPostWithEngagementById(widget.entry.id);
        likeCount = engagement.likeCount;
        commentCount = engagement.commentCount;
        isLiked = engagement.isLikedByCurrentUser;
      }
      if (!mounted) return;
      setState(() {
        _likeCount = likeCount;
        _commentCount = commentCount;
        _isLiked = isLiked;
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

  Future<void> _loadComments() async {
    setState(() {
      _loadingComments = true;
      _commentsError = null;
    });

    try {
      final List<_CommentDisplay> comments;
      if (_isVideo) {
        final rows = await _logic.fetchVideoComments(widget.entry.id);
        comments = rows
            .map(
              (comment) => _CommentDisplay(
                authorUsername: comment.authorUsername,
                authorAvatarUrl: comment.authorAvatarUrl,
                content: comment.content,
                createdAt: comment.createdAt,
              ),
            )
            .toList();
      } else {
        final rows = await _logic.fetchForumPostComments(widget.entry.id);
        comments = rows
            .map(
              (comment) => _CommentDisplay(
                authorUsername: comment.authorUsername,
                authorAvatarUrl: comment.authorAvatarUrl,
                content: comment.content,
                createdAt: comment.createdAt,
              ),
            )
            .toList();
      }
      if (!mounted) return;
      setState(() {
        _comments = comments;
        _loadingComments = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingComments = false;
        _commentsError = EducatorLogic.userMessageForError(
          error,
          fallback: 'Could not load comments.',
        );
      });
    }
  }

  Future<void> _toggleLike() async {
    if (_logic.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to like this.')),
      );
      return;
    }

    try {
      if (_isVideo) {
        await _logic.toggleVideoLike(widget.entry.id);
      } else {
        await _logic.toggleForumPostLike(widget.entry.id);
      }
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

  Future<void> _addComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty || _postingComment) return;

    setState(() {
      _postingComment = true;
    });

    try {
      if (_isVideo) {
        await _logic.addVideoComment(
            videoId: widget.entry.id, content: content);
      } else {
        await _logic.addForumPostComment(
          forumPostId: widget.entry.id,
          content: content,
        );
      }
      _commentController.clear();
      await Future.wait([_loadEngagement(), _loadComments()]);
      if (!mounted) return;
      setState(() {
        _postingComment = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _postingComment = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            EducatorLogic.userMessageForError(
              error,
              fallback: 'Could not post comment.',
            ),
          ),
        ),
      );
    }
  }

  void _openAuthorChannel() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            EducatorChannelPage(educatorId: widget.entry.educatorId),
      ),
    );
  }

  Widget _buildLikeRow(ColorScheme cs) {
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
      return Text(_engagementError!, style: TextStyle(color: cs.error));
    }

    return Row(
      children: [
        IconButton(
          tooltip: _isLiked ? 'Unlike' : 'Like',
          onPressed: _toggleLike,
          icon: Icon(
            _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: _isLiked ? Colors.pink.shade500 : cs.onSurfaceVariant,
          ),
        ),
        Text('$_likeCount'),
      ],
    );
  }

  Widget _buildCommentsSection(ThemeData theme) {
    final cs = theme.colorScheme;
    final signedIn = _logic.currentUser != null;

    Widget listContent;
    if (_loadingComments) {
      listContent = const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (_commentsError != null) {
      listContent = Text(_commentsError!, style: TextStyle(color: cs.error));
    } else if (_comments.isEmpty) {
      listContent = Text(
        'No comments yet.',
        style: TextStyle(color: cs.onSurfaceVariant),
      );
    } else {
      listContent = Column(
        children: [
          for (final comment in _comments)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EducatorProfileAvatar(
                    username: comment.authorUsername,
                    avatarUrl: comment.authorAvatarUrl,
                    radius: 16,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '@${comment.authorUsername}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('MMM d').format(
                                comment.createdAt.toLocal(),
                              ),
                              style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(comment.content),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Comments ($_commentCount)', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        if (signedIn)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Add a comment...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _postingComment ? null : _addComment,
                child: _postingComment
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Post'),
              ),
            ],
          )
        else
          Text(
            'Sign in to comment.',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
        const SizedBox(height: 16),
        listContent,
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
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                _buildLikeRow(cs),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 16),
                _buildCommentsSection(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
