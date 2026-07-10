import 'package:flutter/material.dart';
import 'calculator_page.dart' as calculator_page;
import 'cv_page.dart' as cv_page;
import 'notes_page.dart' as notes_page;
import '../resources_and_services/loading.dart' as world_time_loading;

class ProjectsHomePage extends StatelessWidget {
  const ProjectsHomePage({super.key});

  static final List<_ProjectEntry> _projects = [
    _ProjectEntry(title: 'Cv Resume', builder: _buildCvPage),
    _ProjectEntry(title: 'Calculator', builder: _buildCalculatorPage),
    _ProjectEntry(title: 'Clock', builder: _buildWorldTimePage),
    _ProjectEntry(title: 'Notes', builder: _buildNotesPage),
  ];

  static Widget _buildCalculatorPage() => const calculator_page.Home();
  static Widget _buildCvPage() => const cv_page.Home();
  static Widget _buildWorldTimePage() => const world_time_loading.Loading();
  static Widget _buildNotesPage() => const notes_page.NotesPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Learning Flutter')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Projects',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            ..._projects.map(
              (project) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => project.builder()),
                      );
                    },
                    child: Text(project.title),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectEntry {
  const _ProjectEntry({required this.title, required this.builder});

  final String title;
  final Widget Function() builder;
}
