import 'package:flutter/material.dart';

import '../../resources_and_services/notes_logic.dart';
import 'friends_tab.dart';
import 'notes_skeletons.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key, required this.onPendingCountChanged});

  final ValueChanged<int> onPendingCountChanged;

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final NotesLogic _logic = NotesLogic();
  final TextEditingController _searchController = TextEditingController();

  List<ProfilePreview> _searchResults = [];
  List<FriendRequestItem> _incomingRequests = [];
  List<FriendRequestItem> _outgoingRequests = [];
  List<FriendItem> _friends = [];
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
      final results = await Future.wait([
        incomingFuture,
        outgoingFuture,
        friendsFuture,
      ]);
      if (!mounted) return;
      final incoming = results[0] as List<FriendRequestItem>;
      setState(() {
        _incomingRequests = incoming;
        _outgoingRequests = results[1] as List<FriendRequestItem>;
        _friends = results[2] as List<FriendItem>;
        _loading = false;
      });
      widget.onPendingCountChanged(incoming.length);
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

  Future<void> _cancelRequest(String requestId) async {
    try {
      await _logic.cancelFriendRequest(requestId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend request cancelled.')),
      );
      await _loadAll();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(_friendly(error, fallback: 'Could not cancel request.'))),
      );
    }
  }

  Future<void> _removeFriend(FriendItem friend) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove Friend'),
          content: Text(
            'Remove @${friend.friend.username} from your friends? '
            "You'll need to send a new friend request to reconnect.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (shouldRemove != true) return;

    try {
      await _logic.removeFriend(friend.friendshipId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Removed @${friend.friend.username} from friends.')),
      );
      await _loadAll();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(_friendly(error, fallback: 'Could not remove friend.'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const FriendsTabSkeleton();
    }

    return FriendsTab(
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
      onCancelRequest: _cancelRequest,
      onRemoveFriend: _removeFriend,
      onRefresh: _loadAll,
    );
  }
}
