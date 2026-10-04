import 'package:intl/intl.dart' show DateFormat;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/l10n/catalog_labels.dart';
import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../../core/widgets/batsh_snack.dart';
import '../../../../core/widgets/contact_buttons.dart';
import '../../../auth/domain/profile.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/sign_in_sheet.dart';
import '../../../contact_followup/presentation/providers/professional_contact_providers.dart';
import '../../../portfolio/domain/portfolio_project.dart';
import '../../../portfolio/presentation/providers/portfolio_providers.dart';
import '../../../reviews/domain/review.dart';
import '../../../reviews/presentation/providers/reviews_providers.dart';
import '../../../reviews/presentation/reviews_sheet.dart';
import '../../../saved/presentation/providers/saved_providers.dart';
import '../../domain/contractor_listing.dart';
import '../../domain/professional_reference_fixture.dart';
import '../providers/discovery_providers.dart';
import 'professional_reference_components.dart';

/// One continuous professional profile; section links scroll to mounted content.
class ReferenceProfessionalProfile extends ConsumerStatefulWidget {
  const ReferenceProfessionalProfile({super.key, required this.listing});
  final ContractorListing listing;
  @override
  ConsumerState<ReferenceProfessionalProfile> createState() =>
      _ReferenceProfessionalProfileState();
}

class _ReferenceProfessionalProfileState
    extends ConsumerState<ReferenceProfessionalProfile> {
  final _sections = List.generate(4, (_) => GlobalKey());
  final _scroll = ScrollController();
  bool _saving = false;
  int _section = 0;
  ContractorListing get listing => widget.listing;
  bool get fixture =>
      professionalReferenceEnabled &&
      ProfessionalReferenceFixture.isFixtureId(listing.id);
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    Future<void> action() async {
      setState(() => _saving = true);
      try {
        await ref.read(savedControllerProvider.notifier).toggle(listing.id);
      } catch (e) {
        if (mounted) BatshSnack.error(context, ErrorMapper.map(e));
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    }

    if (fixture) {
      await action();
    } else {
      await runSignedIn(
        context,
        ref,
        reason: context.l10n.signInToSave,
        action: action,
      );
    }
  }

  void _goToSection(int i) {
    setState(() => _section = i);
    final target = _sections[i].currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        alignment: .03,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _quote() {
    if (fixture) {
      context.push(Routes.homeownerSendBriefPath(listing.id));
    } else {
      runSignedIn(
        context,
        ref,
        reason: context.l10n.referenceSignInContact,
        action: () => context.push(Routes.homeownerSendBriefPath(listing.id)),
      );
    }
  }

  Future<void> _contact() async {
    if (fixture) {
      BatshSnack.success(context, 'بيانات تجريبية — التواصل الخارجي غير مُرسل');
      return;
    }
    await runSignedIn(
      context,
      ref,
      reason: context.l10n.referenceSignInContact,
      action: () async {
        try {
          ref.invalidate(contractorByIdProvider(listing.id));
          final current = await ref.read(
            contractorByIdProvider(listing.id).future,
          );
          if (!mounted) return;
          if (current == null || !isValidContactPhone(current.phone)) {
            BatshSnack.error(context, context.l10n.contactLoadFailed);
            return;
          }
          final digits = whatsappPhoneDigits(current.phone);
          final session = ref.read(currentSessionProvider);
          final activeProfile = ref.read(currentProfileProvider).asData?.value;
          final canRecordContact =
              !fixture &&
              session != null &&
              activeProfile?.id == session.user.id &&
              activeProfile?.role == UserRole.homeowner;
          final contactActions = canRecordContact
              ? ref.read(professionalContactActionsProvider)
              : null;
          var whatsappOpened = false;
          try {
            whatsappOpened = await launchUrl(
              Uri.parse('https://wa.me/$digits'),
              mode: LaunchMode.externalApplication,
            );
          } catch (_) {}
          if (whatsappOpened && contactActions != null) {
            unawaited(contactActions.recordSuccessfulWhatsApp(listing.id));
          }
          var opened = whatsappOpened;
          if (!opened) {
            try {
              opened = await launchUrl(Uri.parse('tel:+$digits'));
            } catch (_) {}
          }
          if (!opened && mounted) {
            BatshSnack.error(context, context.l10n.couldNotOpenApp);
          }
        } catch (error) {
          if (mounted) BatshSnack.error(context, ErrorMapper.map(error));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(portfolioForContractorProvider(listing.id));
    final reviewsAsync = ref.watch(reviewsForContractorProvider(listing.id));
    final saved =
        ref.watch(savedContractorIdsProvider).value?.contains(listing.id) ??
        false;
    final projects = projectsAsync.value ?? const <PortfolioProject>[];
    final photos = fixture && listing.id == ProfessionalReferenceFixture.noorId
        ? ProfessionalReferenceFixture.galleryMediaForId(listing.id)
              .map(
                (url) => url == ProfessionalReferenceFixture.livingRoomImage
                    ? 'assets/images/professional_reference_living_profile.png'
                    : url,
              )
              .toList()
        : <String>{
            if (referenceMediaAllowed(listing.coverPhotoUrl))
              listing.coverPhotoUrl!,
            ...projects
                .expand((p) => [p.coverPhotoUrl, ...p.photoUrls])
                .where(referenceMediaAllowed),
          }.toList();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ColoredBox(
        color: referenceBackground,
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              SingleChildScrollView(
                controller: _scroll,
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) => SizedBox(
                        height: 36 + (constraints.maxWidth - 32) / 2.01,
                        child: Stack(
                          children: [
                            Positioned(
                              top: 36,
                              left: 16,
                              right: 16,
                              child: ReferenceGallery(
                                photos: photos,
                                ratio: 2.01,
                                premium: listing.isSponsored,
                                premiumLabel: listing.isPro,
                                compact: true,
                              ),
                            ),
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              height: 44,
                              child: Row(
                                children: [
                                  ReferenceIconButton(
                                    visualOffset: const Offset(0, -4),
                                    icon: Icons.chevron_right,
                                    label: context.l10n.back,
                                    size: 22,
                                    onTap: () {
                                      if (context.canPop()) {
                                        context.pop();
                                      } else {
                                        context.go(Routes.homeownerDiscover);
                                      }
                                    },
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Text(
                                        context.l10n.referenceProfileTitle,
                                        textAlign: TextAlign.center,
                                        style: referenceText(
                                          15,
                                          weight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                  ReferenceIconButton(
                                    visualOffset: const Offset(0, -4),
                                    icon: saved
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    label: saved
                                        ? context
                                              .l10n
                                              .referenceUnsaveProfessional
                                        : context
                                              .l10n
                                              .referenceSaveProfessional,
                                    size: 21,
                                    onTap: _save,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    ReferencePremiumSurface(
                      premium: listing.isSponsored,
                      profile: true,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(17, 8, 17, 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ReferenceAvatar(listing: listing, size: 58),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    referenceName(listing),
                                    style: referenceText(
                                      15.5,
                                      weight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    fixture
                                        ? 'مصمم داخلي'
                                        : referenceSpecialty(context, listing),
                                    style: referenceText(
                                      12,
                                      color: referenceMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        size: 19,
                                        color: Color(0xffffb322),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        listing.rating?.toStringAsFixed(1) ??
                                            '—',
                                        style: referenceText(
                                          17,
                                          weight: FontWeight.w800,
                                        ),
                                      ),
                                      Text(
                                        ' ${context.l10n.referenceReviewCount(listing.reviewCount)}',
                                        style: referenceText(
                                          11,
                                          color: referenceMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text(
                                      listing.serviceAreas.firstOrNull ?? '',
                                      style: referenceText(
                                        11.5,
                                        color: referenceMuted,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    const Icon(
                                      Icons.location_on_outlined,
                                      color: referenceMuted,
                                      size: 15,
                                    ),
                                  ],
                                ),
                                if (listing.verified)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 7),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 9,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xffeaf0db),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            context.l10n.referenceVerified,
                                            style: referenceText(
                                              10.5,
                                              color: const Color(0xff426129),
                                              weight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.check_circle,
                                            size: 13,
                                            color: Color(0xff426129),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
                      child: SizedBox(
                        height: 31,
                        child: Row(
                          children: [
                            Expanded(
                              child: _ProfileFact(
                                icon: Icons.work_outline,
                                leading: '${listing.projectsCompleted}',
                                text: context.l10n.referenceCompletedProjects,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 12,
                              color: const Color(0xfff1eee9),
                            ),
                            Expanded(
                              child: _ProfileFact(
                                icon: Icons.workspace_premium_outlined,
                                leading: '${listing.yearsExperience ?? '—'}',
                                text: context.l10n.referenceYearsExperience,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                      child: Row(
                        children: List.generate(4, (i) {
                          final labels = [
                            context.l10n.referenceAbout,
                            context.l10n.referenceWorks,
                            context.l10n.referenceServices,
                            context.l10n.reviewsSheetTitle,
                          ];
                          const icons = [
                            Icons.assignment_outlined,
                            Icons.photo_library_outlined,
                            Icons.settings_outlined,
                            Icons.star_border,
                          ];
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsetsDirectional.only(
                                end: i == 3 ? 0 : 8,
                              ),
                              child: Semantics(
                                button: true,
                                selected: _section == i,
                                child: InkWell(
                                  onTap: () => _goToSection(i),
                                  borderRadius: BorderRadius.circular(11),
                                  child: SizedBox(
                                    height: 44,
                                    child: Align(
                                      alignment: Alignment.topCenter,
                                      child: Container(
                                        height: 35,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: const Color(0xffe9e7eb),
                                          ),
                                          color: Colors.white.withValues(
                                            alpha: .55,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            11,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              icons[i],
                                              size: 16,
                                              color: referenceNavy,
                                            ),
                                            const SizedBox(width: 5),
                                            Flexible(
                                              child: Text(
                                                labels[i],
                                                style: referenceText(
                                                  11.5,
                                                  weight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    Padding(
                      key: _sections[0],
                      padding: const EdgeInsets.symmetric(horizontal: 17),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.referenceAboutProfessional,
                            style: referenceText(14, weight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            listing.bio?.trim().isNotEmpty == true
                                ? listing.bio!
                                : context.l10n.referenceMissingBio,
                            style: referenceText(
                              11.5,
                              color: referenceMuted,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Padding(
                      key: _sections[1],
                      padding: const EdgeInsets.symmetric(horizontal: 17),
                      child: _ActionSection(
                        heading: _SectionHeading(
                          title: context.l10n.referencePreviousWork,
                          icon: Icons.home_repair_service_outlined,
                          action: () => context.push(
                            Routes.homeownerContractorPortfolioPath(listing.id),
                          ),
                          hitHeight: 44,
                        ),
                        gap: 2,
                        body: Column(
                          children: [
                            if (projectsAsync.isLoading)
                              const SizedBox(
                                height: 110,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: referenceOrange,
                                  ),
                                ),
                              )
                            else if (projectsAsync.hasError)
                              _RetrySection(
                                onRetry: () => ref.invalidate(
                                  portfolioForContractorProvider(listing.id),
                                ),
                              )
                            else if (projects.isEmpty)
                              Text(
                                context.l10n.referenceMissingWork,
                                style: referenceText(12, color: referenceMuted),
                              )
                            else
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (
                                    int i = 0;
                                    i < projects.take(2).length;
                                    i++
                                  ) ...[
                                    if (i > 0) const SizedBox(width: 7),
                                    Expanded(
                                      child: _ProjectCard(
                                        project: projects[i],
                                        onOpen: () => context.push(
                                          Routes.homeownerProjectDetailPath(
                                            listing.id,
                                            projects[i].id,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      key: _sections[2],
                      padding: const EdgeInsets.symmetric(horizontal: 17),
                      child: Column(
                        children: [
                          _SectionHeading(
                            title: context.l10n.referenceServices,
                            icon: Icons.settings_outlined,
                          ),
                          const SizedBox(height: 0),
                          for (final service in _services(context))
                            InkWell(
                              onTap: _quote,
                              borderRadius: BorderRadius.circular(10),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: 44,
                                ),
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 5),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: _quietBox(),
                                      child: Row(
                                        children: [
                                          Icon(
                                            service.$3,
                                            color: referenceOrange,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  service.$1,
                                                  style: referenceText(
                                                    11.5,
                                                    weight: FontWeight.w700,
                                                  ),
                                                ),
                                                if (service.$2.isNotEmpty)
                                                  Text(
                                                    service.$2,
                                                    style: referenceText(
                                                      9.5,
                                                      color: referenceMuted,
                                                      height: 1.3,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          const Directionality(
                                            textDirection: TextDirection.ltr,
                                            child: Icon(
                                              Icons.chevron_left,
                                              color: referenceMuted,
                                              size: 20,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 10),
                          _SectionHeading(
                            title: context.l10n.referenceServiceAreas,
                            icon: Icons.location_on_outlined,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              for (
                                int i = 0;
                                i < listing.serviceAreas.take(3).length;
                                i++
                              ) ...[
                                if (i > 0) const SizedBox(width: 9),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 5,
                                      horizontal: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xfffaecdf),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      listing.serviceAreas[i],
                                      textAlign: TextAlign.center,
                                      style: referenceText(10.5),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          _SectionHeading(
                            title: context.l10n.referenceWorkingApproach,
                            icon: Icons.settings_outlined,
                          ),
                          const SizedBox(height: 7),
                          if (!fixture)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                context.l10n.referenceWorkApproachDisclaimer,
                                style: referenceText(11, color: referenceMuted),
                              ),
                            ),
                          for (int i = 0; i < 3; i++)
                            _WorkStep(index: i, last: i == 2),
                        ],
                      ),
                    ),
                    const SizedBox(height: 7),
                    Padding(
                      key: _sections[3],
                      padding: const EdgeInsets.symmetric(horizontal: 17),
                      child: _ActionSection(
                        heading: _SectionHeading(
                          title: context.l10n.reviewsSheetTitle,
                          icon: Icons.star_border_rounded,
                          star: true,
                          action: () => showReviewsSheet(context, listing.id),
                          hitHeight: 44,
                        ),
                        gap: 6,
                        body: Column(
                          children: [
                            if (reviewsAsync.isLoading)
                              const SizedBox(
                                height: 120,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: referenceOrange,
                                  ),
                                ),
                              )
                            else if (reviewsAsync.hasError)
                              _RetrySection(
                                onRetry: () => ref.invalidate(
                                  reviewsForContractorProvider(listing.id),
                                ),
                              )
                            else ...[
                              _RatingSummary(
                                listing: listing,
                                reviews: reviewsAsync.value ?? const [],
                              ),
                              if (listing.reviewCount >
                                  (reviewsAsync.value?.length ?? 0))
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    context.l10n.reviewsBasedOn(
                                      reviewsAsync.value?.length ?? 0,
                                    ),
                                    style: referenceText(
                                      10,
                                      color: referenceMuted,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 6),
                              for (final review
                                  in (reviewsAsync.value ?? const <Review>[])
                                      .where(
                                        (r) => r.comment?.isNotEmpty == true,
                                      )
                                      .take(2))
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: _ReviewCard(
                                    review: review,
                                    fixture: fixture,
                                  ),
                                ),
                              if (listing.reviewCount == 0)
                                Text(
                                  context.l10n.noReviewsYet,
                                  style: referenceText(
                                    12,
                                    color: referenceMuted,
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 52 + MediaQuery.paddingOf(context).bottom),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _ProfileActions(onQuote: _quote, onContact: _contact),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<(String, String, IconData)> _services(BuildContext context) {
    if (fixture) {
      return [
        ('تصميم داخلي', 'تصميم مساحات عملية وجميلة', Icons.chair_outlined),
        (
          'تنفيذ وتشطيب',
          'تنفيذ بجودة عالية ومتابعة دقيقة',
          Icons.format_paint_outlined,
        ),
        ('استشارات', 'مراجعة أفكار وخطط التنفيذ', Icons.chat_bubble_outline),
      ];
    }
    return listing.specialties
        .map(
          (key) => (
            localizedSpecialtyDisplayLabel(context, key),
            '',
            specialtyIcon(key),
          ),
        )
        .toList();
  }
}

BoxDecoration _quietBox() => BoxDecoration(
  color: Colors.white.withValues(alpha: .85),
  borderRadius: BorderRadius.circular(10),
  border: Border.all(color: const Color(0xfff1eff0)),
  boxShadow: [
    BoxShadow(color: Colors.black.withValues(alpha: .015), blurRadius: 3),
  ],
);

class _ProfileFact extends StatelessWidget {
  const _ProfileFact({
    required this.icon,
    required this.leading,
    required this.text,
  });
  final IconData icon;
  final String leading, text;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(icon, color: referenceMuted, size: 18),
      const SizedBox(width: 7),
      Text(leading, style: referenceText(12, weight: FontWeight.w800)),
      const SizedBox(width: 3),
      Text(text, style: referenceText(11.5, color: referenceMuted)),
    ],
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.icon,
    this.action,
    this.star = false,
    this.hitHeight = 18.2,
  });
  final String title;
  final IconData icon;
  final VoidCallback? action;
  final bool star;
  final double hitHeight;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(
        icon,
        size: 18,
        color: star ? const Color(0xfff7ad21) : referenceOrange,
      ),
      const SizedBox(width: 6),
      Text(title, style: referenceText(14, weight: FontWeight.w800)),
      const Spacer(),
      if (action != null)
        InkWell(
          onTap: action,
          child: SizedBox(
            height: hitHeight,
            child: Align(
              alignment: Alignment.topCenter,
              child: Row(
                children: [
                  Text(
                    context.l10n.referenceViewAll,
                    style: referenceText(
                      11.5,
                      color: referenceOrange,
                      weight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Directionality(
                    textDirection: TextDirection.ltr,
                    child: Icon(
                      Icons.chevron_left,
                      color: referenceOrange,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    ],
  );
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.project, required this.onOpen});
  final PortfolioProject project;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onOpen,
    borderRadius: BorderRadius.circular(9),
    child: Container(
      decoration: _quietBox(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 2.37,
            child: ReferenceMedia(url: project.coverPhotoUrl),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(7, 7, 7, 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: referenceText(10.5, weight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 12,
                      color: referenceMuted,
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        project.location ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: referenceText(9.5, color: referenceMuted),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _WorkStep extends StatelessWidget {
  const _WorkStep({required this.index, required this.last});
  final int index;
  final bool last;
  @override
  Widget build(BuildContext context) {
    final titles = [
      context.l10n.referenceStepOneTitle,
      context.l10n.referenceStepTwoTitle,
      context.l10n.referenceStepThreeTitle,
    ];
    final bodies = [
      context.l10n.referenceStepOneBody,
      context.l10n.referenceStepTwoBody,
      context.l10n.referenceStepThreeBody,
    ];
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 30,
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xffffdfc9),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: referenceText(
                      13,
                      color: referenceOrange,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
                if (!last)
                  Expanded(
                    child: Container(width: 1, color: const Color(0xfff6d4bc)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6, top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titles[index],
                    style: referenceText(11.5, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    bodies[index],
                    style: referenceText(9.5, color: referenceMuted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingSummary extends StatelessWidget {
  const _RatingSummary({required this.listing, required this.reviews});
  final ContractorListing listing;
  final List<Review> reviews;
  @override
  Widget build(BuildContext context) {
    final buckets = {
      for (int i = 1; i <= 5; i++)
        i: reviews.where((r) => r.rating == i).length,
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 5, 11, 3),
      decoration: _quietBox(),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    listing.rating?.toStringAsFixed(1) ?? '—',
                    style: referenceText(
                      29,
                      weight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      5,
                      (_) => const Icon(
                        Icons.star_rounded,
                        color: Color(0xffffaf17),
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    context.l10n.referenceReviewCount(listing.reviewCount),
                    style: referenceText(10.5, color: referenceMuted),
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              margin: const EdgeInsets.symmetric(horizontal: 11),
              color: const Color(0xfff0edf0),
            ),
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  for (int stars = 5; stars >= 1; stars--)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1.5),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xffffaf17),
                            size: 11,
                          ),
                          Text(
                            context.l10n.referenceStarCount(stars),
                            style: referenceText(8.5, color: referenceMuted),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Directionality(
                                textDirection: TextDirection.ltr,
                                child: LinearProgressIndicator(
                                  value: reviews.isEmpty
                                      ? 0
                                      : buckets[stars]! / reviews.length,
                                  minHeight: 5,
                                  color: stars == 5
                                      ? referenceOrange
                                      : const Color(0xffffb326),
                                  backgroundColor: const Color(0xffe9e8ed),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 20,
                            child: Text(
                              '${buckets[stars]}',
                              textAlign: TextAlign.center,
                              style: referenceText(
                                9.5,
                                color: referenceMuted,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review, required this.fixture});
  final Review review;
  final bool fixture;
  @override
  Widget build(BuildContext context) {
    final metadata = fixture
        ? ProfessionalReferenceFixture.reviewerMetadataForReviewId(review.id)
        : null;
    final name = metadata?.name ?? context.l10n.referenceClient;
    final avatar = metadata?.avatarPath;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: _quietBox(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 42,
            height: 42,
            child: ClipOval(child: ReferenceMedia(url: avatar)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: referenceText(9.5, weight: FontWeight.w700),
                    ),
                    const Spacer(),
                    Text(
                      fixture
                          ? '${review.createdAt.day} سبتمبر ${review.createdAt.year}'
                          : DateFormat.yMMMd(
                              Localizations.localeOf(context).languageCode,
                            ).format(review.createdAt),
                      style: referenceText(8, color: referenceMuted),
                    ),
                  ],
                ),
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < review.rating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: const Color(0xffffb21b),
                      size: 11,
                    ),
                  ),
                ),
                Text(
                  review.comment ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: referenceText(8.5, color: referenceMuted, height: 1.3),
                ),
                if (review.isContactOrigin)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      context.l10n.professionalContactReviewAttribution,
                      style: referenceText(8.5, color: referenceMuted),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileActions extends StatelessWidget {
  const _ProfileActions({required this.onQuote, required this.onContact});
  final VoidCallback onQuote, onContact;
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: referenceBackground,
      border: Border(top: BorderSide(color: Color(0xffeee9e5), width: .6)),
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(17, 1, 17, 1),
        child: Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: context.l10n.referenceRequestQuote,
                icon: Icons.assignment_outlined,
                onTap: onQuote,
                filled: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionButton(
                label: context.l10n.referenceMessageProfessional,
                icon: Icons.chat_bubble_outline,
                onTap: onContact,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.filled = false,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    excludeSemantics: true,
    onTap: onTap,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 44,
        child: Center(
          child: Container(
            constraints: const BoxConstraints(minHeight: 38),
            decoration: BoxDecoration(
              color: filled ? referenceOrange : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: referenceOrange.withValues(alpha: filled ? 1 : .65),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: filled ? Colors.white : referenceOrange,
                ),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: referenceText(
                    13,
                    color: filled ? Colors.white : referenceOrange,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _RetrySection extends StatelessWidget {
  const _RetrySection({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) =>
      TextButton(onPressed: onRetry, child: Text(context.l10n.tryAgain));
}

class _ActionSection extends StatelessWidget {
  const _ActionSection({
    required this.heading,
    required this.body,
    required this.gap,
  });
  final Widget heading, body;
  final double gap;
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Padding(
        padding: EdgeInsets.only(top: 18.2 + gap),
        child: body,
      ),
      Positioned(top: 0, left: 0, right: 0, child: heading),
    ],
  );
}
