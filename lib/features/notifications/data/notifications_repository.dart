import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_provider.dart';
import '../domain/app_notification.dart';

part 'notifications_repository.g.dart';

class NotificationsRepository {
  NotificationsRepository(this._client);

  final SupabaseClient _client;

  Future<List<AppNotification>> fetchMine({int limit = 50}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const [];

    final rows = await _client
        .from('notifications')
        .select()
        .eq('recipient_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);
    return (rows as List)
        .map((row) => AppNotification.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Live view of the same rows `fetchMine` returns.
  ///
  /// A quote is only worth what it is worth *now*, so the bell cannot wait for
  /// the next cold fetch to admit one arrived. `.stream()` replays the current
  /// rows before it starts pushing, which makes this a drop-in for the initial
  /// load rather than something bolted beside it.
  ///
  /// Realtime evaluates `notifications_read_own` per subscriber, so the socket
  /// carries nothing this user could not already select. The `recipient_id`
  /// filter is belt-and-braces — and it is the *one* filter a Supabase stream
  /// allows, which is why unread is still counted on the client.
  Stream<List<AppNotification>> watchMine({int limit = 50}) {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return Stream.value(const []);

    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('recipient_id', userId)
        .order('created_at', ascending: false)
        .limit(limit)
        .map((rows) => rows.map(AppNotification.fromJson).toList());
  }

  Future<void> markRead(String id) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client
        .from('notifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id)
        .eq('recipient_id', userId);
  }

  Future<void> markAllRead() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client
        .from('notifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('recipient_id', userId)
        .isFilter('read_at', null);
  }
}

@Riverpod(keepAlive: true)
NotificationsRepository notificationsRepository(Ref ref) =>
    NotificationsRepository(ref.watch(supabaseClientProvider));
