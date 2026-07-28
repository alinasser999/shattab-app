import 'package:batsh/features/discovery/domain/contractor_listing.dart';
import 'package:batsh/features/discovery/domain/trust_signals.dart';
import 'package:batsh/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<BuildContext> getContext(WidgetTester tester) async {
  late BuildContext ctx;
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (c) {
          ctx = c;
          return const SizedBox();
        },
      ),
    ),
  );
  return ctx;
}

/// `TrustProfile` decides what every trust surface claims about a professional.
/// Two ways that goes wrong, and both are worse than showing nothing:
///
/// - inventing a signal (a "0 مشاريع" tile, a "100%" response rate read from a
///   column that defaults to 100), which brands a new account as a bad one, or
/// - stacking every distinction at once, which teaches the reader that badges
///   on this platform are decoration.
ContractorListing listing({
  bool verified = false,
  int projectsCompleted = 0,
  int reviewCount = 0,
  double reviewAvg = 0,
  int? yearsExperience,
  DateTime? memberSince,
}) => ContractorListing(
  id: 'c1',
  fullName: 'Test',
  businessName: 'Test',
  phone: '+201000000000',
  specialties: const [],
  serviceAreas: const [],
  projectsCompleted: projectsCompleted,
  reviewCount: reviewCount,
  reviewAvg: reviewAvg,
  verified: verified,
  yearsExperience: yearsExperience,
  memberSince: memberSince,
);

void main() {
  group('verification ladder', () {
    testWidgets('an unchecked account claims nothing', (tester) async {
      final context = await getContext(tester);
      expect(
        TrustProfile.of(context, listing()).verification,
        VerificationLevel.none,
      );
    });

    testWidgets('a checked account claims identity, not business', (
      tester,
    ) async {
      final context = await getContext(tester);
      // `business` is deliberately unreachable. There is no column behind it,
      // and the higher rung must never be inferred from the lower one.
      expect(
        TrustProfile.of(context, listing(verified: true)).verification,
        VerificationLevel.identity,
      );
    });
  });

  group('metrics', () {
    testWidgets('a brand-new account produces no tiles at all', (tester) async {
      final context = await getContext(tester);
      final trust = TrustProfile.of(context, listing());
      expect(trust.metrics, isEmpty);
      expect(trust.hasMetrics, isFalse);
      expect(trust.isColdStart, isTrue);
    });

    testWidgets('zero completed projects is an absence, not a zero', (
      tester,
    ) async {
      final context = await getContext(tester);
      final kinds = TrustProfile.of(
        context,
        listing(projectsCompleted: 0),
      ).metrics.map((m) => m.kind);
      expect(kinds, isNot(contains(TrustSignalKind.projectsCompleted)));
    });

    testWidgets('zero years of experience is an absence too', (tester) async {
      final context = await getContext(tester);
      final kinds = TrustProfile.of(
        context,
        listing(projectsCompleted: 4, yearsExperience: 0),
      ).metrics.map((m) => m.kind);
      expect(kinds, isNot(contains(TrustSignalKind.yearsExperience)));
    });

    testWidgets('completed work leads the order', (tester) async {
      final context = await getContext(tester);
      final trust = TrustProfile.of(
        context,
        listing(projectsCompleted: 6, yearsExperience: 12),
      );
      expect(trust.metrics.first.kind, TrustSignalKind.projectsCompleted);
      expect(trust.metrics.length, 2);
    });

    testWidgets('every signal carries a label a screen reader can read', (
      tester,
    ) async {
      final context = await getContext(tester);
      final trust = TrustProfile.of(
        context,
        listing(projectsCompleted: 3, yearsExperience: 5),
      );
      expect(trust.metrics, isNotEmpty);
      for (final signal in trust.metrics) {
        expect(signal.label, isNotEmpty);
        expect(signal.semanticLabel, contains(signal.value));
      }
    });
  });

  group('highlight', () {
    testWidgets('none by default', (tester) async {
      final context = await getContext(tester);
      expect(TrustProfile.of(context, listing()).highlight, isNull);
    });

    testWidgets('top rated needs both a high average and enough reviews', (
      tester,
    ) async {
      final context = await getContext(tester);
      expect(
        TrustProfile.of(
          context,
          listing(reviewAvg: 4.9, reviewCount: 5),
        ).highlight,
        TrustHighlight.topRated,
      );
      // Same average, one review. A single five-star is not a distinction.
      expect(
        TrustProfile.of(
          context,
          listing(reviewAvg: 5, reviewCount: 1),
        ).highlight,
        isNull,
      );
    });

    testWidgets('a long record earns a distinction without any reviews', (
      tester,
    ) async {
      final context = await getContext(tester);
      expect(
        TrustProfile.of(context, listing(projectsCompleted: 10)).highlight,
        TrustHighlight.established,
      );
    });

    testWidgets('the strongest claim wins rather than stacking', (
      tester,
    ) async {
      final context = await getContext(tester);
      final trust = TrustProfile.of(
        context,
        listing(reviewAvg: 4.9, reviewCount: 20, projectsCompleted: 40),
      );
      expect(trust.highlight, TrustHighlight.topRated);
    });
  });

  group('formatting', () {
    test('percentages round and clamp', () {
      expect(formatPercent(0.875), '88%');
      expect(formatPercent(1.4), '100%');
      expect(formatPercent(-0.2), '0%');
    });
  });
}
