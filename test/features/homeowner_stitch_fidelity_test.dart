import 'package:batsh/core/debug/debug_role_switcher.dart';
import 'package:batsh/core/router/routes.dart';
import 'package:batsh/core/theme/batsh_colors.dart';
import 'package:batsh/core/theme/batsh_radius.dart';
import 'package:batsh/core/theme/batsh_theme.dart';
import 'package:batsh/core/theme/batsh_typography.dart';
import 'package:batsh/core/utils/connectivity.dart';
import 'package:batsh/core/widgets/batsh_bottom_nav.dart';
import 'package:batsh/core/widgets/batsh_fab.dart';
import 'package:batsh/core/widgets/batsh_pattern_background.dart';
import 'package:batsh/core/widgets/batsh_search_bar.dart';
import 'package:batsh/features/auth/presentation/providers/auth_provider.dart';
import 'package:batsh/features/briefs/domain/brief.dart';
import 'package:batsh/features/briefs/presentation/providers/briefs_providers.dart';
import 'package:batsh/features/discovery/domain/contractor_listing.dart';
import 'package:batsh/features/discovery/presentation/providers/discovery_providers.dart';
import 'package:batsh/features/explore/domain/post.dart';
import 'package:batsh/features/explore/presentation/providers/explore_providers.dart';
import 'package:batsh/features/home/domain/reference_home_data.dart';
import 'package:batsh/features/home/presentation/homeowner_home_screen.dart';
import 'package:batsh/features/home/presentation/widgets/home_live_states.dart';
import 'package:batsh/features/home/presentation/widgets/reference_home_experience.dart';
import 'package:batsh/features/notifications/domain/app_notification.dart';
import 'package:batsh/features/notifications/presentation/providers/notifications_providers.dart';
import 'package:batsh/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:batsh/features/portfolio/data/portfolio_repository.dart';
import 'package:batsh/features/portfolio/domain/portfolio_project.dart';
import 'package:batsh/features/saved/presentation/providers/saved_providers.dart';
import 'package:batsh/features/shell/presentation/homeowner_shell.dart';
import 'package:batsh/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets(
    'Browse-by-need rail keeps Stitch source order and tile styling',
    (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await _pumpWorkExperience(
        tester,
        controller: controller,
        work: ReferenceHomePreviewData.work,
        locale: const Locale('ar'),
        width: 390,
        textScale: 1,
        settle: false,
      );

      const sourceOrder = [
        'full_reno',
        'design',
        'kitchen',
        'bathroom',
        'electrical',
        'plumbing',
        'more',
      ];
      final tileRects = [
        for (final key in sourceOrder)
          tester.getRect(
            find.byKey(ValueKey<String>('reference-home-service-$key')),
          ),
      ];
      for (var index = 0; index < tileRects.length - 1; index++) {
        expect(
          tileRects[index].center.dx,
          greaterThan(tileRects[index + 1].center.dx),
        );
      }

      final fullRenovationTile = find.byKey(
        const ValueKey<String>('reference-home-service-full_reno'),
      );
      expect(tester.getSize(fullRenovationTile), const Size(54, 64));

      final decoration =
          tester
                  .widget<DecoratedBox>(
                    find.descendant(
                      of: fullRenovationTile,
                      matching: find.byType(DecoratedBox),
                    ),
                  )
                  .decoration
              as BoxDecoration;
      expect(decoration.color, BatshColors.homeSoftSurface);
      expect(decoration.borderRadius, BatshRadius.brMd);
      expect(decoration.boxShadow, isNull);
      expect((decoration.border as Border).top.color, const Color(0xFFEDE2D5));

      final label = tester.widget<Text>(
        find.descendant(
          of: fullRenovationTile,
          matching: find.text('تشطيب كامل'),
        ),
      );
      expect(label.style?.fontSize, 9.5);
      expect(label.style?.fontWeight, FontWeight.w700);
      final icon = tester.widget<Icon>(
        find.descendant(of: fullRenovationTile, matching: find.byType(Icon)),
      );
      expect(icon.size, 20);
      expect(icon.color, BatshColors.homeAction);
    },
    skip: !referenceHomePreviewEnabled,
  );

  testWidgets(
    'Browse rail More opens Discover without an empty specialty filter',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      final filtersSubscription = container.listen(
        discoveryFiltersControllerProvider,
        (_, _) {},
      );
      addTearDown(filtersSubscription.close);
      final filters = container.read(
        discoveryFiltersControllerProvider.notifier,
      );
      filters.setSearch('existing query');
      filters.setSpecialty('bathroom');

      final router = GoRouter(
        initialLocation: Routes.homeownerHome,
        routes: [
          GoRoute(
            path: Routes.homeownerHome,
            builder: (_, _) => const HomeownerHomeScreen(),
          ),
          GoRoute(
            path: Routes.homeownerDiscover,
            builder: (_, _) => const Text('discover-route'),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            locale: const Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: BatshTheme.light(),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final moreTile = find.byKey(
        const ValueKey<String>('reference-home-service-more'),
      );
      expect(moreTile, findsOneWidget);
      await tester.ensureVisible(moreTile);
      await tester.pumpAndSettle();
      await tester.tap(moreTile);
      await tester.pumpAndSettle();

      expect(find.text('discover-route'), findsOneWidget);
      final selectedFilters = container.read(
        discoveryFiltersControllerProvider,
      );
      expect(selectedFilters.specialty, isNull);
      expect(selectedFilters.searchQuery, 'existing query');
    },
    skip: !referenceHomePreviewEnabled,
  );

  testWidgets(
    '390dp preview project matches the source card gutter and inner media inset',
    (tester) async {
      expect(referenceHomePreviewEnabled, isTrue);
      tester.view.physicalSize = const Size(780, 1688);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: BatshTheme.light(),
            home: const HomeownerHomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final project = ReferenceHomePreviewData.project;
      final projectCard = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            (widget.properties.label ?? '').contains(project.title) &&
            widget.properties.label != project.title,
      );
      expect(projectCard, findsOneWidget);
      final cardRect = tester.getRect(projectCard);
      expect(cardRect.left, closeTo(14, 0.01));
      expect(cardRect.width, closeTo(362, 0.01));

      final projectMedia = find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName == project.imageUrl,
      );
      expect(projectMedia, findsOneWidget);
      final mediaRect = tester.getRect(projectMedia);
      // The 1dp outer border sits outside the unchanged 12dp content inset.
      expect(mediaRect.left - cardRect.left, closeTo(13, 0.01));
      expect(mediaRect.top - cardRect.top, closeTo(13, 0.01));
      expect(tester.takeException(), isNull);
    },
    skip: !referenceHomePreviewEnabled,
  );

  testWidgets(
    'completed-work preview pair matches source geometry and localized semantics',
    (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      var openedWork = 0;

      await _pumpWorkExperience(
        tester,
        controller: controller,
        work: ReferenceHomePreviewData.work,
        locale: const Locale('ar'),
        width: 390,
        textScale: 1,
        onOpenWork: (_) => openedWork++,
      );

      final item = ReferenceHomePreviewData.work;
      final card = _workCard(item);
      expect(card, findsOneWidget);
      await tester.ensureVisible(card);
      await tester.pumpAndSettle();
      final cardRect = tester.getRect(card);
      expect(cardRect.left, closeTo(14, 0.01));
      expect(cardRect.width, closeTo(362, 0.01));

      final cardPadding = find.descendant(
        of: card,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Padding && widget.padding == const EdgeInsets.all(12),
        ),
      );
      expect(cardPadding, findsOneWidget);

      final mediaFrame = find.descendant(
        of: card,
        matching: find.byType(ClipRRect),
      );
      expect(mediaFrame, findsOneWidget);
      expect(tester.getSize(mediaFrame), const Size(155, 92));
      expect(
        find.descendant(of: card, matching: find.byType(Image)),
        findsNWidgets(2),
      );

      final l10n = AppLocalizations.of(tester.element(card))!;
      expect(
        _semanticsWithLabel(card, l10n.communityBeforeLabel),
        findsOneWidget,
      );
      expect(
        _semanticsWithLabel(card, l10n.communityAfterLabel),
        findsOneWidget,
      );
      expect(_semanticsWithLabel(card, l10n.projectPhotoLabel), findsNothing);

      final details = _semanticsWithLabel(card, l10n.homeReferenceCaseDetails);
      expect(details, findsOneWidget);
      expect(tester.getRect(details).height, greaterThanOrEqualTo(48));
      await tester.ensureVisible(details);
      await tester.pumpAndSettle();
      await tester.tap(details);
      expect(openedWork, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'live work photos stay a neutral de-duplicated gallery and a single photo appears once',
    (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      const firstPhoto = 'assets/images/stitch_home_work_before.jpg';
      const secondPhoto = 'assets/images/stitch_home_work_after.jpg';
      const thirdPhoto = 'assets/images/stitch_home_project.jpg';
      const liveProject = PortfolioProject(
        id: 'live-work',
        contractorId: 'real-contractor',
        title: 'عمل منشور',
        coverPhotoUrl: ' $firstPhoto ',
        photoUrls: [firstPhoto, secondPhoto, ' $secondPhoto ', thirdPhoto],
        position: 0,
        category: 'تشطيب',
        location: 'القاهرة',
      );
      final liveWork = ReferenceHomeWork.fromProject(liveProject);
      expect(liveWork.mediaKind, ReferenceHomeWorkMediaKind.gallery);
      expect(liveWork.galleryUrls, [firstPhoto, secondPhoto, thirdPhoto]);
      expect(liveWork.beforeUrl, isEmpty);
      expect(liveWork.afterUrl, isEmpty);
      expect(liveWork.rating, isNull);
      expect(liveWork.reviewCount, 0);
      expect(liveWork.isPreview, isFalse);

      await _pumpWorkExperience(
        tester,
        controller: controller,
        work: liveWork,
        locale: const Locale('ar'),
        width: 390,
        textScale: 1,
      );

      var card = _workCard(liveWork);
      expect(card, findsOneWidget);
      await tester.ensureVisible(card);
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: card, matching: find.byType(Image)),
        findsNWidgets(2),
      );
      var l10n = AppLocalizations.of(tester.element(card))!;
      expect(
        _semanticsWithLabel(
          card,
          '${l10n.portfolioGalleryTitle}, ${l10n.photoIndexOf(1, 3)}',
        ),
        findsOneWidget,
      );
      expect(
        _semanticsWithLabel(
          card,
          '${l10n.portfolioGalleryTitle}, ${l10n.photoIndexOf(2, 3)}',
        ),
        findsOneWidget,
      );
      expect(
        _semanticsWithLabel(card, l10n.communityBeforeLabel),
        findsNothing,
      );
      expect(_semanticsWithLabel(card, l10n.communityAfterLabel), findsNothing);
      expect(_semanticsWithLabel(card, l10n.morePhotosCount(1)), findsNothing);

      final singlePhoto = ReferenceHomeWork(
        id: 'single-photo-work',
        contractorId: 'real-contractor',
        title: 'عمل بصورة واحدة',
        category: 'دهان',
        location: 'القاهرة',
        mediaKind: ReferenceHomeWorkMediaKind.gallery,
        galleryUrls: [firstPhoto, ' $firstPhoto '],
      );
      await _pumpWorkExperience(
        tester,
        controller: controller,
        work: singlePhoto,
        locale: const Locale('ar'),
        width: 390,
        textScale: 1,
      );

      card = _workCard(singlePhoto);
      expect(card, findsOneWidget);
      await tester.ensureVisible(card);
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: card, matching: find.byType(Image)),
        findsOneWidget,
      );
      l10n = AppLocalizations.of(tester.element(card))!;
      expect(_semanticsWithLabel(card, l10n.projectPhotoLabel), findsOneWidget);
      expect(
        _semanticsWithLabel(card, l10n.portfolioGalleryTitle),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('empty or failed work photos expose one localized fallback', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final emptyWork = ReferenceHomeWork(
      id: 'empty-work',
      contractorId: 'real-contractor',
      title: 'عمل بلا صور',
      category: 'تشطيب',
      location: 'القاهرة',
      mediaKind: ReferenceHomeWorkMediaKind.gallery,
    );

    await _pumpWorkExperience(
      tester,
      controller: controller,
      work: emptyWork,
      locale: const Locale('ar'),
      width: 390,
      textScale: 1,
    );
    var card = _workCard(emptyWork);
    expect(card, findsOneWidget);
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    var l10n = AppLocalizations.of(tester.element(card))!;
    expect(_semanticsWithLabel(card, l10n.imageUnavailable), findsOneWidget);

    final failedWork = ReferenceHomeWork(
      id: 'failed-work',
      contractorId: 'real-contractor',
      title: 'عمل بصورة معطلة',
      category: 'دهان',
      location: 'القاهرة',
      mediaKind: ReferenceHomeWorkMediaKind.gallery,
      galleryUrls: const ['https://invalid.invalid/broken.jpg'],
    );
    await _pumpWorkExperience(
      tester,
      controller: controller,
      work: failedWork,
      locale: const Locale('ar'),
      width: 390,
      textScale: 1,
    );
    card = _workCard(failedWork);
    expect(card, findsOneWidget);
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    l10n = AppLocalizations.of(tester.element(card))!;
    expect(_semanticsWithLabel(card, l10n.imageUnavailable), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'home stays overflow-free at 320dp and 390dp in RTL and LTR with normal and large text',
    (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      for (final width in [320.0, 390.0]) {
        for (final locale in [const Locale('ar'), const Locale('en')]) {
          for (final textScale in [1.0, 1.6]) {
            await _pumpWorkExperience(
              tester,
              controller: controller,
              work: ReferenceHomePreviewData.work,
              locale: locale,
              width: width,
              textScale: textScale,
              settle: false,
            );
            expect(
              tester.takeException(),
              isNull,
              reason:
                  'overflow at ${width.toInt()}dp, ${locale.languageCode}, $textScale text scale',
            );
          }
        }
      }
    },
  );

  testWidgets(
    'Stitch preview professional rails have no 320dp 1.6x RTL overflow',
    (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await _pumpWorkExperience(
        tester,
        controller: controller,
        work: ReferenceHomePreviewData.work,
        locale: const Locale('ar'),
        width: 320,
        textScale: 1.6,
        featuredProfessionals: ReferenceHomePreviewData.professionals,
        topRatedProfessionals: ReferenceHomePreviewData.topRated,
        settle: false,
      );
      final errors = <Object>[];
      while (true) {
        final exception = tester.takeException();
        if (exception == null) break;
        errors.add(exception);
      }
      expect(errors, isEmpty, reason: errors.join('\n\n'));
    },
  );

  testWidgets(
    'home shell scopes the Stitch chrome and other routes keep defaults',
    (tester) async {
      final router = _homeownerShellRouter();
      addTearDown(router.dispose);
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            locale: const Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: BatshTheme.light(),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final homeNav = tester.widget<BatshBottomNav>(
        find.byType(BatshBottomNav),
      );
      expect(find.text('home-root'), findsOneWidget);
      expect(homeNav.anchored, isTrue);
      expect(find.bySemanticsLabel('مشاريعي'), findsOneWidget);
      expect(find.byType(BatshFab), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.byType(DebugRoleSwitcherHost), findsNothing);
      expect(find.byType(BatshPatternBackground), findsNothing);
      expect(
        Theme.of(
          tester.element(find.text('home-root')),
        ).textTheme.bodyMedium?.fontFamily,
        'Tajawal',
      );

      router.go(Routes.homeownerProfile);
      await tester.pumpAndSettle();

      final sharedNav = tester.widget<BatshBottomNav>(
        find.byType(BatshBottomNav),
      );
      expect(find.text('profile-root'), findsOneWidget);
      expect(sharedNav.anchored, isFalse);
      expect(sharedNav.fontFamily, isNull);
      expect(find.byType(BatshFab), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byType(DebugRoleSwitcherHost), findsOneWidget);
      expect(find.byType(DebugRoleSwitcher), findsOneWidget);
      expect(find.byType(BatshPatternBackground), findsOneWidget);
      expect(
        Theme.of(
          tester.element(find.text('profile-root')),
        ).textTheme.bodyMedium?.fontFamily,
        BatshTheme.light().textTheme.bodyMedium?.fontFamily,
      );

      semantics.dispose();
    },
  );

  testWidgets(
    'search typeface override is opt-in and null keeps shared style',
    (tester) async {
      final sharedController = TextEditingController();
      final homeController = TextEditingController();
      addTearDown(sharedController.dispose);
      addTearDown(homeController.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: BatshTheme.light(),
          home: Scaffold(
            body: Column(
              children: [
                BatshSearchBar(
                  key: const ValueKey('shared-search'),
                  controller: sharedController,
                  onChanged: (_) {},
                  onClear: () {},
                  hintText: 'Shared search',
                ),
                BatshSearchBar(
                  key: const ValueKey('home-search'),
                  controller: homeController,
                  onChanged: (_) {},
                  onClear: () {},
                  hintText: 'Home search',
                  fontFamily: 'Tajawal',
                ),
              ],
            ),
          ),
        ),
      );

      final fields = tester
          .widgetList<TextField>(find.byType(TextField))
          .toList();
      expect(fields[0].style?.fontFamily, BatshTypography.bodyMd.fontFamily);
      expect(
        fields[0].decoration?.hintStyle?.fontFamily,
        BatshTypography.bodyMd.fontFamily,
      );
      expect(fields[1].style?.fontFamily, 'Tajawal');
      expect(fields[1].decoration?.hintStyle?.fontFamily, 'Tajawal');
    },
  );

  testWidgets(
    'ordinary homepage keeps provider data and empty states instead of fixtures',
    (tester) async {
      expect(referenceHomePreviewEnabled, isFalse);
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentSessionProvider.overrideWithValue(null),
            homeownerProfileProvider.overrideWith((ref) async => null),
            connectivityProvider.overrideWith((ref) => Stream.value(true)),
            myBriefsProvider.overrideWith((ref) async => const <Brief>[]),
            notificationsProvider.overrideWith(
              (ref) => Stream.value(const <AppNotification>[]),
            ),
            unreadNotificationsProvider.overrideWith((ref) => 0),
            discoverContractorsProvider.overrideWith(
              _EmptyDiscoverContractors.new,
            ),
            topRatedProfessionalsProvider.overrideWith(
              _EmptyTopRatedProfessionals.new,
            ),
            recentProjectsProvider.overrideWith(
              (ref) async => <PortfolioProject>[],
            ),
            exploreFeedProvider.overrideWith(_EmptyExploreFeed.new),
            savedContractorIdsProvider.overrideWith((ref) async => <String>{}),
          ],
          child: MaterialApp(
            locale: const Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: BatshTheme.light(),
            home: const HomeownerHomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final experience = tester.widget<ReferenceHomeExperience>(
        find.byType(ReferenceHomeExperience),
      );
      expect(experience.staticPreview, isFalse);
      expect(find.byType(HomeLiveStateSection), findsOneWidget);
      expect(
        find.text(ReferenceHomePreviewData.professionals.first.name),
        findsNothing,
      );
      expect(find.text(ReferenceHomePreviewData.project.title), findsNothing);
      expect(
        find.text(ReferenceHomePreviewData.communityPosts.first.authorName),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
    skip: referenceHomePreviewEnabled,
  );
}

Future<void> _pumpWorkExperience(
  WidgetTester tester, {
  required TextEditingController controller,
  required ReferenceHomeWork work,
  required Locale locale,
  required double width,
  required double textScale,
  bool staticPreview = true,
  bool settle = true,
  List<ReferenceHomeProfessional> featuredProfessionals = const [],
  List<ReferenceHomeProfessional> topRatedProfessionals = const [],
  ValueChanged<ReferenceHomeWork>? onOpenWork,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final app = MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: BatshTheme.light(),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: Scaffold(
      body: SingleChildScrollView(
        child: ReferenceHomeExperience(
          locationLabel: 'القاهرة',
          homeownerName: 'أحمد',
          avatarUrl: null,
          unreadCount: 0,
          onLocationTap: _noop,
          onNotificationTap: _noop,
          onAccountTap: _noop,
          searchController: controller,
          onSearchSubmitted: (_) {},
          onSearchChanged: (_) {},
          onSearchClear: _noop,
          onStartProject: _noop,
          onSelectService: (_) {},
          onOpenProject: (_) {},
          onOpenProjectOffers: (_) {},
          onOpenProjectDetails: (_) {},
          onOpenFeaturedProfessionals: _noop,
          onOpenTopRated: _noop,
          onOpenWork: onOpenWork ?? (_) {},
          onOpenCompletedWork: _noop,
          onOpenCommunity: (_) {},
          onOpenCommunityFeed: _noop,
          onCreatePost: _noop,
          onOpenClosingCta: _noop,
          featuredProfessionals: featuredProfessionals,
          topRatedProfessionals: topRatedProfessionals,
          project: ReferenceHomePreviewData.project,
          work: work,
          communityPosts: const [],
          savedProfessionalIds: const {},
          onOpenProfessional: (_) {},
          onRequestQuote: (_) {},
          onToggleSaved: (_) {},
          showHeader: false,
          staticPreview: staticPreview,
        ),
      ),
    ),
  );
  await tester.pumpWidget(
    staticPreview
        ? app
        : ProviderScope(
            overrides: [
              myBriefsProvider.overrideWith((ref) async => const <Brief>[]),
              notificationsProvider.overrideWith(
                (ref) => Stream.value(const <AppNotification>[]),
              ),
              unreadNotificationsProvider.overrideWith((ref) => 0),
              connectivityProvider.overrideWith((ref) => Stream.value(true)),
            ],
            child: app,
          ),
  );
  if (!settle) {
    await tester.pump();
    return;
  }
  await tester.pumpAndSettle();

  final card = _workCard(work);
  if (card.evaluate().isNotEmpty) {
    final context = tester.element(card);
    final mediaImages = tester.widgetList<Image>(
      find.descendant(of: card, matching: find.byType(Image)),
    );
    for (final image in mediaImages) {
      if (image.image is AssetImage) {
        await precacheImage(image.image, context);
      }
    }
    await tester.pumpAndSettle();
  }
}

Finder _workCard(ReferenceHomeWork work) => find.byWidgetPredicate(
  (widget) =>
      widget is Semantics &&
      widget.properties.label == '${work.title}، ${work.category}',
);

Finder _semanticsWithLabel(Finder ancestor, String label) => find.descendant(
  of: ancestor,
  matching: find.byWidgetPredicate(
    (widget) => widget is Semantics && widget.properties.label == label,
  ),
);

GoRouter _homeownerShellRouter() => GoRouter(
  initialLocation: Routes.homeownerHome,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => HomeownerShell(
        navigationShell: navigationShell,
        location: state.uri.path,
      ),
      branches: [
        _shellBranch(Routes.homeownerHome, 'home-root'),
        _shellBranch(Routes.homeownerDiscover, 'discover-root'),
        _shellBranch(Routes.homeownerRequests, 'requests-root'),
        _shellBranch(Routes.homeownerExplore, 'community-root'),
        _shellBranch(Routes.homeownerProfile, 'profile-root'),
      ],
    ),
  ],
);

StatefulShellBranch _shellBranch(String path, String label) =>
    StatefulShellBranch(
      routes: [GoRoute(path: path, builder: (context, state) => Text(label))],
    );

class _EmptyDiscoverContractors extends DiscoverContractors {
  @override
  Future<List<ContractorListing>> build() async => const [];
}

class _EmptyTopRatedProfessionals extends TopRatedProfessionals {
  @override
  Future<List<ContractorListing>> build() async => const [];
}

class _EmptyExploreFeed extends ExploreFeed {
  @override
  AsyncValue<List<Post>> build() => const AsyncData([]);
}

void _noop() {}
