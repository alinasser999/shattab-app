import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:batsh/features/home/presentation/widgets/reference_home_experience.dart';
import 'package:batsh/features/home/domain/reference_home_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:batsh/l10n/app_localizations.dart';
import '../support/homeowner_reference_harness.dart';

const folder = 'artifacts/agent-team/20261010-home-reference-clone/render';
Future<void> capture(WidgetTester tester, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('homeowner-qa-capture')),
  );
  final media = MediaQuery.of(
    tester.element(find.byType(ReferenceHomeExperience)),
  );
  final vertical = tester
      .state<ScrollableState>(find.byType(Scrollable).first)
      .position;
  final metadata = {
    'size': [media.size.width, media.size.height],
    'devicePixelRatio': media.devicePixelRatio,
    'textScale': media.textScaler.scale(1),
    'viewPadding': [media.viewPadding.top, media.viewPadding.bottom],
    'physicalPadding': [tester.view.padding.top, tester.view.padding.bottom],
    'scrollOffset': vertical.pixels,
    'maxScrollExtent': vertical.maxScrollExtent,
    'referencePreviewEnabled': referenceHomePreviewEnabled,
  };
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory(folder).create(recursive: true);
    await File('$folder/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
    await File(
      '$folder/$name.json',
    ).writeAsString(const JsonEncoder.withIndent('  ').convert(metadata));
    image.dispose();
  });
}

void main() {
  setUpAll(initializeHomeownerTestClient);
  testWidgets(
    'actual routed reference captures logical phone viewport and ordered sections',
    (tester) async {
      await pumpHomeownerReference(
        tester,
        size: const Size(393, 852),
        capture: true,
      );
      final context = tester.element(find.byType(ReferenceHomeExperience));
      await tester.runAsync(() async {
        for (final file
            in Directory('assets/images').listSync().whereType<File>().where(
              (f) => f.path
                  .split(Platform.pathSeparator)
                  .last
                  .startsWith('home_clone_'),
            )) {
          await precacheImage(
            AssetImage(file.path.replaceAll('\\', '/')),
            context,
          );
        }
      });
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(MediaQuery.sizeOf(context), const Size(393, 852));
      final keys = [
        'home-clone-featured',
        'home-clone-nearby',
        'home-clone-story',
        'home-clone-top-rated',
        'home-clone-kitchens',
        'home-clone-finishing',
        'home-clone-community',
      ];
      for (final key in keys) {
        expect(find.byKey(ValueKey(key)), findsOneWidget);
      }
      if (Platform.environment['SHATTAB_CAPTURE'] == '1') {
        await capture(tester, '01-opening-393');
        for (final entry in [
          ('home-clone-nearby', '02-nearby-story-393'),
          ('home-clone-top-rated', '03-ratings-kitchens-393'),
          ('home-clone-finishing', '04-finishing-community-393'),
        ]) {
          await Scrollable.ensureVisible(
            tester.element(find.byKey(ValueKey(entry.$1))),
            alignment: 0,
          );
          await tester.pumpAndSettle();
          await capture(tester, entry.$2);
        }
      }
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'iPhone15 safe inset simulation retains screen and bottom navigation',
    (tester) async {
      await pumpHomeownerReference(
        tester,
        size: const Size(393, 852),
        safeAreaInsets: const EdgeInsets.only(top: 59, bottom: 34),
        capture: true,
      );
      expect(tester.view.padding.top, 59);
      expect(tester.view.padding.bottom, 34);
      await tester.runAsync(() async {
        await precacheImage(
          const AssetImage(ReferenceHomePreviewData.heroImage),
          tester.element(find.byType(ReferenceHomeExperience)),
        );
      });
      await tester.pumpAndSettle();
      if (Platform.environment['SHATTAB_CAPTURE'] == '1') {
        await capture(tester, '05-opening-safe59-34-393');
      }
      expect(tester.takeException(), isNull);
    },
  );
  for (final width in [320.0, 360.0]) {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets(
        'reference width $width scale $scale reaches final action without overflow',
        (tester) async {
          await pumpHomeownerReference(
            tester,
            query: 'scenario=noactive&textScale=$scale',
            size: Size(width, 852),
            safeAreaInsets: const EdgeInsets.only(top: 59, bottom: 34),
            capture: true,
          );
          expect(tester.takeException(), isNull);
          await Scrollable.ensureVisible(
            tester.element(find.byKey(const ValueKey('home-clone-community'))),
            alignment: 1,
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          if (Platform.environment['SHATTAB_CAPTURE'] == '1' && scale == 1.3) {
            await capture(tester, 'community-${width.toInt()}-scale13');
          }
        },
      );
    }
  }
  testWidgets(
    'English enlarged long-name reference screenshot is actual Flutter',
    (tester) async {
      final container = await pumpHomeownerReference(
        tester,
        size: const Size(320, 852),
        capture: true,
        query: 'scenario=noactive&textScale=1.3',
        configureScenario: (scenario) {
          scenario.profile = scenario.profile.copyWith(
            fullName: 'Mariam Alexandria Long Homeowner Name',
          );
          scenario.homeownerProfile = scenario.homeownerProfile!.copyWith(
            city: 'New Cairo Extended Residential District',
          );
        },
      );
      final experience = tester.widget<ReferenceHomeExperience>(
        find.byType(ReferenceHomeExperience),
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: RepaintBoundary(
            key: const ValueKey('homeowner-qa-capture'),
            child: MaterialApp(
              locale: const Locale('en'),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: MediaQuery(
                data: const MediaQueryData(
                  size: Size(320, 852),
                  textScaler: TextScaler.linear(1.3),
                ),
                child: Scaffold(body: SingleChildScrollView(child: experience)),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      if (Platform.environment['SHATTAB_CAPTURE'] == '1') {
        await capture(tester, 'english-320-scale13');
      }
    },
  );
}
