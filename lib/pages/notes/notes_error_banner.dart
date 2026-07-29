import 'package:flutter/material.dart';

/// Shared error banner, used across Notes/Feed/Friends/Profile so an error
/// looks the same regardless of which screen it happened on.
class NotesErrorBanner extends StatelessWidget {
  const NotesErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(message, style: TextStyle(color: cs.onErrorContainer)),
      ),
    );
  }
}
