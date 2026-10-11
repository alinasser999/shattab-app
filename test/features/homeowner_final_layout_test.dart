import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show debugPrintSynchronously;
import 'package:batsh/features/home/presentation/widgets/reference_home_experience.dart';
import 'package:batsh/core/l10n/l10n_extension.dart';
import 'package:batsh/features/discovery/domain/contractor_listing.dart';
import 'package:batsh/features/discovery/domain/professional_reference_fixture.dart';
import 'package:batsh/features/discovery/presentation/providers/discovery_providers.dart';
import 'package:batsh/features/explore/domain/post.dart';
import 'package:batsh/features/explore/presentation/providers/explore_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/homeowner_reference_harness.dart';

const _folder = 'artifacts/agent-team/20261006-home-scroll/screenshots';
Future<void> _capture(WidgetTester tester, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('homeowner-qa-capture')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory(_folder).create(recursive: true);
    await File('$_folder/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(initializeHomeownerTestClient);
  testWidgets(
    'long professional identity and community caption remain reachable at360 scale2',
    (tester) async {
      await pumpHomeownerReference(
        tester,
        query: 'scenario=noactive&textScale=2',
        size: const Size(360, 844),
        nativeSafeAreas: true,
        extraOverrides: [
          topRatedProfessionalsProvider.overrideWith(
            () => _PhotoListings(longContent: true),
          ),
          exploreFeedProvider.overrideWithValue(
            AsyncData([
              Post(
                id: 'fixture-long-caption',
                authorId: 'fixture-long-author',
                authorRole: 'homeowner',
                postType: PostType.tip,
                caption:
                    'هذه تجربة طويلة جدًا لاختبار ظهور النص العربي بالكامل في بطاقة المجتمع مع تكبير الخط وإمكانية الوصول لجميع تفاصيلها.',
                authorName: 'عضو تجريبي باسم طويل جدًا لاختبار العرض',
                createdAt: DateTime.utc(2026),
              ),
            ]),
          ),
        ],
      );
      for (var i = 0; i < 7; i++) {
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -800));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    },
  );
  for (final scenario in ['active', 'error', 'loading', 'noactive']) {
    testWidgets('truthful state $scenario remains rendered', (tester) async {
      await pumpHomeownerReference(
        tester,
        query: 'scenario=$scenario',
        nativeSafeAreas: true,
        capture: true,
        settle: scenario != 'loading',
      );
      await tester.runAsync(() async {
        await precacheImage(
          const AssetImage('assets/images/homeowner_arch_hero.png'),
          tester.element(find.byType(ReferenceHomeExperience)),
        );
      });
      await tester.pump(const Duration(milliseconds: 50));
      await _capture(tester, 'state-$scenario-390');
      expect(tester.takeException(), isNull);
      if (scenario == 'loading' || scenario == 'error') {
        expect(
          find.byKey(const ValueKey('homeowner-start-project-card')),
          findsNothing,
        );
      }
      if (scenario == 'active') {
        expect(
          tester
              .widget<ReferenceHomeExperience>(
                find.byType(ReferenceHomeExperience),
              )
              .project,
          isNotNull,
        );
      }
    });
  }
  testWidgets(
    'explicit illustrative two-column community and photo rail capture',
    (tester) async {
      await pumpHomeownerReference(
        tester,
        query: 'scenario=noactive&notificationState=empty',
        nativeSafeAreas: true,
        capture: true,
        extraOverrides: [
          topRatedProfessionalsProvider.overrideWith(() => _PhotoListings()),
          exploreFeedProvider.overrideWithValue(
            AsyncData([
              for (final index in [1, 2])
                Post(
                  id: 'fixture-qa-post-$index',
                  authorId: 'fixture-qa-author-$index',
                  authorRole: 'homeowner',
                  postType: PostType.tip,
                  caption: 'محتوى تجريبي لمقارنة تصميم المجتمع.',
                  authorName: 'عضو تجريبي $index',
                  createdAt: DateTime.utc(2026),
                  mediaUrls: [
                    index == 1
                        ? ProfessionalReferenceFixture.livingRoomImage
                        : ProfessionalReferenceFixture.bedroomImage,
                  ],
                ),
            ]),
          ),
        ],
      );
      await tester.runAsync(() async {
        for (final path in [
          ProfessionalReferenceFixture.livingRoomImage,
          ProfessionalReferenceFixture.bedroomImage,
        ]) {
          await precacheImage(
            AssetImage(path),
            tester.element(find.byType(ReferenceHomeExperience)),
          );
        }
      });
      await tester.pumpAndSettle();
      final top = find.text(
        tester.element(find.byType(ReferenceHomeExperience)).l10n.topRated,
      );
      await Scrollable.ensureVisible(tester.element(top), alignment: 0.1);
      await tester.pumpAndSettle();
      await _capture(tester, 'illustrative-scroll-390');
      final tiles = find.byWidgetPredicate(
        (w) => w.runtimeType.toString() == '_CommunityCard',
      );
      expect(tiles, findsNWidgets(2));
      final first = tester.getRect(tiles.at(0));
      final second = tester.getRect(tiles.at(1));
      expect(first.top, second.top);
      expect(first.width, 169);
      expect((first.left - second.left).abs(), 181);
      debugPrintSynchronously('QA community two-column: $first / $second');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('long Arabic identity and location reflow at 360 scale2', (
    tester,
  ) async {
    await pumpHomeownerReference(
      tester,
      query: 'scenario=noactive&textScale=2',
      size: const Size(360, 844),
      nativeSafeAreas: true,
      configureScenario: (scenario) {
        scenario.profile = scenario.profile.copyWith(
          fullName: 'مريم أحمد عبد الرحمن محمد محمود الطويل',
        );
        scenario.homeownerProfile = scenario.homeownerProfile!.copyWith(
          city: 'مدينة القاهرة الجديدة والمنطقة العمرانية الممتدة',
          district: 'التجمع الخامس والامتداد الشرقي',
        );
      },
    );
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -1000));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('390 native safe areas reference anchors and scroll captures', (
    tester,
  ) async {
    await pumpHomeownerReference(
      tester,
      query: 'scenario=noactive&notificationState=empty',
      nativeSafeAreas: true,
      capture: true,
    );
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/images/homeowner_arch_hero.png'),
        tester.element(find.byType(ReferenceHomeExperience)),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await _capture(tester, 'home-390');
    final hero = tester.getRect(
      find.byKey(const ValueKey('homeowner-architectural-hero')),
    );
    final starter = tester.getRect(
      find.byKey(const ValueKey('homeowner-start-project-card')),
    );
    debugPrintSynchronously('QA anchors hero=$hero starter=$starter');
    expect(hero.left, 16);
    expect(hero.top, 92);
    expect(hero.width, 358);
    expect(hero.height, inInclusiveRange(132, 160));
    expect(starter.top, greaterThan(hero.bottom));
    expect(starter.height, inInclusiveRange(104, 240));
    for (final label in ['تشطيبات', 'تصميم', 'مطابخ', 'كهرباء', 'سباكة']) {
      expect(find.text(label), findsWidgets);
      expect(
        tester.getRect(find.text(label).first).bottom,
        lessThanOrEqualTo(starter.top),
      );
    }
    final workHeading = find.text(
      tester
          .element(find.byType(ReferenceHomeExperience))
          .l10n
          .homeownerReferenceWorkTitle,
    );
    await Scrollable.ensureVisible(tester.element(workHeading), alignment: 0);
    await tester.pumpAndSettle();
    await _capture(tester, 'work-390');
    final workCard = tester.getRect(
      find.byWidgetPredicate((w) => w.runtimeType.toString() == '_WorkStory'),
    );
    debugPrintSynchronously('QA work card: $workCard');
    expect(workCard.width, 358);
    expect(workCard.height, inInclusiveRange(100, 400));
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 1500));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -870));
    await tester.pumpAndSettle();
    await _capture(tester, 'scroll-390');
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -520));
    await tester.pumpAndSettle();
    await _capture(tester, 'community-390');
    expect(tester.takeException(), isNull);
  });
  for (final width in [360.0, 390.0, 430.0]) {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('native-safe home no overflow width $width scale $scale', (
        tester,
      ) async {
        await pumpHomeownerReference(
          tester,
          query: 'scenario=noactive&textScale=$scale',
          size: Size(width, 844),
          nativeSafeAreas: true,
        );
        expect(tester.takeException(), isNull);
        expect(find.byType(ReferenceHomeExperience), findsOneWidget);
        for (var i = 0; i < 5; i++) {
          await tester.drag(
            find.byType(Scrollable).first,
            const Offset(0, -650),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      });
    }
  }
}

class _PhotoListings extends TopRatedProfessionals {
  _PhotoListings({this.longContent = false});
  final bool longContent;
  @override
  Future<List<ContractorListing>> build() async => [
    for (final i in [1, 2])
      ContractorListing(
        id: 'fixture-qa-professional-$i',
        fullName: longContent
            ? 'محترف تجريبي باسم طويل جدًا لاختبار عرض جميع التفاصيل $i'
            : 'محترف تجريبي $i',
        businessName: longContent
            ? 'محترف تجريبي باسم طويل جدًا لاختبار عرض جميع التفاصيل $i'
            : 'محترف تجريبي $i',
        specialties: ['design'],
        serviceAreas: [
          longContent
              ? 'مدينة القاهرة الجديدة والتجمع الخامس والامتداد العمراني الشرقي'
              : 'القاهرة',
        ],
        projectsCompleted: 0,
        reviewCount: 2,
        reviewAvg: 4.9,
        coverPhotoUrl: i == 1
            ? ProfessionalReferenceFixture.livingRoomImage
            : ProfessionalReferenceFixture.bedroomImage,
      ),
  ];
}
