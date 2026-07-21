import 'package:flutter/material.dart';
import 'pages/choose_location.dart';
import 'pages/home_navigation_page.dart';
import 'pages/stopwatch_page.dart' as stopwatch_page;
import 'pages/worldtime_page.dart' as time_page;
import 'resources_and_services/loading.dart';
import 'resources_and_services/supabase_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSupabase.initialize();
  runApp(const LearningFlutterApp());
}

class LearningFlutterApp extends StatelessWidget {
  const LearningFlutterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const ProjectsHomePage(),
      routes: {
        '/home': (context) => const time_page.Home(),
        '/location': (context) => const ChooseLocation(),
        '/loading': (context) => const Loading(),
        '/stopwatch': (context) => const stopwatch_page.Home(),
      },
    );
  }
}
