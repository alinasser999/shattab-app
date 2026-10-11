import 'dart:io';
import 'dart:ui' as ui;
import 'package:batsh/core/l10n/l10n_extension.dart';
import 'package:batsh/features/home/presentation/widgets/reference_home_experience.dart';
import 'package:batsh/features/explore/domain/post.dart';
import 'package:batsh/features/explore/presentation/providers/explore_providers.dart';
import 'package:batsh/features/discovery/domain/professional_reference_fixture.dart';
import 'package:batsh/features/discovery/domain/contractor_listing.dart';
import 'package:batsh/features/discovery/presentation/providers/discovery_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import '../support/homeowner_reference_harness.dart';

Finder _cards(String type) =>
    find.byWidgetPredicate((w) => w.runtimeType.toString() == type);
const _caption =
    'تجربة عربية طويلة جدًا توضح تفاصيل اختيار التشطيبات وأهمية مراجعة الخامات والإضاءة والألوان قبل التنفيذ مع توفير جميع المعلومات في صفحة المشاركة بدون قص النص الكامل.';
List<Post> _posts() => [
  for (var i = 0; i < 3; i++)
    Post(
      id: 'scroll-post-$i',
      authorId: 'scroll-author-$i',
      authorRole: 'homeowner',
      postType: PostType.tip,
      caption: _caption,
      authorName: 'عضو تجريبي $i',
      createdAt: DateTime.utc(2026),
      mediaUrls: i == 0 ? [ProfessionalReferenceFixture.livingRoomImage] : [],
    ),
];
Future<void> _capture(WidgetTester tester, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('homeowner-qa-capture')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    const folder = 'artifacts/agent-team/20261006-home-scroll/screenshots';
    await Directory(folder).create(recursive: true);
    await File('$folder/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

Future<void> _community(WidgetTester tester) async {
  final heading = find.text(
    tester
        .element(find.byType(ReferenceHomeExperience))
        .l10n
        .homeCloneCommunity,
  );
  await Scrollable.ensureVisible(tester.element(heading), alignment: 0.1);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(initializeHomeownerTestClient);
  testWidgets('sponsored absent cover and failed nonempty cover scale2', (
    tester,
  ) async {
    final container = await pumpHomeownerReference(
      tester,
      query: 'scenario=noactive&textScale=2',
      size: const Size(320, 844),
      nativeSafeAreas: true,
      capture: true,
      disposeInTearDown: false,
      extraOverrides: [
        topRatedProfessionalsProvider.overrideWith(() => _SparseListings()),
      ],
    );
    final experience = tester.widget<ReferenceHomeExperience>(
      find.byType(ReferenceHomeExperience),
    );
    final topCards = _cards('_ProfessionalRow');
    final sponsored = find
        .ancestor(
          of: find.text('محترف تجريبي بدون غلاف').first,
          matching: topCards,
        )
        .first;
    await Scrollable.ensureVisible(tester.element(sponsored), alignment: 0.1);
    await tester.pumpAndSettle();
    expect(experience.topRatedProfessionals.first.sponsored, isTrue);
    expect(
      find.descendant(
        of: sponsored,
        matching: find.text(
          tester
              .element(find.byType(ReferenceHomeExperience))
              .l10n
              .homeReferenceSponsored,
        ),
      ),
      findsOneWidget,
    );
    final header = tester.widget<ReferenceHomeHeader>(
      find.byType(ReferenceHomeHeader).first,
    );
    final locationTarget = find.descendant(
      of: find.byType(ReferenceHomeHeader).first,
      matching: find.byWidgetPredicate(
        (w) => w is InkWell && w.onTap == header.onLocationTap,
      ),
    );
    expect(locationTarget, findsOneWidget);
    final locationSize = tester.getSize(locationTarget);
    expect(locationSize.width, greaterThanOrEqualTo(48));
    expect(locationSize.height, greaterThanOrEqualTo(48));
    expect(
      find.descendant(of: sponsored, matching: find.byType(AspectRatio)),
      findsNothing,
    );
    await _capture(tester, 'sponsored-no-cover-320-scale2');
    final failed = find
        .ancestor(
          of: find.text('محترف تجريبي بغلاف غير متاح').first,
          matching: topCards,
        )
        .first;
    await Scrollable.ensureVisible(tester.element(failed), alignment: 0.1);
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: failed, matching: find.byType(AspectRatio)),
      findsNothing,
    );
    await _capture(tester, 'failed-cover-320-scale2');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
  });
  testWidgets('singleton and known absent covers avoid surplus blank media', (
    tester,
  ) async {
    await pumpHomeownerReference(
      tester,
      nativeSafeAreas: true,
      capture: true,
      extraOverrides: [
        exploreFeedProvider.overrideWithValue(AsyncData([_posts()[1]])),
      ],
    );
    final experience = tester.widget<ReferenceHomeExperience>(
      find.byType(ReferenceHomeExperience),
    );
    final absentIndex = experience.featuredProfessionals.indexWhere(
      (item) => item.coverPhotoUrl?.trim().isEmpty ?? true,
    );
    expect(absentIndex, greaterThanOrEqualTo(0));
    expect(
      find.descendant(
        of: _cards('_ProfessionalCard').at(absentIndex),
        matching: find.byType(AspectRatio),
      ),
      findsOneWidget,
    );
    await _community(tester);
    final card = _cards('_CommunityCard');
    expect(card, findsOneWidget);
    // Reference keeps a two-column story rhythm at the normal phone width.
    expect(tester.getSize(card).width, 169);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -1200));
    await tester.pumpAndSettle();
    await _capture(tester, 'singleton-community-390');
    expect(tester.takeException(), isNull);
  });
  testWidgets('photo community terminal surface remains visible', (
    tester,
  ) async {
    await pumpHomeownerReference(
      tester,
      nativeSafeAreas: true,
      capture: true,
      extraOverrides: [
        exploreFeedProvider.overrideWithValue(
          AsyncData([
            for (var i = 0; i < 2; i++)
              Post(
                id: 'terminal-$i',
                authorId: 'terminal-author-$i',
                authorRole: 'homeowner',
                postType: PostType.tip,
                caption: 'مشاركة تجريبية لتصميم المساحة.',
                authorName: 'عضو تجريبي $i',
                createdAt: DateTime.utc(2026),
                mediaUrls: [ProfessionalReferenceFixture.livingRoomImage],
              ),
          ]),
        ),
      ],
    );
    await tester.runAsync(() async {
      await precacheImage(
        AssetImage(ProfessionalReferenceFixture.livingRoomImage),
        tester.element(find.byType(ReferenceHomeExperience)),
      );
    });
    await _community(tester);
    await _capture(tester, 'photo-community-terminal-390');
    expect(tester.takeException(), isNull);
  });
  for (final entry in [
    (390.0, 1.0),
    (320.0, 1.0),
    (390.0, 2.0),
    (1024.0, 1.0),
  ]) {
    testWidgets('bounded mixed community ${entry.$1} scale ${entry.$2}', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();

      await pumpHomeownerReference(
        tester,
        query: 'scenario=noactive&textScale=${entry.$2}',
        size: Size(entry.$1, 844),
        nativeSafeAreas: true,
        capture: true,
        extraOverrides: [
          exploreFeedProvider.overrideWithValue(AsyncData(_posts())),
        ],
      );
      await tester.runAsync(() async {
        await precacheImage(
          AssetImage(ProfessionalReferenceFixture.livingRoomImage),
          tester.element(find.byType(ReferenceHomeExperience)),
        );
      });
      await _community(tester);
      final cards = _cards('_CommunityCard');
      expect(cards, findsNWidgets(2));
      expect(find.text('عضو تجريبي 2'), findsNothing);
      expect(
        find.descendant(of: cards.at(0), matching: find.byType(AspectRatio)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: cards.at(1), matching: find.byType(AspectRatio)),
        findsNothing,
      );
      final first = tester.getRect(cards.at(0)),
          second = tester.getRect(cards.at(1));
      if (entry.$1 < 340 || entry.$2 >= 1.4) {
        expect(second.top, greaterThan(first.bottom));
        expect(first.width, second.width);
      } else {
        expect(first.top, second.top);
        expect(first.left, greaterThan(second.left));
      }
      expect(find.bySemanticsLabel(RegExp('عضو تجريبي 1')), findsWidgets);
      await _capture(
        tester,
        'mixed-community-${entry.$1.toInt()}-scale${entry.$2}',
      );
      for (var i = 0; i < 8; i++) {
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -650));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }
  for (final state in ['empty', 'error', 'loading']) {
    testWidgets('community $state retains section and create action', (
      tester,
    ) async {
      await pumpHomeownerReference(
        tester,
        capture: true,
        nativeSafeAreas: true,
        settle: state != 'loading',
        extraOverrides: [
          exploreFeedProvider.overrideWithValue(
            state == 'loading'
                ? const AsyncLoading()
                : state == 'error'
                ? AsyncError(
                    StateError('fixture read failed'),
                    StackTrace.empty,
                  )
                : const AsyncData([]),
          ),
        ],
      );
      final heading = find.text(
        tester
            .element(find.byType(ReferenceHomeExperience))
            .l10n
            .homeCloneCommunity,
      );
      await Scrollable.ensureVisible(tester.element(heading), alignment: 0.1);
      await tester.pump(const Duration(milliseconds: 100));
      final write = find.text(
        tester
            .element(find.byType(ReferenceHomeExperience))
            .l10n
            .homeCloneShare,
      );
      expect(write, findsOneWidget);
      expect(_cards('_CommunityCard'), findsNothing);
      await _capture(tester, 'community-$state');
      expect(tester.takeException(), isNull);
      if (state == 'error') {
        expect(
          find.text(
            tester.element(find.byType(ReferenceHomeExperience)).l10n.tryAgain,
          ),
          findsWidgets,
        );
      }
    });
  }
  for (final action in ['profile', 'community', 'save']) {
    testWidgets('keyboard activation $action keeps independent action', (
      tester,
    ) async {
      final container = await pumpHomeownerReference(
        tester,
        nativeSafeAreas: true,
        disposeInTearDown: false,
        extraOverrides: [
          exploreFeedProvider.overrideWithValue(AsyncData(_posts())),
        ],
      );
      final experience = tester.widget<ReferenceHomeExperience>(
        find.byType(ReferenceHomeExperience),
      );
      final router = GoRouter.of(
        tester.element(find.byType(ReferenceHomeExperience)),
      );
      final card = action == 'community'
          ? _cards('_CommunityCard').first
          : _cards('_ProfessionalCard').first;
      await Scrollable.ensureVisible(tester.element(card), alignment: 0.3);
      await tester.pumpAndSettle();
      final target = action == 'save'
          ? find.descendant(of: card, matching: find.byType(IconButton))
          : action == 'profile'
          ? find
                .ancestor(
                  of: find
                      .text(experience.featuredProfessionals.first.name)
                      .first,
                  matching: find.byType(InkWell),
                )
                .first
          : action == 'quote'
          ? find
                .ancestor(
                  of: find.text('اطلب عرض').first,
                  matching: find.byType(InkWell),
                )
                .first
          : find.descendant(of: card, matching: find.byType(InkWell)).first;
      final focus = find
          .descendant(of: target, matching: find.byType(Focus))
          .first;
      final node = Focus.of(
        tester.element(
          find.descendant(of: focus, matching: find.byType(Semantics)).first,
        ),
      );
      node.requestFocus();
      await tester.pump();
      expect(node.hasFocus, isTrue);
      final rect = tester.getRect(target);
      expect(rect.height, greaterThanOrEqualTo(48));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      if (action == 'save') {
        expect(
          tester
              .widget<ReferenceHomeExperience>(
                find.byType(ReferenceHomeExperience),
              )
              .savedProfessionalIds,
          contains(experience.featuredProfessionals.first.id),
        );
      } else {
        expect(
          router.routerDelegate.currentConfiguration.last.matchedLocation,
          contains(
            action == 'community'
                ? 'scroll-post-0'
                : experience.featuredProfessionals.first.id,
          ),
        );
      }
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
    });
  }
}

class _SparseListings extends TopRatedProfessionals {
  @override
  Future<List<ContractorListing>> build() async => [
    for (var i = 0; i < 2; i++)
      ContractorListing(
        id: 'sparse-fixture-$i',
        fullName: i == 0
            ? 'محترف تجريبي بدون غلاف'
            : 'محترف تجريبي بغلاف غير متاح',
        businessName: i == 0
            ? 'محترف تجريبي بدون غلاف'
            : 'محترف تجريبي بغلاف غير متاح',
        specialties: ['design'],
        serviceAreas: ['القاهرة الجديدة'],
        projectsCompleted: 0,
        reviewCount: 2,
        reviewAvg: 4.9,
        isSponsored: i == 0,
        coverPhotoUrl: i == 0 ? null : 'invalid-image-url',
      ),
  ];
}
