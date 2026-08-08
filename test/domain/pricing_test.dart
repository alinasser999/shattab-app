import 'package:batsh/features/billing/pricing.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the numbers money is actually charged against.
///
/// `BatshPricing` is the single source of truth for monetization, read by the
/// Pro page, the paywall, the promote sheet and the payment flow. Nothing else
/// in the suite touched it, so a typo in a constant — an annual price below the
/// monthly one, a quota of zero — would have reached a real contractor's screen
/// and a real InstaPay transfer before anyone noticed.
///
/// These are deliberately *relationship* assertions rather than a second copy
/// of each number. Restating `proMonthlyEgp == 299` here would only assert that
/// someone typed the same thing twice, and would fail on every intentional
/// price change; asserting that the annual term stays a discount survives
/// repricing and still catches the mistake that matters.
void main() {
  group('BatshPricing', () {
    test('every published price is a positive amount', () {
      expect(BatshPricing.proMonthlyEgp, greaterThan(0));
      expect(BatshPricing.proAnnualEgp, greaterThan(0));
      expect(BatshPricing.featuredWeekEgp, greaterThan(0));
      expect(BatshPricing.quoteBoostJobEgp, greaterThan(0));
    });

    test('annual is cheaper than paying monthly for a year', () {
      // The whole reason the annual term exists. If a repricing ever inverts
      // this, the app advertises a discount that charges more.
      expect(
        BatshPricing.proAnnualEgp,
        lessThan(BatshPricing.proMonthlyEgp * 12),
      );
    });

    test('annual discount stays in a believable band', () {
      // Documented intent is "~2 months free". A number far outside that band
      // is more likely a missing or extra digit than a deliberate promotion.
      final monthlyForAYear = BatshPricing.proMonthlyEgp * 12;
      final saving = monthlyForAYear - BatshPricing.proAnnualEgp;
      final ratio = saving / monthlyForAYear;
      expect(ratio, greaterThan(0.05));
      expect(ratio, lessThan(0.5));
    });

    test('proPrice returns the term it was asked for', () {
      expect(BatshPricing.proPrice(annual: true), BatshPricing.proAnnualEgp);
      expect(BatshPricing.proPrice(annual: false), BatshPricing.proMonthlyEgp);
    });

    test('free tier grants something but not everything', () {
      // A quota of 0 silently bricks the free tier: a contractor could never
      // send a first quote and the paywall would be the entire product. An
      // unbounded quota gives away the thing Pro is sold on.
      expect(BatshPricing.freeMonthlyQuota, greaterThan(0));
      expect(BatshPricing.freeMonthlyQuota, lessThan(50));
      expect(BatshPricing.freePortfolioCap, greaterThan(0));
      expect(BatshPricing.freePortfolioCap, lessThan(100));
    });

    test('the InstaPay handle is a plausible Egyptian mobile number', () {
      // Contractors transfer real money to this string. A truncated or
      // reformatted one sends payments into the void, and the failure is
      // invisible in-app — it surfaces as payment requests that never arrive.
      const number = BatshPricing.instapayNumber;
      expect(number, matches(RegExp(r'^01[0125]\d{8}$')));
      expect(number.length, 11);
    });
  });
}
