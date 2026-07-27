import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../resources_and_services/educator_logic.dart';
import 'educator_profile_avatar.dart';

/// Comments on one forum post - readable by anyone (comments are publicly
/// readable, same as the post itself), but the compose row only appears
/// when signed in. Any signed-in account (Notes user or educator) can
/// comment, so `ForumPostCommentItem.authorUsername` may have come from
/// either table - see `EducatorLogic.fetchForumPostComments`.
class ForumPostCommentsSheet extends StatefulWidget {
  const ForumPostCommentsSheet({
    super.key,
    required this.logic,
    required this.forumPostId,
  });

  final EducatorLogic logic;
  final String forumPostId;

  @override
  State<ForumPostCommentsSheet> createState() => _ForumPostCommentsSheetState();
}

class _ForumPostCommentsSheetState extends State<ForumPostCommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  List<ForumPostCommentItem> _comments = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String _friendly(Object error, {String fallback = 'Something went wrong.'}) {
    return EducatorLogic.userMessageForError(error, fallback: fallback);
  }

  Future<void> _loadComments() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final comments =
          await widget.logic.fetchForumPostComments(widget.forumPostId);
      if (!mounted) return;
      setState(() {
        _comments = comments;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _friendly(error, fallback: 'Could not load comments.');
      });
    }
  }

  Future<void> _addComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty || _saving) return;

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.logic.addForumPostComment(
        forumPostId: widget.forumPostId,
        content: content,
      );
      _commentController.clear();
      await _loadComments();
      if (!mounted) return;
      setState(() {
        _saving = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = _friendly(error, fallback: 'Could not post comment.');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final signedIn = widget.logic.currentUser != null;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Comments',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            if (_error != null)
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
            const SizedBox(height: 8),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              )
            else if (_comments.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'No comments yet.',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _comments.length,
                  itemBuilder: (context, index) {
                    final comment = _comments[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: EducatorProfileAvatar(
                        username: comment.authorUsername,
                        avatarUrl: comment.authorAvatarUrl,
                        radius: 14,
                      ),
                      title: Text('@${comment.authorUsername}'),
                      subtitle: Text(comment.content),
                      trailing: Text(
                        DateFormat('MMM d').format(comment.createdAt.toLocal()),
                        style:
                            TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 6),
            if (signedIn)
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
                    onPressed: _saving ? null : _addComment,
                    child: _saving
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
          ],
        ),
      ),
    );
  }
}
