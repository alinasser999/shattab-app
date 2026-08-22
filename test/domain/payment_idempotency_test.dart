import 'package:batsh/features/billing/data/payment_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dart:io';

/// The key is the only thing standing between a lost response and a contractor
/// being charged twice for one Pro subscription.
///
/// `payment_requests_idempotency_uidx` is UNIQUE(contractor_id,
/// idempotency_key), so two properties actually matter: keys must not repeat
/// across attempts (a collision would silently swallow a genuine second payment
/// as a duplicate), and a key must stay stable for the length of one attempt
/// (regenerating per tap defeats the constraint entirely — that half is
/// enforced by holding it as a `final` field in `_InstaPayScreenState`).
void main() {
  test('payment submission stays server-priced', () {
    final repository = File(
      'lib/features/billing/data/payment_repository.dart',
    ).readAsStringSync();
    final migration = File(
      'supabase/migrations/20260814103000_payment_submission_validation.sql',
    ).readAsStringSync();

    expect(repository, isNot(contains('amountEgp')));
    expect(repository, contains("'submit_payment_request'"));
    expect(repository, isNot(contains("from('payment_requests')")));
    expect(repository, contains('upsert: false'));
    expect(repository, isNot(contains('upsert: true')));
    expect(migration, contains('when \'monthly\' then 299'));
    expect(migration, contains('when \'annual\' then 2990'));
    expect(
      migration,
      contains('revoke all on function public.submit_payment_request'),
    );
  });

  group('PaymentRepository.newIdempotencyKey', () {
    test('is 32 hex characters', () {
      expect(
        PaymentRepository.newIdempotencyKey(),
        matches(RegExp(r'^[0-9a-f]{32}$')),
      );
    });

    test('pads bytes so length never varies', () {
      // Byte values below 0x10 render as a single hex digit unless padded.
      // Without the pad, keys are occasionally short — harmless for uniqueness,
      // but it makes a fixed-width column or a log parser wrong later.
      for (var i = 0; i < 200; i++) {
        expect(PaymentRepository.newIdempotencyKey().length, 32);
      }
    });

    test('does not repeat across many draws', () {
      // A repeat means a real payment is rejected as a duplicate of an
      // unrelated one. 128 bits from Random.secure() makes that impossible in
      // practice; this asserts the generator actually draws fresh bytes rather
      // than seeding once and returning a constant.
      final keys = List.generate(
        2000,
        (_) => PaymentRepository.newIdempotencyKey(),
      );
      expect(keys.toSet().length, keys.length);
    });
  });
}
