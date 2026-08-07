import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/notifications_repository.dart';
import '../../domain/app_notification.dart';

part 'notifications_providers.g.dart';

/// One live subscription for the whole app.
///
/// `keepAlive` because the bell is drawn on three shells (discover, explore,
/// home) and an auto-disposing provider would tear the socket down and open a
/// fresh one every time the user crossed a tab boundary.
///
/// Keyed on the user *id* rather than the whole `Session`: Supabase mints a new
/// Session object on every hourly token refresh, and re-subscribing for that
/// would drop the socket for no reason. A change of identity is the one event
/// that must rebuild the stream — otherwise a logout would leave the previous
/// account's inbox feeding the next account's badge.
@Riverpod(keepAlive: true)
Stream<List<AppNotification>> notifications(Ref ref) {
  ref.watch(currentSessionProvider.select((session) => session?.user.id));
  return ref.watch(notificationsRepositoryProvider).watchMine();
}

@riverpod
int unreadNotifications(Ref ref) => ref
    .watch(notificationsProvider)
    .maybeWhen(
      data: (items) => items.where((item) => !item.isRead).length,
      orElse: () => 0,
    );

@Riverpod(keepAlive: true)
class NotificationsController extends _$NotificationsController {
  @override
  void build() {}

  // Neither of these invalidates the list any more. `notificationsProvider` is
  // a live subscription, and the UPDATE that sets `read_at` comes back over the
  // same socket — invalidating would drop and reopen the connection on every
  // tap to fetch a row realtime was already about to deliver.

  Future<void> markRead(String id) =>
      ref.read(notificationsRepositoryProvider).markRead(id);

  Future<void> markAllRead() =>
      ref.read(notificationsRepositoryProvider).markAllRead();
}
