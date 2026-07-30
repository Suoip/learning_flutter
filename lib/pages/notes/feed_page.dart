import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../resources_and_services/notes_logic.dart';
import 'feed_post_detail_page.dart';
import 'feed_tab.dart';
import 'notes_error_banner.dart';
import 'notes_skeletons.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({
    super.key,
    required this.isActive,
    required this.onUnseenCountChanged,
  });

  /// Whether the Feed tab is currently the selected bottom-nav destination.
  /// The feed's own [State] stays alive across tab switches (it lives inside
  /// an `IndexedStack`), so a false-to-true transition is detected via
  /// [didUpdateWidget], not [initState].
  final bool isActive;
  final ValueChanged<int> onUnseenCountChanged;

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

  @override
  void didUpdateWidget(covariant FeedPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      _markSeen();
    }
  }

  Future<void> _markSeen() async {
    await _logic.markFeedSeenNow();
    if (!mounted) return;
    widget.onUnseenCountChanged(0);
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
      final results = await Future.wait([
        _logic.fetchFriendsFeed(),
        _logic.fetchFeedLastSeenAt(),
      ]);
      if (!mounted) return;
      final feed = results[0] as List<SharedNoteFeedItem>;
      final lastSeenAt = results[1] as DateTime?;
      setState(() {
        _feed = feed;
        _loading = false;
      });
      widget.onUnseenCountChanged(
        NotesLogic.countUnseenFeedItems(feed: feed, lastSeenAt: lastSeenAt),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _friendly(error, fallback: 'Could not load your feed.');
      });
    }
  }

  Future<void> _toggleLike(SharedNoteFeedItem item) async {
    final index = _feed.indexWhere((i) => i.id == item.id);
    if (index == -1) return;

    HapticFeedback.lightImpact();
    final wasLiked = item.isLikedByCurrentUser;
    setState(() {
      _feed[index] = item.copyWith(
        isLikedByCurrentUser: !wasLiked,
        likeCount: item.likeCount + (wasLiked ? -1 : 1),
      );
    });

    try {
      await _logic.toggleFeedLike(item.id);
    } catch (error) {
      if (!mounted) return;
      setState(() => _feed[index] = item);
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
    final String stateKey;
    final Widget child;
    if (_loading) {
      stateKey = 'loading';
      child = const FeedListSkeleton();
    } else if (_error != null) {
      stateKey = 'error';
      child = RefreshIndicator(
        onRefresh: _loadFeed,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            NotesErrorBanner(message: 'Failed to load feed:\n$_error'),
          ],
        ),
      );
    } else {
      stateKey = 'loaded';
      child = FeedTab(
        feed: _feed,
        onToggleLike: _toggleLike,
        onOpenComments: _openPostDetail,
        onRefresh: _loadFeed,
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: KeyedSubtree(key: ValueKey(stateKey), child: child),
    );
  }
}
