import 'package:flutter/material.dart';

/// Where the current user stands with another person, for any row that
/// might represent someone who isn't a friend yet (search results, a
/// note's "liked by" list). `pending` exists so a second tap can't produce
/// a "you already sent a request" error - without it, a plain
/// friend/not-friend boolean would show an actionable "Add Friend" button
/// for someone a request was already sent to.
enum FriendStatus { friend, pending, none }

/// Trailing status/action element for a person row: a static "Friends"
/// pill, a static "Requested" pill, or an enabled "Add Friend" button.
class FriendStatusButton extends StatelessWidget {
  const FriendStatusButton({
    super.key,
    required this.status,
    required this.onAdd,
  });

  final FriendStatus status;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    switch (status) {
      case FriendStatus.friend:
        return _StatusPill(
          icon: Icons.check_rounded,
          label: 'Friends',
          background: cs.tertiaryContainer,
          foreground: cs.onTertiaryContainer,
        );
      case FriendStatus.pending:
        return _StatusPill(
          icon: Icons.schedule_rounded,
          label: 'Requested',
          background: cs.surfaceContainerHighest,
          foreground: cs.onSurfaceVariant,
        );
      case FriendStatus.none:
        return FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
          label: const Text('Add Friend'),
        );
    }
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
