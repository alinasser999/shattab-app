import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_provider.dart';

/// Writes manual-transfer payment claims. Feature grant is NOT done here — an
/// admin approves the pending row via `approve_payment_request()` (service role),
/// which flips the plan. The client can only ever create a pending request.
class PaymentRepository {
  PaymentRepository(this._client);
  final SupabaseClient _client;

  /// Uploads the InstaPay transfer proof (if any) and inserts a pending
  /// payment request. Throws if not signed in.
  Future<void> submitInstapay({
    required String purpose, // 'pro' | 'sponsored' | 'boost'
    String? planTerm, // 'monthly' | 'annual' (pro only)
    required int amountEgp,
    File? proofFile,
    Uint8List? proofBytes,
    String? reference,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw StateError('not signed in');

    String? proofPath;
    if (proofFile != null || proofBytes != null) {
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

    await _client.from('payment_requests').insert({
      'contractor_id': uid,
      'method': 'instapay',
      'purpose': purpose,
      'plan_term': planTerm,
      'amount_egp': amountEgp,
      'proof_path': proofPath,
      'reference_text': reference,
      'status': 'pending',
    });
  }
}

final paymentRepositoryProvider = Provider<PaymentRepository>(
  (ref) => PaymentRepository(ref.watch(supabaseClientProvider)),
);
