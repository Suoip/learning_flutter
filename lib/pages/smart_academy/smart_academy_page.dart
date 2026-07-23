import 'package:flutter/material.dart';

/// Placeholder for the SmartAcademy mini-project: a coding-education hub
/// where a curated main page will sit alongside customizable pages for
/// individual educators. This is bare scaffolding only - the real hub,
/// educator sign-up, and per-educator pages are built out incrementally
/// in follow-up work.
class SmartAcademyPage extends StatelessWidget {
  const SmartAcademyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('SmartAcademy')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.school_rounded, size: 56, color: cs.primary),
              const SizedBox(height: 16),
              Text('SmartAcademy', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'A hub for learning to code, and for educators to teach it.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Coming soon',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: cs.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
