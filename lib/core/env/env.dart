import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Typed access to environment variables loaded from `.env`.
/// Call [Env.load] before runApp.
class Env {
  const Env._();

  static Future<void> load() => dotenv.load(fileName: '.env');

  static String _required(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw StateError(
        'Missing required env var "$key". Copy .env.example to .env and fill it in.',
      );
    }
    return value;
  }

  static String get supabaseUrl => _required('SUPABASE_URL');
  static String get supabaseAnonKey => _required('SUPABASE_ANON_KEY');
}
