import 'package:flutter/material.dart';

/// Minimal post-login landing spot for educators. No real dashboard
/// features exist yet - course/content management is future work, built
/// incrementally on top of the auth system this page currently stands in for.
class EducatorDashboardPlaceholderPage extends StatelessWidget {
  const EducatorDashboardPlaceholderPage({
    super.key,
    required this.username,
    required this.onSignOut,
  });

  final String username;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.school_outlined, size: 40, color: cs.primary),
                    const SizedBox(height: 12),
                    Text(
                      'Welcome, $username.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Course/content management coming soon.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: onSignOut,
                      child: const Text('Sign out'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
