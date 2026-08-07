import 'package:batsh/core/theme/batsh_theme.dart';
import 'package:batsh/core/widgets/batsh_error.dart';
import 'package:batsh/features/briefs/domain/brief.dart';
import 'package:batsh/features/briefs/domain/opportunity_experience.dart';
import 'package:batsh/features/briefs/presentation/contractor/job_opportunities_screen.dart';
import 'package:batsh/features/briefs/presentation/contractor/widgets/job_card.dart';
import 'package:batsh/features/briefs/presentation/contractor/widgets/opportunity_radar_card.dart';
import 'package:batsh/features/onboarding/domain/onboarding_models.dart';
import 'package:batsh/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Brief _brief({String description = 'تشطيب شقة كاملة'}) => Brief(
  id: 'brief-1',
  homeownerId: 'homeowner-1',
  apartmentType: ApartmentType.twoBedroom,
  city: 'القاهرة',
  district: 'المعادي',
  workDescription: description,
  photoUrls: const [],
  targetSpecialties: const ['full_reno'],
  status: BriefStatus.open,
  createdAt: DateTime(2026, 8, 1, 8),
);

Future<void> _pumpCard(
  WidgetTester tester, {
  String description = 'تشطيب شقة كاملة',
  VoidCallback? onTap,
  VoidCallback? onSave,
  Size size = const Size(320, 800),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ar'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: BatshTheme.light(),
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: OpportunityCard(
            brief: _brief(description: description),
            match: const OpportunityMatch(
              rank: 85,
              reasons: [
                OpportunityRecommendationReason.specialtyMatch,
                OpportunityRecommendationReason.serviceAreaMatch,
              ],
            ),
            onTap: onTap ?? () {},
            onSave: onSave ?? () {},
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('card keeps its hierarchy without overflowing at 320dp', (
    tester,
  ) async {
    await _pumpCard(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('شوف التفاصيل'), findsOneWidget);
    expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
    expect(find.bySemanticsLabel('حفظ الفرصة'), findsOneWidget);
  });

  testWidgets('long titles truncate safely and actions remain separate', (
    tester,
  ) async {
    var detailsTapped = false;
    var saveTapped = false;

    await _pumpCard(
      tester,
      description:
          'تشطيب شقة كاملة وتجهيز شامل للمطبخ والحمام والدهانات والأرضيات والتفاصيل الداخلية',
      onTap: () => detailsTapped = true,
      onSave: () => saveTapped = true,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('شوف التفاصيل'), findsOneWidget);

    await tester.tap(find.byTooltip('حفظ الفرصة'));
    await tester.tap(find.text('شوف التفاصيل'));

    expect(saveTapped, isTrue);
    expect(detailsTapped, isTrue);
  });

  testWidgets('card remains stable across supported phone widths', (
    tester,
  ) async {
    for (final width in [360.0, 390.0, 430.0]) {
      await _pumpCard(tester, size: Size(width, 800));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('compact summary remains usable at 320dp', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: BatshTheme.light(),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: OpportunitySummaryCard(
              metrics: const OpportunityFeedMetrics(
                matchingCount: 12,
                freshCount: 4,
                areaCount: 8,
              ),
              preferencesCompletion: 50,
              onPreferencesTap: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('ملخص فرص الشغل'), findsOneWidget);
  });

  testWidgets('radar sweep settles without overflowing at 320dp', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: BatshTheme.light(),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: OpportunityRadarCard(
              metrics: const OpportunityRadarMetrics(
                matchingCount: 12,
                areaCount: 8,
                freshCount: 4,
                weekCount: 10,
                photoCount: 6,
              ),
              preferencesCompletion: 100,
              onPreferencesTap: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 450));
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('feed error recovery action does not overflow at 320dp', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: BatshTheme.light(),
        home: Scaffold(
          body: BatshError(message: 'الخدمة مش شغالة دلوقتي', onRetry: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('حاول تاني'), findsOneWidget);
  });
}
