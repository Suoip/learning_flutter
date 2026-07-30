import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../resources_and_services/notes_logic.dart';
import 'friend_status_button.dart';
import 'profile_avatar.dart';

/// Opens a floating, centered panel listing everyone who liked a shared
/// note - friends first, then everyone else with a mutual-friend count and
/// an "Add Friend" button. Deliberately not a full page or an edge-to-edge
/// bottom sheet: a custom `showGeneralDialog` with a transparent built-in
/// barrier lets this file draw its own blurred backdrop (the same
/// `BackdropFilter` technique as the frosted bottom nav bar) behind a
/// bounded, rounded panel that doesn't touch the screen edges.
Future<void> showLikedBySheet(
  BuildContext context, {
  required NotesLogic logic,
  required String sharedNoteId,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Liked by',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, animation, secondaryAnimation) {
      return _LikedBySheet(logic: logic, sharedNoteId: sharedNoteId);
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _LikerRow {
  _LikerRow({required this.liker, required this.status});

  final FeedLikerItem liker;
  FriendStatus status;
  int? mutualCount;
}

class _LikedBySheet extends StatefulWidget {
  const _LikedBySheet({required this.logic, required this.sharedNoteId});

  final NotesLogic logic;
  final String sharedNoteId;

  @override
  State<_LikedBySheet> createState() => _LikedBySheetState();
}

class _LikedBySheetState extends State<_LikedBySheet> {
  bool _loading = true;
  String? _error;
  List<_LikerRow> _rows = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final likers = await widget.logic.fetchFeedLikers(widget.sharedNoteId);
      final friends = await widget.logic.fetchFriends();
      final outgoing = await widget.logic.fetchOutgoingFriendRequests();
      final currentUserId = widget.logic.currentUser?.id;

      final friendIds = friends.map((f) => f.friend.id).toSet();
      final pendingIds = outgoing.map((r) => r.counterpart.id).toSet();

      final visible =
          likers.where((liker) => liker.userId != currentUserId).map((liker) {
        final status = friendIds.contains(liker.userId)
            ? FriendStatus.friend
            : pendingIds.contains(liker.userId)
                ? FriendStatus.pending
                : FriendStatus.none;
        return _LikerRow(liker: liker, status: status);
      }).toList();

      // Friends first, then everyone else - .where() preserves each group's
      // original (like-order) relative ordering, so this doesn't need a
      // sort comparator (List.sort isn't guaranteed stable in Dart).
      final rows = [
        ...visible.where((row) => row.status == FriendStatus.friend),
        ...visible.where((row) => row.status != FriendStatus.friend),
      ];

      if (!mounted) return;
      setState(() {
        _rows = rows;
        _loading = false;
      });

      for (final row in rows) {
        if (row.status == FriendStatus.friend) continue;
        widget.logic.fetchMutualFriendCount(row.liker.userId).then((count) {
          if (!mounted) return;
          setState(() => row.mutualCount = count);
        }).catchError((_) {});
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = NotesLogic.userMessageForError(
          error,
          fallback: 'Could not load likes.',
        );
      });
    }
  }

  Future<void> _addFriend(_LikerRow row) async {
    try {
      await widget.logic.sendFriendRequestByUsername(row.liker.username);
      if (!mounted) return;
      setState(() => row.status = FriendStatus.pending);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            NotesLogic.userMessageForError(
              error,
              fallback: 'Could not send friend request.',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).pop(),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(color: cs.scrim.withValues(alpha: 0.35)),
            ),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420, maxHeight: 520),
              child: Material(
                color: cs.surfaceContainerHigh,
                elevation: 6,
                shadowColor: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(24),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Liked by',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Close',
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                    Flexible(child: _buildBody(cs)),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(ColorScheme cs) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Text(_error!, style: TextStyle(color: cs.error)),
      );
    }

    if (_rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Text(
          'No likes yet.',
          style: TextStyle(color: cs.onSurfaceVariant),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: _rows.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final row = _rows[index];
        final showMutuals =
            row.status != FriendStatus.friend && (row.mutualCount ?? 0) > 0;
        return ListTile(
          leading: ProfileAvatar(
            username: row.liker.username,
            avatarUrl: row.liker.avatarUrl,
            radius: 18,
          ),
          title: Text('@${row.liker.username}'),
          subtitle: showMutuals
              ? Text(
                  '${row.mutualCount} mutual '
                  'friend${row.mutualCount == 1 ? '' : 's'}',
                )
              : null,
          trailing: FriendStatusButton(
            status: row.status,
            onAdd: () => _addFriend(row),
          ),
        );
      },
    );
  }
}
