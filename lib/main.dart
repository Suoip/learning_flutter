import 'package:flutter/material.dart';
import 'pages/calculator_page.dart' as calculator_page;
import 'pages/cv_page.dart' as cv_page;
import 'pages/stopwatch_page.dart' as stopwatch_page;

void main() => runApp(const LearningFlutterApp());

class LearningFlutterApp extends StatelessWidget {
  const LearningFlutterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ProjectsHomePage(),
    );
  }
}

class ProjectsHomePage extends StatelessWidget {
  const ProjectsHomePage({super.key});

  static final List<_ProjectEntry> _projects = [
    _ProjectEntry(title: 'cv', builder: _buildCvPage),
    _ProjectEntry(title: 'calculator', builder: _buildCalculatorPage),
    _ProjectEntry(title: 'stopwatch', builder: _buildStopwatchPage),
  ];

  static Widget _buildCalculatorPage() => const calculator_page.Home();
  static Widget _buildCvPage() => const cv_page.Home();
  static Widget _buildStopwatchPage() => const stopwatch_page.Home();

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
