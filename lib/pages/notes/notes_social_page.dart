import 'package:flutter/material.dart';

import '../../resources_and_services/notes_logic.dart';
import 'feed_comments_sheet.dart';
import 'profile_avatar.dart';

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

  Widget _buildFriendsTab() {
    final cs = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        children: [
          if (_error != null) ...[
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _error!,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _searchUsers(),
                      decoration: InputDecoration(
                        labelText: 'Find users by username',
                        hintText: 'Type a username to send a friend request',
                        prefixIcon: const Icon(Icons.search_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: _searching ? null : _searchUsers,
                    child: _searching
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Search'),
                  ),
                ],
              ),
            ),
          ),
          if (_searchController.text.trim().isNotEmpty &&
              !_searching &&
              _searchResults.isEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'No users found. Make sure the username is correct.',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ],
          if (_searchResults.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'Search results',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            ..._searchResults.map((user) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: ProfileAvatar(
                  username: user.username,
                  avatarUrl: user.avatarUrl,
                  radius: 18,
                ),
                title: Text('@${user.username}'),
                trailing: FilledButton(
                  onPressed: () => _sendRequest(user.username),
                  child: const Text('Add'),
                ),
              );
            }),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                'Incoming requests',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              if (_incomingRequests.isNotEmpty)
                Badge.count(count: _incomingRequests.length),
            ],
          ),
          const SizedBox(height: 6),
          if (_incomingRequests.isEmpty)
            Text(
              'No pending incoming requests.',
              style: TextStyle(color: cs.onSurfaceVariant),
            )
          else
            ..._incomingRequests.map((request) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 5),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      ProfileAvatar(
                        username: request.counterpart.username,
                        avatarUrl: request.counterpart.avatarUrl,
                        radius: 16,
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text('@${request.counterpart.username}')),
                      TextButton(
                        onPressed: () => _respondRequest(request.id, false),
                        child: const Text('Decline'),
                      ),
                      FilledButton(
                        onPressed: () => _respondRequest(request.id, true),
                        child: const Text('Accept'),
                      ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 14),
          const Text(
            'Sent requests',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          if (_outgoingRequests.isEmpty)
            Text(
              'No pending outgoing requests.',
              style: TextStyle(color: cs.onSurfaceVariant),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _outgoingRequests
                  .map((request) =>
                      Chip(label: Text('@${request.counterpart.username}')))
                  .toList(),
            ),
          const SizedBox(height: 14),
          Text(
            'Friends (${_friends.length})',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          if (_friends.isEmpty)
            Text(
              'No friends yet.',
              style: TextStyle(color: cs.onSurfaceVariant),
            )
          else
            ..._friends.map((friend) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: ProfileAvatar(
                  username: friend.friend.username,
                  avatarUrl: friend.friend.avatarUrl,
                  radius: 18,
                ),
                title: Text('@${friend.friend.username}'),
                subtitle: Text(
                  'Friends since ${NotesLogic.formatUpdatedTime(friend.createdAt)}',
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildFeedTab() {
    final cs = Theme.of(context).colorScheme;
    if (_feed.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadAll,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 70, 20, 120),
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side:
                    BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: const Padding(
                padding: EdgeInsets.all(22),
                child: Column(
                  children: [
                    Icon(Icons.dynamic_feed_outlined, size: 36),
                    SizedBox(height: 8),
                    Text(
                      'No shared notes yet',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'When your friends publish notes, they will appear here.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        itemCount: _feed.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = _feed[index];
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
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
                              '@${item.authorUsername}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
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
                  const SizedBox(height: 10),
                  Text(
                    item.title,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(item.content.isEmpty ? '(No content)' : item.content),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      IconButton(
                        tooltip: item.isLikedByCurrentUser ? 'Unlike' : 'Like',
                        onPressed: () => _toggleLike(item),
                        icon: Icon(
                          item.isLikedByCurrentUser
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: item.isLikedByCurrentUser
                              ? Colors.pink.shade500
                              : cs.onSurfaceVariant,
                        ),
                      ),
                      Text('${item.likeCount}'),
                      const SizedBox(width: 10),
                      IconButton(
                        tooltip: 'Comments',
                        onPressed: () => _openCommentsSheet(item),
                        icon: const Icon(Icons.mode_comment_outlined),
                      ),
                      Text('${item.commentCount}'),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: cs.secondaryContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Read-only',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: cs.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
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
                  _buildFriendsTab(),
                  _buildFeedTab(),
                ],
              ),
      ),
    );
  }
}
