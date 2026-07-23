/// Single source of truth for monetization numbers. Tunable business config.
/// Mirrors migration `0013_monetization` (contractor_profiles.plan / quotes gate).
/// Change a price here and every surface (Pro page, paywall, promote) follows.
class BatshPricing {
  const BatshPricing._();

  /// Free contractors may send this many quotes per calendar month.
  static const int freeMonthlyQuota = 3;

  /// Free-tier portfolio project cap.
  static const int freePortfolioCap = 5;

  /// Pro subscription (EGP).
  static const int proMonthlyEgp = 299;
  static const int proAnnualEgp = 2990; // ~2 months free vs paying monthly

  /// Sponsored placement (EGP).
  static const int featuredWeekEgp = 199;
  static const int quoteBoostJobEgp = 49;
}
