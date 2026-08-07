import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../logging/app_logger.dart';

/// Registers this device as a push target and keeps that registration honest.
///
/// Everything here is best-effort by construction. Push is an enhancement on
/// top of a notification row that already exists in the database and is already
/// delivered live over realtime when the app is open — so a device that cannot
/// register (no Firebase config in the build, permission denied, no Play
/// Services, which is common on Egyptian Android handsets) has to degrade to
/// the in-app experience rather than take the app down with it.
///
/// That is why `ensureInitialized` logs and continues instead of rethrowing:
/// the alternative is an app that refuses to boot until someone finishes a
/// step in the Firebase console.
class PushService {
  PushService._();

  static bool _available = false;
  static StreamSubscription<String>? _refreshSub;

  /// True once Firebase started and messaging is usable on this device.
  static bool get isAvailable => _available;

  /// Called once at boot, before `runApp`.
  static Future<void> ensureInitialized() async {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(pushBackgroundHandler);
      _available = true;
    } catch (error, stackTrace) {
      // No google-services.json / GoogleService-Info.plist in this build, or no
      // Play Services on the handset. Both are expected states, not faults.
      AppLogger.warning(
        'push_unavailable_falling_back_to_in_app',
        error: error,
        stackTrace: stackTrace,
      );
      _available = false;
    }
  }

  /// Asks for permission and records the resulting token against [userId].
  ///
  /// Safe to call repeatedly: FCM hands back the same token until it rotates,
  /// and the upsert is keyed on the token itself.
  static Future<void> register(
    SupabaseClient client,
    String userId,
    String locale,
  ) async {
    if (!_available) return;

    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        // A denial is a real answer. Don't nag, don't retry, and don't store a
        // token there is no permission to use.
        return;
      }

      final token = await messaging.getToken();
      if (token != null) await _store(client, userId, token, locale);

      // A token can rotate at any time (restore from backup, cleared cache,
      // long idle). Missing a rotation means silently never reaching this
      // device again, with nothing on either end reporting a failure.
      await _refreshSub?.cancel();
      _refreshSub = messaging.onTokenRefresh.listen(
        (next) => _store(client, userId, next, locale),
        onError: (Object error, StackTrace stackTrace) => AppLogger.warning(
          'push_token_refresh_failed',
          error: error,
          stackTrace: stackTrace,
        ),
      );
    } catch (error, stackTrace) {
      AppLogger.warning(
        'push_registration_failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Drops this device's token so a signed-out phone stops receiving the
  /// previous account's notifications — which is why this runs on sign-out
  /// rather than letting the row age out on its own.
  static Future<void> unregister(SupabaseClient client) async {
    await _refreshSub?.cancel();
    _refreshSub = null;
    if (!_available) return;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await client.from('device_tokens').delete().eq('token', token);
      await FirebaseMessaging.instance.deleteToken();
    } catch (error, stackTrace) {
      AppLogger.warning(
        'push_unregister_failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static Future<void> _store(
    SupabaseClient client,
    String userId,
    String token,
    String locale,
  ) async {
    try {
      await client.from('device_tokens').upsert({
        'token': token,
        'user_id': userId,
        'platform': defaultTargetPlatform == TargetPlatform.iOS
            ? 'ios'
            : 'android',
        'locale': locale,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'token');
    } catch (error, stackTrace) {
      AppLogger.warning(
        'push_token_upsert_failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}

/// Required by firebase_messaging to exist as a top-level entry point.
///
/// It intentionally does nothing. The payload carries routing ids only, and the
/// system tray has already drawn the notification from the `notification` block
/// the Edge Function sent, so there is no work to do until the user taps.
@pragma('vm:entry-point')
Future<void> pushBackgroundHandler(RemoteMessage message) async {}
