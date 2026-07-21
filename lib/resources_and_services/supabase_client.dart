import 'package:supabase_flutter/supabase_flutter.dart';

class AppSupabase {
  AppSupabase._();

  static Future<void> initialize() async {
    const url = String.fromEnvironment('SUPABASE_URL');
    const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

    if (url.isEmpty || anonKey.isEmpty) {
      throw Exception(
        'Missing SUPABASE_URL or SUPABASE_ANON_KEY. '
        'Run with --dart-define-from-file=env.json (copy env.example.json to env.json and fill in your values).',
      );
    }

    await Supabase.initialize(url: url, publishableKey: anonKey);
  }

  static SupabaseClient get client => Supabase.instance.client;

  static String? get emailRedirectTo {
    const raw = String.fromEnvironment('SUPABASE_EMAIL_REDIRECT_TO');
    final normalized = raw.trim();
    if (normalized.isEmpty) return null;
    return normalized;
  }
}
