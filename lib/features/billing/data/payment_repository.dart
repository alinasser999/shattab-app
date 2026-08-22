import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/analytics/app_analytics.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/utils/image_compression.dart';
import '../../../core/utils/upload_policy.dart';
import '../domain/billing_state.dart';

/// Writes manual-transfer payment claims.
///
/// The client can only submit a pending claim. The database RPC owns the
/// amount and contractor identity; an admin approves the claim separately.
class PaymentRepository {
  PaymentRepository(this._client);
  final SupabaseClient _client;

  /// Reads the server-owned subscription snapshot in one round trip.
  Future<BillingState> fetchBillingState() async {
    if (_client.auth.currentUser?.id == null) return const BillingState();

    final result = await _client
        .rpc('get_my_billing_state')
        .timeout(const Duration(seconds: 12));
    if (result is Map) {
      return BillingState.fromJson(Map<String, dynamic>.from(result));
    }
    throw StateError('Unexpected billing state response');
  }

  /// Generates a key that makes one submission retry-safe.
  static String newIdempotencyKey() {
    final random = Random.secure();
    return List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  Future<void> submitInstapay({
    required String purpose,
    String? planTerm,
    required String idempotencyKey,
    File? proofFile,
    Uint8List? proofBytes,
    String? reference,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw StateError('not signed in');

    String? proofPath;
    if (proofFile != null || proofBytes != null) {
      final uploadBytes = proofFile != null
          ? await ImageCompression.prepare(await proofFile.readAsBytes())
          : await ImageCompression.prepare(proofBytes!);
      UploadPolicy.validateImageBytes(uploadBytes);
      final name = '$uid/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storage = _client.storage.from('payment-proofs');
      await storage
          .uploadBinary(
            name,
            uploadBytes,
            fileOptions: const FileOptions(
              // Proof paths are unique per submission. Insert-only uploads
              // match the bucket's least-privilege RLS contract and avoid
              // requiring UPDATE permission on private payment evidence.
              upsert: false,
              contentType: 'image/jpeg',
            ),
          )
          .timeout(const Duration(seconds: 30));
      proofPath = name;
    }

    // The RPC owns the price, allowed purpose/term, auth identity, and
    // idempotency lookup. No client-supplied amount reaches the table.
    await _client
        .rpc(
          'submit_payment_request',
          params: {
            'p_method': 'instapay',
            'p_purpose': purpose,
            'p_plan_term': planTerm,
            'p_proof_path': proofPath,
            'p_reference_text': reference,
            'p_idempotency_key': idempotencyKey,
          },
        )
        .timeout(const Duration(seconds: 15));

    unawaited(
      AppAnalytics.track(
        'payment_request_submitted',
        properties: {
          'purpose': purpose,
          'plan_term': planTerm,
          'has_proof': proofPath != null,
        },
      ),
    );
  }
}

final paymentRepositoryProvider = Provider<PaymentRepository>(
  (ref) => PaymentRepository(ref.watch(supabaseClientProvider)),
);
