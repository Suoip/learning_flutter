import 'package:flutter/material.dart';

import 'smart_academy_entry.dart';

class SmartAcademyHubToolbar extends StatelessWidget {
  const SmartAcademyHubToolbar({
    super.key,
    required this.searchController,
    required this.activeFilter,
    required this.onFilterChanged,
  });

  final TextEditingController searchController;
  final SmartAcademyHubFilter activeFilter;
  final ValueChanged<SmartAcademyHubFilter> onFilterChanged;

  Widget _filterChip({
    required SmartAcademyHubFilter filter,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: TextField(
            controller: searchController,
            decoration: const InputDecoration(
              hintText: 'Search by title or author',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _filterChip(
                filter: SmartAcademyHubFilter.all,
                label: 'All',
                icon: Icons.view_agenda_outlined,
              ),
              const SizedBox(width: 8),
              _filterChip(
                filter: SmartAcademyHubFilter.videos,
                label: 'Videos',
                icon: Icons.play_circle_outline_rounded,
              ),
              const SizedBox(width: 8),
              _filterChip(
                filter: SmartAcademyHubFilter.forum,
                label: 'Forum',
                icon: Icons.forum_outlined,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
