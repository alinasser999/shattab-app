import 'package:batsh/core/theme/batsh_theme.dart';
import 'package:batsh/core/utils/connectivity.dart';
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
import 'package:batsh/features/home/presentation/widgets/home_reference_sections.dart';
import 'package:batsh/features/home/presentation/widgets/reference_home_experience.dart';
import 'package:batsh/features/notifications/domain/app_notification.dart';
import 'package:batsh/features/notifications/presentation/providers/notifications_providers.dart';
import 'package:batsh/features/onboarding/domain/onboarding_models.dart';
import 'package:batsh/features/portfolio/data/portfolio_repository.dart';
import 'package:batsh/features/portfolio/domain/portfolio_project.dart';
import 'package:batsh/features/saved/presentation/providers/saved_providers.dart';
import 'package:batsh/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'compile-time preview renders its fixture without live home provider reads and keeps saves local',
    (tester) async {
      expect(
        referenceHomePreviewEnabled,
        isTrue,
        reason:
            'Run this test with --dart-define=SHATTAB_REFERENCE_PREVIEW=true',
      );
      _setViewport(tester, const Size(1024, 844));
      final providerAudit = _HomeProviderAudit();

      await tester.pumpWidget(
        ProviderScope(
          observers: [providerAudit],
          overrides: [
            currentSessionProvider.overrideWithValue(null),
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
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: BatshTheme.light(),
            home: const HomeownerHomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HomeownerHomeScreen), findsOneWidget);
      expect(find.byType(ReferenceHomeHero), findsOneWidget);
      expect(find.byType(HomeLiveStateSection), findsNothing);
      expect(
        tester
            .widget<ReferenceHomeExperience>(
              find.byType(ReferenceHomeExperience),
            )
            .staticPreview,
        isTrue,
      );
      expect(
        find.text(ReferenceHomePreviewData.professionals.first.name),
        findsOneWidget,
      );
      expect(find.text(ReferenceHomePreviewData.project.title), findsOneWidget);
      final liveHomeProvidersRead = providerAudit.initializedProviderNames
          .where(_liveHomeProviderNames.contains)
          .toSet();
      expect(
        liveHomeProvidersRead,
        isEmpty,
        reason: 'Live home providers initialized: $liveHomeProvidersRead',
      );
      expect(tester.takeException(), isNull);

      final context = tester.element(find.byType(HomeownerHomeScreen));
      final l10n = AppLocalizations.of(context)!;
      final saveAction = _labeledWidget(l10n.saveTooltip).first;
      await tester.ensureVisible(saveAction);
      await tester.pumpAndSettle();
      await tester.tap(saveAction);
      await tester.pumpAndSettle();
      expect(_labeledWidget(l10n.unsaveTooltip), findsWidgets);

      await tester.tap(_labeledWidget(l10n.unsaveTooltip).first);
      await tester.pumpAndSettle();
      expect(_labeledWidget(l10n.unsaveTooltip), findsNothing);
      expect(_labeledWidget(l10n.saveTooltip), findsWidgets);
      expect(tester.takeException(), isNull);
    },
    skip: !referenceHomePreviewEnabled,
  );

  testWidgets('home entrance plays once and finishes after a parent rebuild', (
    tester,
  ) async {
    _setViewport(tester, const Size(1024, 844));
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final actions = _HomeActions();

    await tester.pumpWidget(
      _HomeHarness(controller: controller, actions: actions),
    );

    expect(_entranceOpacity(tester), 0);
    await tester.pump(const Duration(milliseconds: 160));
    final intermediateOpacity = _entranceOpacity(tester);
    expect(intermediateOpacity, greaterThan(0));
    expect(intermediateOpacity, lessThan(1));

    await tester.pump(const Duration(milliseconds: 300));
    expect(_entranceOpacity(tester), 1);

    await tester.tap(find.byKey(_HomeHarness.rebuildKey));
    await tester.pump();
    expect(_entranceOpacity(tester), 1);
    await tester.pump(const Duration(milliseconds: 500));
    expect(_entranceOpacity(tester), 1);
  });

  testWidgets('initial reduced motion shows the final home state immediately', (
    tester,
  ) async {
    _setViewport(tester, const Size(1024, 844));
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _HomeHarness(
        controller: controller,
        actions: _HomeActions(),
        disableAnimations: true,
      ),
    );

    expect(_entranceOpacity(tester), 1);
    expect(find.byType(ReferenceHomeHero), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('enabling reduced motion mid-entrance completes it immediately', (
    tester,
  ) async {
    _setViewport(tester, const Size(1024, 844));
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _HomeHarness(controller: controller, actions: _HomeActions()),
    );
    await tester.pump(const Duration(milliseconds: 120));
    expect(_entranceOpacity(tester), greaterThan(0));
    expect(_entranceOpacity(tester), lessThan(1));

    await tester.tap(find.byKey(_HomeHarness.reduceMotionKey));
    await tester.pump();
    expect(_entranceOpacity(tester), 1);
  });

  testWidgets('header, service and view-all actions expose one useful node', (
    tester,
  ) async {
    _setViewport(tester, const Size(1024, 844));
    final semantics = tester.ensureSemantics();
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final actions = _HomeActions();

    await tester.pumpWidget(
      _HomeHarness(
        controller: controller,
        actions: actions,
        disableAnimations: true,
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(ReferenceHomeExperience));
    final l10n = AppLocalizations.of(context)!;
    final notification = _labeledWidget(l10n.notificationsTitle);
    // Electrical appears once in the hero shortcuts and once in the lower
    // service rail. Each separate control should expose a single action node.
    final services = _labeledWidget(l10n.specialtyElectrical);
    final viewAll = _labeledWidget(l10n.viewAll);

    expect(notification, findsOneWidget);
    expect(services, findsNWidgets(2));
    // Five section headers and the empty top-rated/work actions share this
    // localized label. The baseline composition therefore has seven real
    // view-all nodes; duplicate nested button semantics increase this count.
    expect(viewAll, findsNWidgets(7));
    for (final finder in [notification, services.first, viewAll.first]) {
      final node = tester.getSemantics(finder);
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      expect(node.rect.height, greaterThanOrEqualTo(48));
    }
    expect(
      tester.getSemantics(notification).getSemanticsData().label,
      contains(l10n.notificationsTitle),
    );
    expect(
      tester.getSemantics(services.first).getSemanticsData().label,
      contains(l10n.specialtyElectrical),
    );
    expect(
      tester.getSemantics(viewAll.first).getSemanticsData().label,
      contains(l10n.viewAll),
    );

    await tester.tap(notification);
    await tester.pump();
    expect(actions.events, contains('notifications'));

    await tester.tap(services.first);
    await tester.pump();
    expect(actions.events, contains('service:electrical'));

    await tester.tap(viewAll.first);
    await tester.pump();
    expect(actions.events, contains('featured-view-all'));
    semantics.dispose();
  });

  testWidgets('compact project image overlay keeps a 48dp tappable target', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    final previousFlutterErrorHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('RenderFlex overflowed')) {
        print('QA_RENDERFLEX_DETAILS_BEGIN');
        print(details.toString(minLevel: DiagnosticLevel.hidden));
        print('QA_RENDERFLEX_DETAILS_END');
      }
      previousFlutterErrorHandler?.call(details);
    };
    addTearDown(() => FlutterError.onError = previousFlutterErrorHandler);
    for (final width in [320.0, 390.0, 359.0, 360.0]) {
      for (final textScale in [1.0, 1.6]) {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        final semantics = tester.ensureSemantics();
        try {
          final controller = TextEditingController();
          addTearDown(controller.dispose);
          final actions = _HomeActions();
          const project = ReferenceHomeProject(
            id: 'project-overlay-qa',
            title: 'تجديد شقة المعادي',
            location: 'المعادي، القاهرة',
            imageUrl: '',
            progress: 0.5,
            stage: 'تنفيذ النجارة',
            offerCount: 4,
          );

          await tester.pumpWidget(
            _HomeHarness(
              controller: controller,
              actions: actions,
              project: project,
              disableAnimations: true,
              locale: const Locale('ar'),
              textScale: textScale,
            ),
          );
          await tester.pumpAndSettle();

          final context = tester.element(find.byType(ReferenceHomeExperience));
          final label = AppLocalizations.of(
            context,
          )!.homeReferenceProjectDetails;
          final overlay = find.byType(TextButton);
          expect(
            overlay,
            findsOneWidget,
            reason: 'width=$width scale=$textScale',
          );
          final buttonSemantics = find.descendant(
            of: overlay,
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Semantics && widget.properties.button == true,
            ),
          );
          expect(
            buttonSemantics,
            findsOneWidget,
            reason: 'width=$width scale=$textScale',
          );
          final overlayLabel = find.descendant(
            of: find.byType(ExcludeSemantics),
            matching: find.text(label),
          );
          expect(
            overlayLabel,
            findsOneWidget,
            reason: 'width=$width scale=$textScale',
          );
          await tester.ensureVisible(overlay);
          await tester.pumpAndSettle();
          final node = tester.getSemantics(buttonSemantics);
          final buttonSize = tester.getSize(overlay);
          expect(
            node.getSemanticsData().label,
            label,
            reason: 'width=$width scale=$textScale',
          );
          expect(
            node.getSemanticsData().hasFlag(SemanticsFlag.isButton),
            isTrue,
            reason: 'width=$width scale=$textScale',
          );
          expect(
            node.getSemanticsData().hasAction(SemanticsAction.tap),
            isTrue,
            reason: 'width=$width scale=$textScale',
          );
          expect(
            buttonSize.width,
            greaterThanOrEqualTo(48),
            reason: 'width=$width scale=$textScale',
          );
          expect(
            buttonSize.height,
            greaterThanOrEqualTo(48),
            reason: 'width=$width scale=$textScale',
          );
          expect(
            node.rect.width,
            greaterThanOrEqualTo(48),
            reason: 'width=$width scale=$textScale',
          );
          expect(
            node.rect.height,
            greaterThanOrEqualTo(48),
            reason: 'width=$width scale=$textScale',
          );
          await tester.tap(overlay);
          await tester.pump();
          expect(
            actions.events,
            contains('project-details:${project.id}'),
            reason: 'width=$width scale=$textScale',
          );
          expect(
            tester.takeException(),
            isNull,
            reason: 'width=$width scale=$textScale',
          );
        } finally {
          semantics.dispose();
        }
      }
    }
  });

  testWidgets(
    'Arabic home has no overflow at narrow, reference and wide sizes',
    (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final actions = _HomeActions();
      final layoutFailures = <String>[];

      for (final width in [320.0, 390.0, 1024.0]) {
        _setViewport(tester, Size(width, 844));
        await tester.pumpWidget(
          _HomeHarness(
            controller: controller,
            actions: actions,
            disableAnimations: true,
            locale: const Locale('ar'),
            textScale: width == 320 ? 1.6 : 1,
          ),
        );
        await tester.pumpAndSettle();

        final experience = find.byType(ReferenceHomeExperience);
        expect(experience, findsOneWidget);
        expect(
          Directionality.of(tester.element(experience)),
          TextDirection.rtl,
        );
        final initialException = tester.takeException();
        if (initialException != null) {
          layoutFailures.add(
            'width=$width, textScale=${width == 320 ? 1.6 : 1}: '
            '$initialException',
          );
        }

        final context = tester.element(experience);
        final closingActionLabel = AppLocalizations.of(
          context,
        )!.homeReferenceClosingAction;
        await tester.ensureVisible(find.text(closingActionLabel));
        await tester.pump();
        expect(
          find.text(closingActionLabel),
          findsOneWidget,
          reason: 'width=$width',
        );
        final scrollException = tester.takeException();
        if (scrollException != null) {
          layoutFailures.add(
            'width=$width after scrolling to closing action: '
            '$scrollException',
          );
        }
      }
      expect(layoutFailures, isEmpty, reason: layoutFailures.join('\n\n'));
    },
  );

  testWidgets('live unread activity exposes one tappable notification node', (
    tester,
  ) async {
    _setViewport(tester, const Size(390, 844));
    final semantics = tester.ensureSemantics();
    var notificationsOpened = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myBriefsProvider.overrideWith((ref) async => [_activeBrief]),
          notificationsProvider.overrideWith(
            (ref) => Stream.value([_unreadNotification]),
          ),
          unreadNotificationsProvider.overrideWith((ref) => 1),
          connectivityProvider.overrideWith((ref) => Stream.value(true)),
        ],
        child: MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: BatshTheme.light(),
          home: Scaffold(
            body: HomeLiveStateSection(
              onOpenRequests: () {},
              onOpenNotifications: () => notificationsOpened++,
              onStartRequest: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(HomeLiveStateSection));
    final label = AppLocalizations.of(context)!.homeLiveOpenNotifications;
    final notificationAction = _labeledWidget(label);
    expect(notificationAction, findsOneWidget);
    expect(
      tester
          .getSemantics(notificationAction)
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );

    await tester.tap(notificationAction);
    await tester.pump();
    expect(notificationsOpened, 1);
    semantics.dispose();
  });

  testWidgets('a community card opens its corresponding post', (tester) async {
    _setViewport(tester, const Size(390, 844));
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final actions = _HomeActions();
    const post = ReferenceHomeCommunityPost(
      id: 'community-post-qa',
      authorId: 'member-qa',
      authorName: 'عضو اختبار',
      authorAvatarUrl: '',
      badge: 'من واقع التجربة',
      timeLabel: 'منذ يوم',
      caption: 'منشور تجريبي لاختبار فتح بطاقة المجتمع',
      imageUrl: '',
      likeCount: 3,
      commentCount: 1,
    );

    await tester.pumpWidget(
      _HomeHarness(
        controller: controller,
        actions: actions,
        communityPosts: const [post],
        disableAnimations: true,
        locale: const Locale('ar'),
      ),
    );
    await tester.pumpAndSettle();

    final card = find.text(post.caption);
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    await tester.tap(card);
    await tester.pump();

    expect(actions.events, contains('post:${post.id}'));
    expect(tester.takeException(), isNull);
  });
}

Finder _labeledWidget(String label) => find.byWidgetPredicate(
  (widget) => widget is Semantics && widget.properties.label == label,
);

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

double _entranceOpacity(WidgetTester tester) {
  final fade = find
      .ancestor(
        of: find.byType(ReferenceHomeHero),
        matching: find.byWidgetPredicate(
          (widget) => widget is FadeTransition && widget.alwaysIncludeSemantics,
        ),
      )
      .first;
  return tester.widget<FadeTransition>(fade).opacity.value;
}

class _HomeHarness extends StatefulWidget {
  const _HomeHarness({
    required this.controller,
    required this.actions,
    this.disableAnimations = false,
    this.locale = const Locale('en'),
    this.textScale = 1,
    this.communityPosts = const [],
    this.project,
  });

  static const rebuildKey = ValueKey('test-rebuild-home');
  static const reduceMotionKey = ValueKey('test-enable-reduced-motion');

  final TextEditingController controller;
  final _HomeActions actions;
  final bool disableAnimations;
  final Locale locale;
  final double textScale;
  final List<ReferenceHomeCommunityPost> communityPosts;
  final ReferenceHomeProject? project;

  @override
  State<_HomeHarness> createState() => _HomeHarnessState();
}

class _HomeHarnessState extends State<_HomeHarness> {
  late bool _disableAnimations = widget.disableAnimations;
  var _revision = 0;

  @override
  Widget build(BuildContext context) {
    final experience = ReferenceHomeExperience(
      locationLabel: _revision.isEven ? 'القاهرة' : 'الجيزة',
      homeownerName: 'أحمد',
      avatarUrl: null,
      unreadCount: 0,
      onLocationTap: () => widget.actions.events.add('location'),
      onNotificationTap: () => widget.actions.events.add('notifications'),
      onAccountTap: () => widget.actions.events.add('account'),
      searchController: widget.controller,
      onSearchSubmitted: (value) => widget.actions.events.add('search:$value'),
      onSearchChanged: (value) => widget.actions.events.add('changed:$value'),
      onSearchClear: () => widget.actions.events.add('search-clear'),
      onStartProject: () => widget.actions.events.add('start-project'),
      onSelectService: (value) => widget.actions.events.add('service:$value'),
      onOpenProject: (project) =>
          widget.actions.events.add('project:${project.id}'),
      onOpenProjectOffers: (project) =>
          widget.actions.events.add('offers:${project.id}'),
      onOpenProjectDetails: (project) =>
          widget.actions.events.add('project-details:${project.id}'),
      onOpenFeaturedProfessionals: () =>
          widget.actions.events.add('featured-view-all'),
      onOpenTopRated: () => widget.actions.events.add('top-rated'),
      onOpenWork: (work) => widget.actions.events.add('work:${work.id}'),
      onOpenCompletedWork: () => widget.actions.events.add('completed-work'),
      onOpenCommunity: (post) => widget.actions.events.add('post:${post.id}'),
      onOpenCommunityFeed: () => widget.actions.events.add('community-feed'),
      onCreatePost: () => widget.actions.events.add('create-post'),
      onOpenClosingCta: () => widget.actions.events.add('closing-cta'),
      featuredProfessionals: const [],
      topRatedProfessionals: const [],
      project: widget.project,
      work: null,
      communityPosts: widget.communityPosts,
      savedProfessionalIds: const {},
      onOpenProfessional: (id) => widget.actions.events.add('professional:$id'),
      onRequestQuote: (id) => widget.actions.events.add('quote:$id'),
      onToggleSaved: (id) => widget.actions.events.add('saved:$id'),
    );

    return ProviderScope(
      overrides: [
        myBriefsProvider.overrideWith((ref) async => const <Brief>[]),
        notificationsProvider.overrideWith(
          (ref) => Stream.value(const <AppNotification>[]),
        ),
        connectivityProvider.overrideWith((ref) => Stream.value(true)),
      ],
      child: MaterialApp(
        locale: widget.locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: BatshTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: _disableAnimations,
            textScaler: TextScaler.linear(widget.textScale),
          ),
          child: child!,
        ),
        home: Scaffold(
          body: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    key: _HomeHarness.rebuildKey,
                    onPressed: () => setState(() => _revision++),
                    tooltip: 'rebuild fixture',
                    icon: const Icon(Icons.refresh),
                  ),
                  IconButton(
                    key: _HomeHarness.reduceMotionKey,
                    onPressed: () => setState(() => _disableAnimations = true),
                    tooltip: 'enable reduced motion',
                    icon: const Icon(Icons.motion_photos_off_outlined),
                  ),
                ],
              ),
              Expanded(child: SingleChildScrollView(child: experience)),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeActions {
  final events = <String>[];
}

final _activeBrief = Brief(
  id: 'live-brief',
  homeownerId: 'homeowner-1',
  apartmentType: ApartmentType.oneBedroom,
  city: 'Cairo',
  workDescription: 'Paint the living room',
  photoUrls: const [],
  targetSpecialties: const [],
  status: BriefStatus.open,
  createdAt: DateTime.utc(2026, 9, 27),
);

final _unreadNotification = AppNotification(
  id: 'unread-1',
  kind: 'new_quote',
  titleKey: 'notificationNewQuoteTitle',
  bodyKey: 'notificationNewQuoteBody',
  createdAt: DateTime.utc(2026, 9, 27),
);

const _liveHomeProviderNames = <String>{
  'currentProfileProvider',
  'homeownerProfileProvider',
  'myBriefsProvider',
  'notificationsProvider',
  'unreadNotificationsProvider',
  'discoverContractorsProvider',
  'topRatedProfessionalsProvider',
  'recentProjectsProvider',
  'exploreFeedProvider',
  'savedContractorIdsProvider',
  'discoveryFiltersControllerProvider',
};

final class _HomeProviderAudit extends ProviderObserver {
  final initializedProviderNames = <String>[];

  @override
  void didAddProvider(ProviderObserverContext context, Object? value) {
    final name = context.provider.name;
    if (name != null) initializedProviderNames.add(name);
  }
}

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
