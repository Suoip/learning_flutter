import 'package:flutter/material.dart';

import '../../resources_and_services/notes_logic.dart';
import 'profile_avatar.dart';

class ProfileAvatarSection extends StatelessWidget {
  const ProfileAvatarSection({
    super.key,
    required this.profile,
    required this.uploadingAvatar,
    required this.onPickAvatar,
  });

  final UserProfile? profile;
  final bool uploadingAvatar;
  final VoidCallback onPickAvatar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: cs.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            ProfileAvatar(
              username: profile?.username,
              avatarUrl: profile?.avatarUrl,
              radius: 44,
            ),
            const SizedBox(height: 12),
            Text(
              '@${profile?.username ?? ''}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: uploadingAvatar ? null : onPickAvatar,
              icon: uploadingAvatar
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.photo_camera_outlined),
              label: const Text('Change profile picture'),
            ),
          ],
        ),
      ),
    );
  }
}
