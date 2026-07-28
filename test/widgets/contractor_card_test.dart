import 'package:batsh/core/theme/batsh_theme.dart';
import 'package:batsh/core/widgets/contractor_card.dart';
import 'package:batsh/features/discovery/domain/contractor_listing.dart';
import 'package:batsh/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ContractorListing listing({
  String businessName = 'مؤسسة النور للتشطيبات المتكاملة',
  List<String> specialties = const ['plumbing', 'electrical', 'painting'],
  List<String> serviceAreas = const ['القاهرة', 'الجيزة'],
  int projectsCompleted = 56,
  int? yearsExperience = 8,
  int reviewCount = 40,
  double reviewAvg = 4.8,
}) => ContractorListing(
  id: 'c1',
  fullName: 'محمد',
  businessName: businessName,
  phone: '+201000000000',
  specialties: specialties,
  serviceAreas: serviceAreas,
  projectsCompleted: projectsCompleted,
  reviewCount: reviewCount,
  reviewAvg: reviewAvg,
  verified: true,
  yearsExperience: yearsExperience,
  memberSince: DateTime(2020),
);

Future<void> pumpCard(
  WidgetTester tester,
  ContractorListing item, {
  Size size = const Size(360, 900),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: BatshTheme.light(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: ContractorCard(listing: item, onTap: () {}),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  // This card lost eight of its fourteen elements and then gained 4dp of
  // interior padding, and nothing rendered it at phone width in between. A
  // RenderFlex overflow throws during pump, so building it at 360dp is itself
  // the assertion.
  group('ContractorCard at 360dp', () {
    testWidgets('lays out without overflowing', (tester) async {
      await pumpCard(tester, listing());
      expect(tester.takeException(), isNull);
    });

    testWidgets('survives a long name and the maximum chip row', (
      tester,
    ) async {
      await pumpCard(
        tester,
        listing(
          businessName:
              'الشركة المصرية الحديثة للتشطيبات والديكورات الداخلية والخارجية',
          specialties: const [
            'plumbing',
            'electrical',
            'painting',
            'carpentry',
            'flooring',
          ],
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('survives a contractor with nothing to show', (tester) async {
      await pumpCard(
        tester,
        listing(
          specialties: const [],
          serviceAreas: const [],
          projectsCompleted: 0,
          yearsExperience: null,
          reviewCount: 0,
          reviewAvg: 0,
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('the name is never truncated', (tester) async {
      // The one string on the card that must arrive whole: it is the
      // contractor's identity, and it is why the name moved off the photo.
      await pumpCard(tester, listing());
      final name = tester.widget<Text>(
        find.text('مؤسسة النور للتشطيبات المتكاملة'),
      );
      expect(name.overflow, isNot(TextOverflow.ellipsis));
      expect(name.maxLines, 2);
    });
  });
}
