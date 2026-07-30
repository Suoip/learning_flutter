import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.username,
    required this.avatarUrl,
    required this.radius,
  });

  final String? username;
  final String? avatarUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final fallbackName = (username ?? '').trim();
    final initial =
        fallbackName.isEmpty ? '?' : fallbackName.substring(0, 1).toUpperCase();

    final hasAvatar = (avatarUrl ?? '').isNotEmpty;
    final cs = Theme.of(context).colorScheme;

    return Semantics(
      label: fallbackName.isEmpty
          ? 'Profile picture'
          : 'Profile picture of $fallbackName',
      image: true,
      // Keyed by avatarUrl so a freshly-uploaded photo (or the initial ->
      // photo transition) crossfades in instead of swapping instantly.
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: CircleAvatar(
          key: ValueKey(avatarUrl ?? ''),
          radius: radius,
          // Default CircleAvatar without an explicit backgroundColor falls
          // back to Material's generic grey, clashing against the app's
          // dark blurple design system - primaryContainer keeps the fallback
          // initial on-brand for every user without a photo set.
          backgroundColor: cs.primaryContainer,
          foregroundImage: hasAvatar ? NetworkImage(avatarUrl!) : null,
          child: Text(
            initial,
            style: TextStyle(
              color: cs.onPrimaryContainer,
              fontWeight: FontWeight.w700,
              fontSize: radius * 0.75,
            ),
          ),
        ),
      ),
    );
  }
}
