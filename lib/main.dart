import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'pages/choose_location.dart';
import 'pages/home_navigation_page.dart';
import 'pages/notes/reset_password_page.dart';
import 'pages/stopwatch_page.dart' as stopwatch_page;
import 'pages/worldtime_page.dart' as time_page;
import 'resources_and_services/loading.dart';
import 'resources_and_services/supabase_client.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSupabase.initialize();
  runApp(const LearningFlutterApp());
}

class LearningFlutterApp extends StatefulWidget {
  const LearningFlutterApp({super.key});

  @override
  State<LearningFlutterApp> createState() => _LearningFlutterAppState();
}

class _LearningFlutterAppState extends State<LearningFlutterApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<AuthState>? _authStateSubscription;

  @override
  void initState() {
    super.initState();
    // Supabase's password-reset link lands the user back in the app with a
    // recovery session already established, signaled by this one-time
    // stream event - regardless of which page they were on. Listening at
    // the app root (rather than inside the Notes feature) is what lets us
    // catch it even if the user isn't currently in Notes at all.
    _authStateSubscription = AppSupabase.client.auth.onAuthStateChange.listen(
      (state) {
        if (state.event == AuthChangeEvent.passwordRecovery) {
          _navigatorKey.currentState?.push(
            MaterialPageRoute(builder: (_) => const ResetPasswordPage()),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      themeMode: ThemeMode.dark,
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
