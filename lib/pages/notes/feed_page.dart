import 'package:flutter/material.dart';

import '../../resources_and_services/notes_logic.dart';
import 'feed_post_detail_page.dart';
import 'feed_tab.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final NotesLogic _logic = NotesLogic();

  List<SharedNoteFeedItem> _feed = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  String _friendly(Object error, {String fallback = 'Something went wrong.'}) {
    return NotesLogic.userMessageForError(error, fallback: fallback);
  }

  Future<void> _loadFeed() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final feed = await _logic.fetchFriendsFeed();
      if (!mounted) return;
      setState(() {
        _feed = feed;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _friendly(error, fallback: 'Could not load your feed.');
      });
    }
  }

  Future<void> _toggleLike(SharedNoteFeedItem item) async {
    try {
      await _logic.toggleFeedLike(item.id);
      await _loadFeed();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(_friendly(error, fallback: 'Could not update like.'))),
      );
    }
  }

  Future<void> _openPostDetail(SharedNoteFeedItem item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FeedPostDetailPage(
          logic: _logic,
          item: item,
        ),
      ),
    );
    if (!mounted) return;
    await _loadFeed();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      final cs = Theme.of(context).colorScheme;
      return RefreshIndicator(
        onRefresh: _loadFeed,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              color: cs.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Failed to load feed:\n$_error',
                  style: TextStyle(color: cs.onErrorContainer),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return FeedTab(
      feed: _feed,
      onToggleLike: _toggleLike,
      onOpenComments: _openPostDetail,
      onRefresh: _loadFeed,
    );
  }
}
