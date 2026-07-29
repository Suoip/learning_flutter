import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../resources_and_services/notes_logic.dart';
import 'expandable_text.dart';
import 'profile_avatar.dart';

class FeedPostDetailPage extends StatefulWidget {
  const FeedPostDetailPage({
    super.key,
    required this.logic,
    required this.item,
  });

  final NotesLogic logic;
  final SharedNoteFeedItem item;

  @override
  State<FeedPostDetailPage> createState() => _FeedPostDetailPageState();
}

class _FeedPostDetailPageState extends State<FeedPostDetailPage> {
  final TextEditingController _commentController = TextEditingController();

  late bool _isLiked;
  late int _likeCount;
  late int _commentCount;
  List<FeedCommentItem> _comments = [];
  bool _loadingComments = true;
  bool _postingComment = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.item.isLikedByCurrentUser;
    _likeCount = widget.item.likeCount;
    _commentCount = widget.item.commentCount;
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String _friendly(Object error, {String fallback = 'Something went wrong.'}) {
    return NotesLogic.userMessageForError(error, fallback: fallback);
  }

  Future<void> _loadComments() async {
    setState(() {
      _loadingComments = true;
      _error = null;
    });
    try {
      final rows = await widget.logic.fetchFeedComments(widget.item.id);
      if (!mounted) return;
      setState(() {
        _comments = rows;
        _commentCount = rows.length;
        _loadingComments = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingComments = false;
        _error = _friendly(error, fallback: 'Could not load comments.');
      });
    }
  }

  Future<void> _toggleLike() async {
    try {
      await widget.logic.toggleFeedLike(widget.item.id);
      if (!mounted) return;
      setState(() {
        _isLiked = !_isLiked;
        _likeCount += _isLiked ? 1 : -1;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(_friendly(error, fallback: 'Could not update like.'))),
      );
    }
  }

  Future<void> _addComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty || _postingComment) return;

    setState(() {
      _postingComment = true;
      _error = null;
    });
    try {
      await widget.logic
          .addFeedComment(sharedNoteId: widget.item.id, content: content);
      _commentController.clear();
      await _loadComments();
      if (!mounted) return;
      setState(() {
        _postingComment = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _postingComment = false;
        _error = _friendly(error, fallback: 'Could not post comment.');
      });
    }
  }

  Widget _buildCommentsList(ColorScheme cs) {
    if (_loadingComments) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_comments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'No comments yet.',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
      );
    }

    return Column(
      children: _comments.map((comment) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: ProfileAvatar(
            username: comment.authorUsername,
            avatarUrl: comment.authorAvatarUrl,
            radius: 14,
          ),
          title: Text('@${comment.authorUsername}'),
          subtitle: Text(comment.content),
          trailing: Text(
            DateFormat('MMM d').format(comment.createdAt.toLocal()),
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final item = widget.item;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(title: const Text('Post')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 14),
            Text(item.title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 10),
            ExpandableText(
              text: item.content.isEmpty ? '(No content)' : item.content,
              trimLines: 4,
            ),
            const SizedBox(height: 14),
            Divider(color: cs.outlineVariant),
            const SizedBox(height: 6),
            Row(
              children: [
                IconButton(
                  tooltip: _isLiked ? 'Unlike' : 'Like',
                  onPressed: _toggleLike,
                  icon: Icon(
                    _isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color:
                        _isLiked ? Colors.pink.shade500 : cs.onSurfaceVariant,
                  ),
                ),
                Text('$_likeCount'),
              ],
            ),
            Divider(color: cs.outlineVariant),
            const SizedBox(height: 10),
            Text(
              'Comments ($_commentCount)',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            if (_error != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
              const SizedBox(height: 10),
            ],
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    minLines: 1,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Write a comment...',
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
            ),
            const SizedBox(height: 10),
            _buildCommentsList(cs),
          ],
        ),
      ),
    );
  }
}
