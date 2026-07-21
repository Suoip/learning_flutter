import 'package:flutter/material.dart';
import 'calculator_page.dart' as calculator_page;
import 'cv_page.dart' as cv_page;
import 'notes/notes_page.dart' as notes_page;
import '../resources_and_services/loading.dart' as world_time_loading;

class ProjectsHomePage extends StatelessWidget {
  const ProjectsHomePage({super.key});

  static final List<_ProjectEntry> _projects = [
    _ProjectEntry(
      title: 'CV Resume',
      subtitle: 'Professional profile layout and personal branding.',
      icon: Icons.badge_outlined,
      accent: Color(0xFF2563EB),
      builder: _buildCvPage,
    ),
    _ProjectEntry(
      title: 'Calculator',
      subtitle: 'Clean utility app with basic arithmetic features.',
      icon: Icons.calculate_outlined,
      accent: Color(0xFF7C3AED),
      builder: _buildCalculatorPage,
    ),
    _ProjectEntry(
      title: 'Clock',
      subtitle: 'Location-aware World Clock time display with route navigation and StopWatch app combined with bottom navigation bar access.',
      icon: Icons.schedule_outlined,
      accent: Color(0xFF0F766E),
      builder: _buildWorldTimePage,
    ),
    _ProjectEntry(
      title: 'Notes',
      subtitle: 'Authenticated note-taking backed by Supabase.',
      icon: Icons.sticky_note_2_outlined,
      accent: Color(0xFFDC2626),
      builder: _buildNotesPage,
    ),
  ];

  static Widget _buildCalculatorPage() => const calculator_page.Home();
  static Widget _buildCvPage() => const cv_page.Home();
  static Widget _buildWorldTimePage() => const world_time_loading.Loading();
  static Widget _buildNotesPage() => const notes_page.NotesPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text('Learning Flutter'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF1D4ED8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x220F172A),
                        blurRadius: 24,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mini Projects Dashboard',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'A central launchpad for small Flutter projects, built to grow with more modules over time.',
                        style: TextStyle(
                          color: Color(0xFFDCE7FF),
                          fontSize: 15.5,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Text(
                      'Projects',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_projects.length} available',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth >= 900
                        ? 2
                        : constraints.maxWidth >= 640
                            ? 2
                            : 1;
                    final spacing = 16.0;
                    final cardWidth =
                        (constraints.maxWidth - ((crossAxisCount - 1) * spacing)) /
                            crossAxisCount;

                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: _projects.map((project) {
                        return SizedBox(
                          width: cardWidth,
                          child: _ProjectCard(
                            project: project,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => project.builder(),
                                ),
                              );
                            },
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProjectEntry {
  const _ProjectEntry({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.builder,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Widget Function() builder;
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    required this.onTap,
  });

  final _ProjectEntry project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D0F172A),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: project.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          project.icon,
                          color: project.accent,
                          size: 28,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: project.accent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    project.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    project.subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.35,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Open project',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: project.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
