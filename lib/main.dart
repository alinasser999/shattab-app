import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/debug/debug_config.dart';
import 'core/env/env.dart';
import 'core/supabase/supabase_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Env.load();
  await SupabaseInit.ensureInitialized();

  // Debug-only: sign in as the seeded test user so every write works against
  // real RLS. No-op + tree-shaken in release builds.
  await debugSignIn(Supabase.instance.client);

  runApp(const ProviderScope(child: BatshApp()));
}
