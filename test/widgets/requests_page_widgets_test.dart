import 'package:batsh/core/theme/batsh_theme.dart';
import 'package:batsh/features/briefs/domain/brief.dart';
import 'package:batsh/features/inbox/presentation/widgets/requests_page_widgets.dart';
import 'package:batsh/features/onboarding/domain/onboarding_models.dart';
import 'package:batsh/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Brief _brief({String description = 'تشطيب شقة كاملة'}) => Brief(
  id: 'brief-1',
  homeownerId: 'homeowner-1',
  apartmentType: ApartmentType.twoBedroom,
  city: 'القاهرة',
  district: 'مدينة نصر',
  workDescription: description,
  photoUrls: const [],
  targetSpecialties: const ['full_reno'],
  status: BriefStatus.open,
  createdAt: DateTime(2026, 8, 1),
);

Widget _app(Widget child) => MaterialApp(
  locale: const Locale('ar'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: BatshTheme.light(),
  home: Scaffold(
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: child,
    ),
  ),
);

void main() {
  testWidgets('locked request protects contact details at narrow width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(LockedRequestCard(request: _brief(), locked: true, onTap: () {})),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('متاح مع برو'), findsOneWidget);
    expect(find.text('بيانات التواصل محمية'), findsNWidgets(2));
    expect(find.text('تشطيب شقة كاملة'), findsOneWidget);
  });

  testWidgets('plan selector updates the configured price', (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    var annual = false;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) => RequestsProConversionCard(
            annual: annual,
            onAnnualChanged: (value) => setState(() => annual = value),
            onSubscribe: () {},
            isLoading: false,
            trialAvailable: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('٢٩٩'), findsOneWidget);
    await tester.tap(find.text('سنوي'));
    await tester.pumpAndSettle();

    expect(find.textContaining('٢٩٩٠'), findsOneWidget);
    expect(find.textContaining('وفّرت'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('usage banner exposes the Pro state', (tester) async {
    await tester.pumpWidget(_app(const RequestsUsageBanner(isPro: true)));
    await tester.pumpAndSettle();

    expect(find.text('اشتراك برو مفعّل — عروضك وطلباتك متاحة'), findsOneWidget);
    expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
  });
}
