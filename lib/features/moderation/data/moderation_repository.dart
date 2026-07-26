import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_provider.dart';

part 'moderation_repository.g.dart';

/// What a report points at. The value is stored verbatim in
/// `content_reports.target_type`, which has a CHECK constraint on exactly these
/// strings — the enum name and the wire value must not drift.
enum ReportTarget { post, comment, profile, brief, review }

/// Why something was reported. Mirrors the `content_reports.reason` CHECK.
enum ReportReason {
  spam,
  scam,
  offensive,
  sexual,
  violence,
  impersonation,
  other,
}

/// Blocking and reporting.
///
/// Blocks take effect immediately and are private to the blocker — the feed RPC
/// filters in both directions (0024), so blocking also stops the other person
/// seeing your posts. Reports are queued for an operator and deliberately hide
/// nothing on their own.
class ModerationRepository {
  ModerationRepository(this._client);
  final SupabaseClient _client;

  String get _uid {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw StateError('No authenticated user.');
    return id;
  }

  Future<Set<String>> fetchBlockedIds() async {
    final rows = await _client
        .from('user_blocks')
        .select('blocked_id')
        .eq('blocker_id', _uid);
    return rows.map((r) => r['blocked_id'] as String).toSet();
  }

  Future<void> block(String userId) async {
    // Idempotent: re-blocking must not surface a primary-key error to someone
    // who simply tapped twice.
    await _client.from('user_blocks').upsert(
      {'blocker_id': _uid, 'blocked_id': userId},
      onConflict: 'blocker_id,blocked_id',
    );
  }

  Future<void> unblock(String userId) async {
    await _client
        .from('user_blocks')
        .delete()
        .eq('blocker_id', _uid)
        .eq('blocked_id', userId);
  }

  /// Files a report. Returns false when this user already reported this item —
  /// the table's unique constraint makes re-reporting a no-op rather than an
  /// error the user has to interpret.
  Future<bool> report({
    required ReportTarget target,
    required String targetId,
    required ReportReason reason,
    String? note,
  }) async {
    try {
      await _client.from('content_reports').insert({
        'reporter_id': _uid,
        'target_type': target.name,
        'target_id': targetId,
        'reason': reason.name,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      });
      return true;
    } on PostgrestException catch (e) {
      // 23505 = unique_violation → already reported.
      if (e.code == '23505') return false;
      rethrow;
    }
  }
}

@riverpod
ModerationRepository moderationRepository(Ref ref) =>
    ModerationRepository(ref.watch(supabaseClientProvider));

/// Ids the signed-in user has blocked. Lets lists the feed RPC does not cover
/// (search results, saved contractors) hide blocked people too.
@riverpod
Future<Set<String>> blockedIds(Ref ref) =>
    ref.watch(moderationRepositoryProvider).fetchBlockedIds();
