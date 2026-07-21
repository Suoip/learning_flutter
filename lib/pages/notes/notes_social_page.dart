import 'package:flutter/material.dart';

import '../../resources_and_services/notes_logic.dart';
import 'feed_comments_sheet.dart';
import 'feed_tab.dart';
import 'friends_tab.dart';

class NotesSocialPage extends StatefulWidget {
  const NotesSocialPage({super.key});

  @override
  State<NotesSocialPage> createState() => _NotesSocialPageState();
}

class _NotesSocialPageState extends State<NotesSocialPage> {
  final NotesLogic _logic = NotesLogic();
  final TextEditingController _searchController = TextEditingController();

  List<ProfilePreview> _searchResults = [];
  List<FriendRequestItem> _incomingRequests = [];
  List<FriendRequestItem> _outgoingRequests = [];
  List<FriendItem> _friends = [];
  List<SharedNoteFeedItem> _feed = [];
  bool _loading = true;
  bool _searching = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _friendly(Object error, {String fallback = 'Something went wrong.'}) {
    return NotesLogic.userMessageForError(error, fallback: fallback);
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final incomingFuture = _logic.fetchIncomingFriendRequests();
      final outgoingFuture = _logic.fetchOutgoingFriendRequests();
      final friendsFuture = _logic.fetchFriends();
      final feedFuture = _logic.fetchFriendsFeed();
      final results = await Future.wait([
        incomingFuture,
        outgoingFuture,
        friendsFuture,
        feedFuture,
      ]);
      if (!mounted) return;
      setState(() {
        _incomingRequests = results[0] as List<FriendRequestItem>;
        _outgoingRequests = results[1] as List<FriendRequestItem>;
        _friends = results[2] as List<FriendItem>;
        _feed = results[3] as List<SharedNoteFeedItem>;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _friendly(error, fallback: 'Could not load social data.');
      });
    }
  }

  Future<void> _searchUsers() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _searching = true;
    });
    try {
      final users = await _logic.searchUsersByUsername(query);
      if (!mounted) return;
      setState(() {
        _searchResults = users;
        _searching = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _error = _friendly(error, fallback: 'Could not search users.');
      });
    }
  }

  Future<void> _sendRequest(String username) async {
    try {
      await _logic.sendFriendRequestByUsername(username);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend request sent.')),
      );
      await _loadAll();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(_friendly(error, fallback: 'Could not send request.'))),
      );
    }
  }

  Future<void> _respondRequest(String requestId, bool accept) async {
    try {
      await _logic.respondToFriendRequest(requestId: requestId, accept: accept);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(accept
                ? 'Friend request accepted.'
                : 'Friend request declined.')),
      );
      await _loadAll();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(_friendly(error, fallback: 'Could not update request.'))),
      );
    }
  }

  Future<void> _toggleLike(SharedNoteFeedItem item) async {
    try {
      await _logic.toggleFeedLike(item.id);
      await _loadAll();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(_friendly(error, fallback: 'Could not update like.'))),
      );
    }
  }

  Future<void> _openCommentsSheet(SharedNoteFeedItem item) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => FeedCommentsSheet(
        logic: _logic,
        item: item,
      ),
    );
    if (!mounted) return;
    await _loadAll();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: cs.surfaceContainerLowest,
        appBar: AppBar(
          title: const Text('Friends & Feed'),
          scrolledUnderElevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Friends', icon: Icon(Icons.group_outlined)),
              Tab(text: 'Feed', icon: Icon(Icons.dynamic_feed_outlined)),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  FriendsTab(
                    searchController: _searchController,
                    searching: _searching,
                    error: _error,
                    searchResults: _searchResults,
                    incomingRequests: _incomingRequests,
                    outgoingRequests: _outgoingRequests,
                    friends: _friends,
                    onSearch: _searchUsers,
                    onSendRequest: _sendRequest,
                    onRespondRequest: _respondRequest,
                    onRefresh: _loadAll,
                  ),
                  FeedTab(
                    feed: _feed,
                    onToggleLike: _toggleLike,
                    onOpenComments: _openCommentsSheet,
                    onRefresh: _loadAll,
                  ),
                ],
              ),
      ),
    );
  }
}
