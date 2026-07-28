import 'package:supabase_flutter/supabase_flutter.dart';

import '../env/env.dart';

/// Initializes Supabase once at app startup.
class SupabaseInit {
  const SupabaseInit._();

  static Future<void> ensureInitialized() async {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: true),
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
