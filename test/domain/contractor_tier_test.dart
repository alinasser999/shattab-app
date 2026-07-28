import 'package:batsh/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:batsh/features/discovery/domain/contractor_listing.dart';
import 'package:flutter_test/flutter_test.dart';

/// The tier is now shown to homeowners, not only to the contractor themselves,
/// so the thresholds became a public trust claim. Two ways it goes wrong: gold
/// reachable without verification (a claim the app cannot back), or bronze
/// leaking onto a card and branding every new account "lowest of three".
ContractorListing listing({
  bool verified = false,
  int projectsCompleted = 0,
  int reviewCount = 0,
  String plan = 'free',
}) => ContractorListing(
  id: 'c1',
  fullName: 'Test',
  businessName: 'Test',
  phone: '+201000000000',
  specialties: const [],
  serviceAreas: const [],
  projectsCompleted: projectsCompleted,
  reviewCount: reviewCount,
  verified: verified,
  plan: plan,
);

void main() {
  group('ContractorTier', () {
    test('gold requires verification plus a track record', () {
      expect(
        listing(verified: true, projectsCompleted: 10).tier,
        ContractorTier.gold,
      );
      expect(listing(verified: true, reviewCount: 5).tier, ContractorTier.gold);
    });

    test('a track record alone never reaches gold', () {
      expect(
        listing(projectsCompleted: 50, reviewCount: 50).tier,
        ContractorTier.silver,
      );
    });

    test('paying for Pro moves nothing', () {
      // The whole point of the badge: money must not buy it.
      expect(listing(plan: 'pro').tier, ContractorTier.bronze);
      expect(
        listing(plan: 'pro', projectsCompleted: 10).tier,
        ContractorTier.silver,
      );
    });

    test('silver comes from three jobs or from verification', () {
      expect(listing(projectsCompleted: 3).tier, ContractorTier.silver);
      expect(listing(verified: true).tier, ContractorTier.silver);
    });

    test('a brand-new account is bronze and stays off public surfaces', () {
      expect(listing().tier, ContractorTier.bronze);
      expect(ContractorTier.bronze.isPublic, isFalse);
      expect(ContractorTier.silver.isPublic, isTrue);
      expect(ContractorTier.gold.isPublic, isTrue);
    });

    testWidgets('every tier has a label', (tester) async {
      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (c) {
              context = c;
              return const SizedBox();
            },
          ),
        ),
      );
      for (final t in ContractorTier.values) {
        expect(t.label(context), isNotEmpty);
      }
    });
  });
}
