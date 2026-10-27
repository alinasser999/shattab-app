import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/debug/debug_config.dart';
import 'core/theme/batsh_theme.dart';
import 'core/theme/batsh_typography.dart';
import 'core/l10n/l10n_extension.dart';
import 'l10n/app_localizations.dart';
import 'core/env/env.dart';
import 'core/logging/app_logger.dart';
import 'core/notifications/push_service.dart';
import 'core/router/browser_location.dart';
import 'core/supabase/supabase_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  captureInitialBrowserUri();
  usePathUrlStrategy();

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
      event.user = null;
      return event;
    };
  }, appRunner: _runApp);
}

Future<void> _retryInitialization() async {
  runApp(const _StartupApp());
  try {
    await _initializeApp();
  } catch (error, stackTrace) {
    AppLogger.error('app_boot_failed', error: error, stackTrace: stackTrace);
    runApp(const _StartupErrorApp());
  }
}

class _StartupApp extends StatelessWidget {
  const _StartupApp({this.failed = false});
  final bool failed;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: BatshTheme.light(),
    darkTheme: BatshTheme.dark(),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    // The real router reads the captured URI after initialization. Bootstrap
    // renders the same surface for deep links without attempting to resolve it.
    initialRoute: '/',
    onGenerateRoute: (_) => MaterialPageRoute<void>(
      builder: (context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/icon/app_icon_foreground.png',
                      width: 180,
                      height: 100,
                      fit: BoxFit.contain,
                      semanticLabel: context.l10n.appName,
                    ),
                    const SizedBox(height: 24),
                    if (failed) ...[
                      Text(
                        context.l10n.startupRetryMessage,
                        textAlign: TextAlign.center,
                        style: BatshTypography.bodyLg,
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: _retryInitialization,
                        child: Text(context.l10n.tryAgain),
                      ),
                    ] else
                      Semantics(
                        label: context.l10n.loading,
                        liveRegion: true,
                        excludeSemantics: true,
                        child: MediaQuery.disableAnimationsOf(context)
                            ? const Icon(Icons.hourglass_top_rounded)
                            : const SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                ),
                              ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp();
  @override
  Widget build(BuildContext context) => const _StartupApp(failed: true);
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
