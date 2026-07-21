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

    return CircleAvatar(
      radius: radius,
      foregroundImage: hasAvatar ? NetworkImage(avatarUrl!) : null,
      child: Text(
        initial,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.75,
        ),
      ),
    );
  }
}
