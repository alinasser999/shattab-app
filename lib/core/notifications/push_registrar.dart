import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../l10n/locale_provider.dart';
import '../router/app_router.dart';
import '../router/routes.dart';
import '../supabase/supabase_provider.dart';
import 'push_service.dart';

part 'push_registrar.g.dart';

/// Ties the device's push registration to whoever is signed in.
///
/// Watched once from `BatshApp` so it lives for the process. Registration has
/// to follow the session rather than happen once at boot: a token left
/// pointing at the previous account would keep delivering that account's
/// quotes to a phone someone else is now holding.
@Riverpod(keepAlive: true)
class PushRegistrar extends _$PushRegistrar {
  bool _tapsWired = false;

  @override
  void build() {
    final userId = ref.watch(
      currentSessionProvider.select((session) => session?.user.id),
    );
    // Read, not watch: a language toggle should not churn the registration.
    // The stored locale refreshes on the next sign-in or token rotation, and
    // one push in the previous language is a smaller cost than re-registering
    // every device every time someone flips the switch.
    final locale = ref.read(localeProvider).languageCode == 'en' ? 'en' : 'ar';
    final client = ref.read(supabaseClientProvider);

    if (userId == null) {
      unawaited(PushService.unregister(client));
      return;
    }

    unawaited(PushService.register(client, userId, locale));
    unawaited(_listenForTaps());
  }

  /// A tap opens the notifications list rather than deep-linking straight to
  /// the entity.
  ///
  /// The list's own `_openNotification` already resolves entity type *and*
  /// viewer role into a route; reproducing that here would be a second copy of
  /// the mapping, free to drift out of step. It also lands the user somewhere
  /// with context rather than on a bare detail screen they cannot place.
  Future<void> _listenForTaps() async {
    if (_tapsWired || !PushService.isAvailable) return;
    _tapsWired = true;

    void open(RemoteMessage? message) {
      if (message == null) return;
      ref.read(appRouterProvider).push(Routes.notifications);
    }

    // Cold start: the tap that launched the process.
    open(await FirebaseMessaging.instance.getInitialMessage());

    // Warm start: tapped while the app sat in the background.
    final sub = FirebaseMessaging.onMessageOpenedApp.listen(open);
    ref.onDispose(sub.cancel);
  }
}
