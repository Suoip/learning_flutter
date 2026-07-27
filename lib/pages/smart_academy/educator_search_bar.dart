import 'package:flutter/material.dart';

import '../../resources_and_services/educator_logic.dart';
import 'educator_channel_page.dart';

/// A "Find an educator" username lookup on the public hub. Works for a
/// fully signed-out visitor - the underlying `findEducatorByUsername` call
/// only needs public read access (see backend/sql/009_educator_public_read.sql),
/// not a session.
class EducatorSearchBar extends StatefulWidget {
  const EducatorSearchBar({super.key});

  @override
  State<EducatorSearchBar> createState() => _EducatorSearchBarState();
}

class _EducatorSearchBarState extends State<EducatorSearchBar> {
  final EducatorLogic _logic = EducatorLogic();
  final _controller = TextEditingController();

  bool _searching = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final username = _controller.text.trim();
    if (username.isEmpty || _searching) return;

    setState(() {
      _searching = true;
      _error = null;
    });

    try {
      final profile = await _logic.findEducatorByUsername(username);
      if (!mounted) return;
      setState(() {
        _searching = false;
      });

      if (profile == null) {
        setState(() {
          _error = 'No educator found with that username.';
        });
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EducatorChannelPage(educatorId: profile.id),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _error = EducatorLogic.userMessageForError(
          error,
          fallback: 'Could not search right now.',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Find an educator',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(),
                    decoration: InputDecoration(
                      hintText: 'Username',
                      prefixIcon: const Icon(Icons.search_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: _searching ? null : _search,
                  child: _searching
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Search'),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: cs.error)),
            ],
          ],
        ),
      ),
    );
  }
}
