import 'package:flutter/material.dart';

import '../../resources_and_services/notes_logic.dart';

class NotesToolbar extends StatelessWidget {
  const NotesToolbar({
    super.key,
    required this.searchController,
    required this.activeFilter,
    required this.onFilterChanged,
    required this.onCreateNote,
  });

  final TextEditingController searchController;
  final NoteQuickFilter activeFilter;
  final ValueChanged<NoteQuickFilter> onFilterChanged;
  final VoidCallback onCreateNote;

  Widget _filterChip({
    required NoteQuickFilter filter,
    required String label,
    required IconData icon,
  }) {
    final selected = activeFilter == filter;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: selected,
      onSelected: (_) => onFilterChanged(filter),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search by title',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: onCreateNote,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('New'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip(
                  filter: NoteQuickFilter.all,
                  label: 'All',
                  icon: Icons.view_agenda_outlined,
                ),
                const SizedBox(width: 8),
                _filterChip(
                  filter: NoteQuickFilter.pinned,
                  label: 'Pinned',
                  icon: Icons.push_pin_outlined,
                ),
                const SizedBox(width: 8),
                _filterChip(
                  filter: NoteQuickFilter.favorites,
                  label: 'Favorites',
                  icon: Icons.star_border_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
