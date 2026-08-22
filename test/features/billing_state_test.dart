import 'package:flutter_test/flutter_test.dart';
import 'package:batsh/features/billing/domain/billing_state.dart';

void main() {
  group('BillingState', () {
    test('treats only an unexpired server Pro plan as active', () {
      final active = BillingState.fromJson({
        'plan': 'pro',
        'plan_expires_at': DateTime.now()
            .add(const Duration(days: 2))
            .toUtc()
            .toIso8601String(),
      });
      final expired = BillingState.fromJson({
        'plan': 'pro',
        'plan_expires_at': DateTime.now()
            .subtract(const Duration(seconds: 1))
            .toUtc()
            .toIso8601String(),
      });
      final free = BillingState.fromJson({'plan': 'free'});

      expect(active.isProActive, isTrue);
      expect(expired.isProActive, isFalse);
      expect(free.isProActive, isFalse);
    });

    test('exposes a pending Pro request without treating it as active', () {
      final state = BillingState.fromJson({
        'plan': 'free',
        'latest_request': {
          'id': 'request-1',
          'status': 'pending',
          'purpose': 'pro',
          'amount_egp': 299,
        },
      });

      expect(state.hasPendingProRequest, isTrue);
      expect(state.isProActive, isFalse);
      expect(state.latestRequest?.amountEgp, 299);
    });

    test('ignores an unrelated pending request', () {
      final state = BillingState.fromJson({
        'plan': 'free',
        'latest_request': {
          'id': 'request-2',
          'status': 'pending',
          'purpose': 'boost',
        },
      });

      expect(state.hasPendingProRequest, isFalse);
    });

    test(
      'keeps Special Pro placement separate from the subscription state',
      () {
        final active = BillingState.fromJson({
          'plan': 'free',
          'sponsored_until': DateTime.now()
              .add(const Duration(days: 4))
              .toUtc()
              .toIso8601String(),
        });
        final pending = BillingState.fromJson({
          'latest_request': {
            'id': 'placement-1',
            'status': 'pending',
            'purpose': 'sponsored',
          },
        });

        expect(active.isSponsoredActive, isTrue);
        expect(active.isProActive, isFalse);
        expect(pending.hasPendingSponsoredRequest, isTrue);
        expect(pending.hasPendingProRequest, isFalse);
      },
    );

    test(
      'does not turn an empty server placeholder into a pending request',
      () {
        final state = BillingState.fromJson({
          'plan': 'free',
          'latest_request': <String, dynamic>{},
          'latest_payment': <String, dynamic>{},
        });

        expect(state.latestRequest, isNull);
        expect(state.latestPayment, isNull);
        expect(state.hasPendingProRequest, isFalse);
      },
    );
  });
}
