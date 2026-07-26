import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

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

  final dsn = Env.sentryDsn;
  if (dsn == null) {
    // No DSN configured — run without crash reporting rather than refusing to
    // start. This is the path for contributors, and for any build where the
    // secret was not injected.
    runApp(const ProviderScope(child: BatshApp()));
    return;
  }

  await SentryFlutter.init(
    (options) {
      options.dsn = dsn;
      options.environment = kReleaseMode ? 'production' : 'development';

      // Never attach request bodies, headers, cookies or user identifiers.
      // Every account here is keyed by an Egyptian phone number, so the default
      // "helpful" PII capture would ship personal data to a third party.
      options.sendDefaultPii = false;

      // Errors are always sent; performance traces are sampled. Traces are the
      // expensive part of the quota and 20% is plenty to spot a slow screen.
      options.tracesSampleRate = kReleaseMode ? 0.2 : 1.0;

      // A screenshot here can contain a phone number, a brief, or the inside of
      // a customer's home.
      options.attachScreenshot = false;

      options.beforeSend = (event, hint) {
        // Defence in depth: drop the user object even if some integration
        // populates it. Errors stay useful without knowing who hit them.
        return event.copyWith(user: null);
      };
    },
    appRunner: () => runApp(const ProviderScope(child: BatshApp())),
  );
}
