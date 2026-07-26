import 'package:flutter_test/flutter_test.dart';

/// The send-quote CTA chooses between "send" and "upgrade" from the quota
/// record. The rule is small but it fails in both directions: too strict and a
/// paying contractor sees a paywall, too loose and free quotes are unlimited.
/// This mirrors the predicate in `contractor_quote_cta.dart`, which in turn
/// mirrors the RLS policy in 0025.
bool canSend({required ({bool isPro, int used, int quota})? q}) {
  if (q == null) return true; // still loading — assume allowed
  if (q.isPro) return true;
  return (q.quota - q.used) > 0;
}

int? remaining(({bool isPro, int used, int quota})? q) =>
    q == null ? null : (q.quota - q.used).clamp(0, 9999);

void main() {
  group('quote quota gating', () {
    test('Pro sends regardless of how many quotes were used', () {
      expect(canSend(q: (isPro: true, used: 999, quota: 5)), isTrue);
    });

    test('free contractor with unused quota can send', () {
      expect(canSend(q: (isPro: false, used: 0, quota: 5)), isTrue);
      expect(remaining((isPro: false, used: 0, quota: 5)), 5);
    });

    test('free contractor on the last quote can still send', () {
      expect(canSend(q: (isPro: false, used: 4, quota: 5)), isTrue);
      expect(remaining((isPro: false, used: 4, quota: 5)), 1);
    });

    test('free contractor at the cap is blocked', () {
      expect(canSend(q: (isPro: false, used: 5, quota: 5)), isFalse);
      expect(remaining((isPro: false, used: 5, quota: 5)), 0);
    });

    test('over-cap never reports negative remaining', () {
      // Reachable if the cap is lowered while someone is over it. The counter
      // must not read "-2 quotes left".
      expect(canSend(q: (isPro: false, used: 7, quota: 5)), isFalse);
      expect(remaining((isPro: false, used: 7, quota: 5)), 0);
    });

    test('while loading, sending is allowed', () {
      // Flashing a paywall at a paying contractor is worse than a rejected
      // insert, which the quote sheet already surfaces.
      expect(canSend(q: null), isTrue);
      expect(remaining(null), isNull);
    });

    test('no contractor profile means no allowance', () {
      // fetchQuota returns quota 0 when the RPC yields no row.
      expect(canSend(q: (isPro: false, used: 0, quota: 0)), isFalse);
    });
  });
}
