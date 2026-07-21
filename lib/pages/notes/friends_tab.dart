import 'package:flutter/material.dart';

import '../../resources_and_services/notes_logic.dart';
import 'profile_avatar.dart';

class FriendsTab extends StatelessWidget {
  const FriendsTab({
    super.key,
    required this.searchController,
    required this.searching,
    required this.error,
    required this.searchResults,
    required this.incomingRequests,
    required this.outgoingRequests,
    required this.friends,
    required this.onSearch,
    required this.onSendRequest,
    required this.onRespondRequest,
    required this.onRefresh,
  });

  final TextEditingController searchController;
  final bool searching;
  final String? error;
  final List<ProfilePreview> searchResults;
  final List<FriendRequestItem> incomingRequests;
  final List<FriendRequestItem> outgoingRequests;
  final List<FriendItem> friends;
  final VoidCallback onSearch;
  final ValueChanged<String> onSendRequest;
  final void Function(String requestId, bool accept) onRespondRequest;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        children: [
          if (error != null) ...[
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  error!,
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
                      controller: searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => onSearch(),
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
                    onPressed: searching ? null : onSearch,
                    child: searching
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
          if (searchController.text.trim().isNotEmpty &&
              !searching &&
              searchResults.isEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'No users found. Make sure the username is correct.',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ],
          if (searchResults.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'Search results',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            ...searchResults.map((user) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: ProfileAvatar(
                  username: user.username,
                  avatarUrl: user.avatarUrl,
                  radius: 18,
                ),
                title: Text('@${user.username}'),
                trailing: FilledButton(
                  onPressed: () => onSendRequest(user.username),
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
              if (incomingRequests.isNotEmpty)
                Badge.count(count: incomingRequests.length),
            ],
          ),
          const SizedBox(height: 6),
          if (incomingRequests.isEmpty)
            Text(
              'No pending incoming requests.',
              style: TextStyle(color: cs.onSurfaceVariant),
            )
          else
            ...incomingRequests.map((request) {
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
                        onPressed: () => onRespondRequest(request.id, false),
                        child: const Text('Decline'),
                      ),
                      FilledButton(
                        onPressed: () => onRespondRequest(request.id, true),
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
          if (outgoingRequests.isEmpty)
            Text(
              'No pending outgoing requests.',
              style: TextStyle(color: cs.onSurfaceVariant),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: outgoingRequests
                  .map((request) =>
                      Chip(label: Text('@${request.counterpart.username}')))
                  .toList(),
            ),
          const SizedBox(height: 14),
          Text(
            'Friends (${friends.length})',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          if (friends.isEmpty)
            Text(
              'No friends yet.',
              style: TextStyle(color: cs.onSurfaceVariant),
            )
          else
            ...friends.map((friend) {
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
}
