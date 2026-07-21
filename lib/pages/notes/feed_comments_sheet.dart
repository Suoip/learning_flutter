import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../resources_and_services/notes_logic.dart';
import 'profile_avatar.dart';

class FeedCommentsSheet extends StatefulWidget {
  const FeedCommentsSheet({
    super.key,
    required this.logic,
    required this.item,
  });

  final NotesLogic logic;
  final SharedNoteFeedItem item;

  @override
  State<FeedCommentsSheet> createState() => _FeedCommentsSheetState();
}

class _FeedCommentsSheetState extends State<FeedCommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  List<FeedCommentItem> _comments = [];
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
    return NotesLogic.userMessageForError(error, fallback: fallback);
  }

  Future<void> _loadComments() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await widget.logic.fetchFeedComments(widget.item.id);
      if (!mounted) return;
      setState(() {
        _comments = rows;
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
      await widget.logic
          .addFeedComment(sharedNoteId: widget.item.id, content: content);
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
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _comments.length,
                  itemBuilder: (context, index) {
                    final comment = _comments[index];
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
                        style:
                            TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 6),
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
            ),
          ],
        ),
      ),
    );
  }
}
