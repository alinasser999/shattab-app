import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/analytics/app_analytics.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/utils/upload_policy.dart';

/// Writes manual-transfer payment claims. Feature grant is NOT done here — an
/// admin approves the pending row via `approve_payment_request()` (service role),
/// which flips the plan. The client can only ever create a pending request.
class PaymentRepository {
  PaymentRepository(this._client);
  final SupabaseClient _client;

  /// Uploads the InstaPay transfer proof (if any) and inserts a pending
  /// payment request. Throws if not signed in.
  /// Generates the key that makes a submission retry-safe.
  ///
  /// Held by the submitting screen for the life of one attempt, so pressing
  /// "try again" after a dropped response re-sends the *same* key rather than
  /// filing a second claim for one bank transfer.
  static String newIdempotencyKey() {
    final random = Random.secure();
    return List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  Future<void> submitInstapay({
    required String purpose, // 'pro' | 'sponsored' | 'boost'
    String? planTerm, // 'monthly' | 'annual' (pro only)
    required int amountEgp,
    required String idempotencyKey,
    File? proofFile,
    Uint8List? proofBytes,
    String? reference,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw StateError('not signed in');

    String? proofPath;
    if (proofFile != null || proofBytes != null) {
      if (proofBytes != null) {
        UploadPolicy.validateImageBytes(proofBytes);
      }
      if (proofFile != null) {
        UploadPolicy.validateImageLength(await proofFile.length());
      }
      final name = '$uid/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storage = _client.storage.from('payment-proofs');
      if (proofFile != null) {
        await storage.upload(
          name,
          proofFile,
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'image/jpeg',
          ),
        );
      } else {
        await storage.uploadBinary(
          name,
          proofBytes!,
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'image/jpeg',
          ),
        );
      }
      proofPath = name;
    }

    try {
      await _client.from('payment_requests').insert({
        'contractor_id': uid,
        'method': 'instapay',
        'purpose': purpose,
        'plan_term': planTerm,
        'amount_egp': amountEgp,
        'proof_path': proofPath,
        'reference_text': reference,
        'status': 'pending',
        'idempotency_key': idempotencyKey,
      });
    } on PostgrestException catch (error) {
      // 23505 = unique_violation on payment_requests_idempotency_uidx: this
      // exact attempt already landed, and the caller is retrying because the
      // response was lost rather than because the write failed. The desired
      // end state — one pending claim for one transfer — already holds, so
      // report success. Rethrowing would show an error for a claim that was
      // filed, and push the contractor toward transferring twice.
      if (error.code != '23505') rethrow;
      return;
    }

    // The revenue funnel already emits `checkout_started` when someone opens
    // the flow, but nothing recorded them finishing it — so a contractor who
    // opened the sheet and gave up looked identical to one who transferred the
    // money. This closes that pair, and is the denominator an approval rate
    // gets computed against.
    //
    // `has_proof` matters operationally: an InstaPay claim with no screenshot
    // is the shape that gets rejected, and a rise in it is a UI problem rather
    // than a payment problem.
    //
    // No reference_text (a real bank transfer reference) and no proof_path.
    unawaited(
      AppAnalytics.track(
        'payment_request_submitted',
        properties: {
          'purpose': purpose,
          'plan_term': planTerm,
          'amount_egp': amountEgp,
          'has_proof': proofPath != null,
        },
      ),
    );
  }
}

final paymentRepositoryProvider = Provider<PaymentRepository>(
  (ref) => PaymentRepository(ref.watch(supabaseClientProvider)),
);
