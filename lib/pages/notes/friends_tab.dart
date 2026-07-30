import 'package:flutter/material.dart';

import '../../resources_and_services/notes_logic.dart';
import 'friend_status_button.dart';
import 'notes_error_banner.dart';
import 'pop_on_change.dart';
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
    required this.onCancelRequest,
    required this.onRemoveFriend,
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
  final ValueChanged<String> onCancelRequest;
  final ValueChanged<FriendItem> onRemoveFriend;
  final Future<void> Function() onRefresh;

  FriendStatus _statusFor(String userId) {
    if (friends.any((f) => f.friend.id == userId)) return FriendStatus.friend;
    if (outgoingRequests.any((r) => r.counterpart.id == userId)) {
      return FriendStatus.pending;
    }
    return FriendStatus.none;
  }

  Widget _sectionCard(ColorScheme cs, {required List<Widget> children}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: children),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        children: [
          if (error != null) ...[
            NotesErrorBanner(message: error!),
            const SizedBox(height: 12),
          ],
          _sectionCard(
            cs,
            children: [
              Row(
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
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                alignment: Alignment.topLeft,
                child: Builder(
                  builder: (context) {
                    if (searchController.text.trim().isNotEmpty &&
                        !searching &&
                        searchResults.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          'No users found. Make sure the username is correct.',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                      );
                    }
                    if (searchResults.isNotEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                                trailing: FriendStatusButton(
                                  status: _statusFor(user.id),
                                  onAdd: () => onSendRequest(user.username),
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _sectionCard(
            cs,
            children: [
              Row(
                children: [
                  const Text(
                    'Incoming requests',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 8),
                  PopOnChange(
                    active: incomingRequests.isNotEmpty,
                    child: incomingRequests.isEmpty
                        ? const SizedBox.shrink()
                        : Badge.count(count: incomingRequests.length),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                alignment: Alignment.topLeft,
                child: incomingRequests.isEmpty
                    ? Text(
                        'No pending incoming requests.',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: incomingRequests.map((request) {
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
                                  Expanded(
                                    child: Text(
                                      '@${request.counterpart.username}',
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        onRespondRequest(request.id, false),
                                    child: const Text('Decline'),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        onRespondRequest(request.id, true),
                                    child: const Text('Accept'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _sectionCard(
            cs,
            children: [
              const Text(
                'Sent requests',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                alignment: Alignment.topLeft,
                child: outgoingRequests.isEmpty
                    ? Text(
                        'No pending outgoing requests.',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: outgoingRequests
                            .map((request) => Chip(
                                  label:
                                      Text('@${request.counterpart.username}'),
                                  deleteIcon: const Icon(Icons.close, size: 18),
                                  deleteButtonTooltipMessage: 'Cancel request',
                                  onDeleted: () => onCancelRequest(request.id),
                                ))
                            .toList(),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _sectionCard(
            cs,
            children: [
              Text(
                'Friends (${friends.length})',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                alignment: Alignment.topLeft,
                child: friends.isEmpty
                    ? Text(
                        'No friends yet.',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: friends.map((friend) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: ProfileAvatar(
                              username: friend.friend.username,
                              avatarUrl: friend.friend.avatarUrl,
                              radius: 18,
                            ),
                            title: Text('@${friend.friend.username}'),
                            subtitle: Text(
                              'Friends since '
                              '${NotesLogic.formatUpdatedTime(friend.createdAt)}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.person_remove_outlined),
                              tooltip: 'Remove friend',
                              onPressed: () => onRemoveFriend(friend),
                            ),
                          );
                        }).toList(),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
