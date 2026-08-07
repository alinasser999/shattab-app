import 'package:batsh/core/theme/batsh_theme.dart';
import 'package:batsh/features/discovery/domain/contractor_listing.dart';
import 'package:batsh/features/discovery/presentation/widgets/featured_professional_card.dart';
import 'package:batsh/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const professional = ContractorListing(
  id: 'featured',
  fullName: 'أحمد المصري',
  businessName: 'الشركة المصرية الحديثة للتشطيبات والديكورات المتكاملة',
  phone: '',
  specialties: ['full_reno', 'design'],
  serviceAreas: ['القاهرة', 'الجيزة'],
  projectsCompleted: 200,
  reviewCount: 52,
  reviewAvg: 4.8,
  verified: true,
  yearsExperience: 15,
);

Future<void> pumpFeatured(
  WidgetTester tester, {
  required double width,
  double textScale = 1,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: BatshTheme.light(),
      home: Scaffold(
        body: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: FeaturedProfessionalCard(
              listing: professional,
              onTap: () {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('featured card uses the safe stacked layout at 320dp', (
    tester,
  ) async {
    await pumpFeatured(tester, width: 320);
    expect(tester.takeException(), isNull);
  });

  // The reference card is stacked at every width — cover, identity, stats,
  // trust, action — so this is the reference viewport, not a second layout.
  testWidgets('featured card lays out at the reference 390dp width', (
    tester,
  ) async {
    await pumpFeatured(tester, width: 390);
    expect(tester.takeException(), isNull);
  });

  testWidgets('featured card survives large text without clipping', (
    tester,
  ) async {
    await pumpFeatured(tester, width: 320, textScale: 1.5);
    expect(tester.takeException(), isNull);
  });
}
