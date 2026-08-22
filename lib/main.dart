import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/debug/debug_config.dart';
import 'core/env/env.dart';
import 'core/logging/app_logger.dart';
import 'core/notifications/push_service.dart';
import 'core/supabase/supabase_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Paint a real first frame before network and plugin initialization. On
  // mobile Safari, waiting here leaves a blank Flutter surface visible while
  // the keyboard or a slow connection is starting up.
  runApp(const _StartupApp());

  unawaited(
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]),
  );

  try {
    await _initializeApp();
  } catch (error, stackTrace) {
    // Keep a recoverable surface on boot failures instead of leaving a blank
    // canvas with no action for the user.
    AppLogger.error('app_boot_failed', error: error, stackTrace: stackTrace);
    runApp(const _StartupErrorApp());
  }
}

Future<void> _initializeApp() async {
  await Env.load();

  // Firebase Messaging is a native enhancement. It is not configured for
  // the web build, and initializing its missing platform channel before the
  // first frame makes Safari wait through a failed plugin handshake. In-app
  // and realtime notifications remain available on web.
  await SupabaseInit.ensureInitialized();
  if (!kIsWeb) await PushService.ensureInitialized();

  // Debug-only: sign in as the seeded test user so every write works against
  // real RLS. No-op + tree-shaken in release builds.
  await debugSignIn(Supabase.instance.client);

  final dsn = Env.sentryDsn;
  if (dsn == null) {
    // No DSN configured: run without crash reporting rather than refusing to
    // start. This is also the normal path for local development.
    _runApp();
    return;
  }

  await SentryFlutter.init((options) {
    options.dsn = dsn;
    options.environment = kReleaseMode ? 'production' : 'development';

    // Never attach request bodies, headers, cookies or user identifiers.
    options.sendDefaultPii = false;
    options.tracesSampleRate = kReleaseMode ? 0.2 : 1.0;
    options.attachScreenshot = false;

    options.beforeSend = (event, hint) {
      // Defence in depth: drop the user object even if an integration
      // populates it. Errors stay useful without knowing who hit them.
      return event.copyWith(user: null);
    };
  }, appRunner: _runApp);
}

class _StartupApp extends StatelessWidget {
  const _StartupApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color(0xFFF8F4EC),
        body: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Color(0xFFA64E2F),
            ),
          ),
        ),
      ),
    );
  }
}

class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color(0xFFF8F4EC),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'شطّب بياخد لحظة يبدأ. اقفل الصفحة وافتحها تاني.',
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                color: Color(0xFF2B2B2B),
                fontSize: 18,
                height: 1.6,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void _runApp() {
  _installErrorLogging();
  runApp(const ProviderScope(child: BatshApp()));
}

void _installErrorLogging() {
  final previousFlutterError = FlutterError.onError;
  FlutterError.onError = (details) {
    AppLogger.error(
      'flutter framework error',
      error: details.exception,
      stackTrace: details.stack,
    );
    previousFlutterError?.call(details);
  };

  final previousAsyncError = PlatformDispatcher.instance.onError;
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    AppLogger.error(
      'uncaught async error',
      error: error,
      stackTrace: stackTrace,
    );
    return previousAsyncError?.call(error, stackTrace) ?? false;
  };
}
