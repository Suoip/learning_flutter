import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppSupabase {
  AppSupabase._();

  static Future<void> initialize() async {
    await dotenv.load(fileName: '.env');

    final url = dotenv.env['SUPABASE_URL'];
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (url == null || url.isEmpty || anonKey == null || anonKey.isEmpty) {
      throw Exception(
        'Missing SUPABASE_URL or SUPABASE_ANON_KEY in .env. '
        'Copy .env.example to .env and fill in your values.',
      );
    }

    await Supabase.initialize(url: url, publishableKey: anonKey);
  }

  static SupabaseClient get client => Supabase.instance.client;

  static String? get emailRedirectTo {
    final raw = dotenv.env['SUPABASE_EMAIL_REDIRECT_TO'];
    if (raw == null) return null;
    final normalized = raw.trim();
    if (normalized.isEmpty) return null;
    return normalized;
  }
}
