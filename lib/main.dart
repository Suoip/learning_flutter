import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'pages/choose_location.dart';
import 'pages/home_navigation_page.dart';
import 'pages/notes/reset_password_page.dart';
import 'pages/smart_academy/smart_academy_reset_password_page.dart';
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
          // The 'app' tag from signup metadata ('notes' or 'smart_academy'),
          // read off this event's own session rather than the global
          // client.auth.currentUser to avoid any doubt about timing.
          // Missing/null covers every Notes account created before this tag
          // existed - default to Notes, the only feature this app had
          // before educator accounts, so existing users are unaffected.
          final signupApp =
              (state.session?.user.userMetadata?['app'] as String?)
                  ?.trim()
                  .toLowerCase();
          final page = signupApp == 'smart_academy'
              ? const SmartAcademyResetPasswordPage()
              : const ResetPasswordPage();
          _navigatorKey.currentState?.push(
            MaterialPageRoute(builder: (_) => page),
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
