import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/draft_photo.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/utils/image_compression.dart';
import '../../../core/utils/upload_policy.dart';

/// Status of a contractor's most recent verification request.
/// [none] = never applied. The badge grant itself lives on
/// `contractor_profiles.verified`; this only tracks the review pipeline.
enum VerificationStatus { none, pending, approved, rejected }

/// Writes verification requests. The badge is NOT granted here — a founder
/// approves the pending row via `approve_verification_request()` (service role,
/// migration 0015), which flips `contractor_profiles.verified`. The client can
/// only ever create a pending request.
class VerificationRepository {
  VerificationRepository(this._client);
  final SupabaseClient _client;

  /// Latest request status for the signed-in contractor (null user → none).
  Future<VerificationStatus> currentStatus() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return VerificationStatus.none;
    final row = await _client
        .from('verification_requests')
        .select('status')
        .eq('contractor_id', uid)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return switch (row?['status']) {
      'pending' => VerificationStatus.pending,
      'approved' => VerificationStatus.approved,
      'rejected' => VerificationStatus.rejected,
      _ => VerificationStatus.none,
    };
  }

  /// Uploads the document photos and inserts a pending verification request.
  /// Throws if not signed in or no docs provided.
  Future<void> submit({required List<DraftPhoto> docs, String? note}) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw StateError('not signed in');
    if (docs.isEmpty) throw ArgumentError('at least one document required');

    final storage = _client.storage.from('verification-docs');
    final paths = <String>[];
    for (var i = 0; i < docs.length; i++) {
      final name = '$uid/${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
      final d = docs[i];
      final bytes = d.file != null
          ? await ImageCompression.prepare(await d.file!.readAsBytes())
          : d.bytes != null
          ? await ImageCompression.prepare(d.bytes!)
          : null;
      if (bytes == null) continue;
      UploadPolicy.validateImageBytes(bytes);
      await storage.uploadBinary(
        name,
        bytes,
        fileOptions: const FileOptions(
          // Each document gets a fresh path. Overwrite permission would add
          // risk without enabling a real verification workflow.
          upsert: false,
          contentType: 'image/jpeg',
        ),
      );
      paths.add(name);
    }

    if (paths.isEmpty) {
      throw ArgumentError('no valid verification documents provided');
    }

    await _client.from('verification_requests').insert({
      'contractor_id': uid,
      'doc_paths': paths,
      'note': (note != null && note.trim().isNotEmpty) ? note.trim() : null,
      'status': 'pending',
    });
  }
}

final verificationRepositoryProvider = Provider<VerificationRepository>(
  (ref) => VerificationRepository(ref.watch(supabaseClientProvider)),
);

/// Latest verification status for the current contractor. Auto-disposes so it
/// re-fetches whenever the account screen is reopened after submitting.
final verificationStatusProvider = FutureProvider<VerificationStatus>(
  (ref) => ref.watch(verificationRepositoryProvider).currentStatus(),
);
