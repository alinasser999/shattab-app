import '../../../../core/widgets/professional_reference_states.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/l10n/catalog_labels.dart';
import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/professional_reference_theme.dart';
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _scroll,
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            _ProfileIconButton(
                              icon: Icons.chevron_right,
                              label: context.l10n.back,
                              onTap: () {
                                if (context.canPop()) {
                                  context.pop();
                                } else {
                                  context.go(Routes.homeownerDiscover);
                                }
                              },
                            ),
                            Expanded(
                              child: Text(
                                context.l10n.referenceProfileTitle,
                                textAlign: TextAlign.center,
                                style: referenceText(
                                  18,
                                  weight: FontWeight.w700,
                                ),
                              ),
                            ),
                            _ProfileIconButton(
                              icon: saved
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              label: saved
                                  ? context.l10n.referenceUnsaveProfessional
                                  : context.l10n.referenceSaveProfessional,
                              onTap: _save,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ReferenceGallery(
                          photos: photos,
                          ratio: 2.01,
                          premium: listing.isSponsored,
                          premiumLabel: listing.isPro,
                          compact: true,
                        ),
                      ),
                      ReferencePremiumSurface(
                        premium: listing.isSponsored,
                        profile: true,
                        child: _ProfileIdentity(
                          listing: listing,
                          fixture: fixture,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
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
                              height: 40,
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
                                    child: Container(
                                      constraints: const BoxConstraints(
                                        minHeight: 48,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: const Color(0xffe9e7eb),
                                        ),
                                        color: Colors.white.withValues(
                                          alpha: .55,
                                        ),
                                        borderRadius: BorderRadius.circular(11),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            icons[i],
                                            size: 20,
                                            color: referenceNavy,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            labels[i],
                                            textAlign: TextAlign.center,
                                            style: referenceText(
                                              14,
                                              weight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
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
                              style: referenceText(18, weight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              listing.bio?.trim().isNotEmpty == true
                                  ? listing.bio!
                                  : context.l10n.referenceMissingBio,
                              style: referenceText(
                                16,
                                color: ProfessionalReferenceTheme.muted,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        key: _sections[1],
                        padding: const EdgeInsets.symmetric(horizontal: 17),
                        child: _ActionSection(
                          heading: _SectionHeading(
                            title: context.l10n.referencePreviousWork,
                            icon: Icons.home_repair_service_outlined,
                            action: () => context.push(
                              Routes.homeownerContractorPortfolioPath(
                                listing.id,
                              ),
                            ),
                          ),
                          gap: 8,
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
                                ProfessionalReferenceState(
                                  compact: true,
                                  motif: ProfessionalReferenceMotif.portfolio,
                                  title: context.l10n.noWorksTitle,
                                  message: context.l10n.statePublicWorksMessage,
                                  primaryLabel:
                                      context.l10n.stateServicesAction,
                                  onPrimary: () => _goToSection(2),
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
                      const SizedBox(height: 24),
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
                                    minHeight: 48,
                                  ),
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 5),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 12,
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
                                                      16,
                                                      weight: FontWeight.w700,
                                                    ),
                                                  ),
                                                  if (service.$2.isNotEmpty)
                                                    Text(
                                                      service.$2,
                                                      style: referenceText(
                                                        14,
                                                        color:
                                                            ProfessionalReferenceTheme
                                                                .muted,
                                                        height: 1.5,
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
                                                size: 22,
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
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final area in listing.serviceAreas.take(3))
                                  Container(
                                    constraints: const BoxConstraints(
                                      minHeight: 40,
                                    ),
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xfffaecdf),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      area,
                                      textAlign: TextAlign.center,
                                      style: referenceText(
                                        14,
                                        color: ProfessionalReferenceTheme.muted,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _SectionHeading(
                              title: context.l10n.referenceWorkingApproach,
                              icon: Icons.settings_outlined,
                            ),
                            const SizedBox(height: 10),
                            if (!fixture)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  context.l10n.referenceWorkApproachDisclaimer,
                                  style: referenceText(
                                    14,
                                    color: ProfessionalReferenceTheme.muted,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            for (int i = 0; i < 3; i++)
                              _WorkStep(index: i, last: i == 2),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        key: _sections[3],
                        padding: const EdgeInsets.symmetric(horizontal: 17),
                        child: _ActionSection(
                          heading: _SectionHeading(
                            title: context.l10n.reviewsSheetTitle,
                            icon: Icons.star_border_rounded,
                            star: true,
                            action: () => showReviewsSheet(context, listing.id),
                          ),
                          gap: 8,
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
                                        14,
                                        color: ProfessionalReferenceTheme.muted,
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
                                if (reviewsAsync.value?.isEmpty == true)
                                  ProfessionalReferenceState(
                                    compact: true,
                                    motif: ProfessionalReferenceMotif.reviews,
                                    title: context.l10n.noReviewsYet,
                                    message:
                                        context.l10n.stateClientReviewsMessage,
                                    primaryLabel:
                                        context.l10n.stateServicesAction,
                                    onPrimary: () => _goToSection(2),
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              _ProfileActions(onQuote: _quote, onContact: _contact),
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

class _ProfileIconButton extends StatelessWidget {
  const _ProfileIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, size: 24, color: referenceNavy),
        ),
      ),
    ),
  );
}

class _ProfileIdentity extends StatelessWidget {
  const _ProfileIdentity({required this.listing, required this.fixture});
  final ContractorListing listing;
  final bool fixture;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final useSideMetadata =
          MediaQuery.sizeOf(context).width >= 375 &&
          MediaQuery.textScalerOf(context).scale(14) <= 16;
      final identity = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            referenceName(listing),
            style: referenceText(22, weight: FontWeight.w700, height: 1.3),
          ),
          const SizedBox(height: 4),
          Text(
            fixture ? 'مصمم داخلي' : referenceSpecialty(context, listing),
            style: referenceText(
              14,
              color: ProfessionalReferenceTheme.muted,
              height: 1.5,
            ),
          ),
        ],
      );
      final metadata = _ProfileIdentityMetadata(listing: listing);

      return Padding(
        padding: const EdgeInsets.fromLTRB(17, 12, 17, 12),
        child: useSideMetadata
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ReferenceAvatar(listing: listing, size: 64),
                  const SizedBox(width: 12),
                  Expanded(child: identity),
                  const SizedBox(width: 10),
                  SizedBox(width: constraints.maxWidth * .37, child: metadata),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ReferenceAvatar(listing: listing, size: 64),
                      const SizedBox(width: 12),
                      Expanded(child: identity),
                    ],
                  ),
                  const SizedBox(height: 10),
                  metadata,
                ],
              ),
      );
    },
  );
}

class _ProfileIdentityMetadata extends StatelessWidget {
  const _ProfileIdentityMetadata({required this.listing});
  final ContractorListing listing;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Directionality(
        textDirection: TextDirection.ltr,
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Icon(Icons.star_rounded, size: 22, color: Color(0xffffb322)),
            const SizedBox(width: 4),
            Text(
              listing.rating?.toStringAsFixed(1) ?? '—',
              style: referenceText(20, weight: FontWeight.w700),
            ),
            const SizedBox(width: 4),
            Text(
              context.l10n.referenceReviewCount(listing.reviewCount),
              style: referenceText(14, color: ProfessionalReferenceTheme.muted),
            ),
          ],
        ),
      ),
      const SizedBox(height: 4),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Text(
              listing.serviceAreas.firstOrNull ?? '',
              textAlign: TextAlign.end,
              style: referenceText(
                14,
                color: ProfessionalReferenceTheme.muted,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(width: 5),
          const Icon(
            Icons.location_on_outlined,
            color: ProfessionalReferenceTheme.muted,
            size: 20,
          ),
        ],
      ),
      if (listing.verified)
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xffeaf0db),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.l10n.referenceVerified,
                    style: referenceText(
                      14,
                      color: const Color(0xff426129),
                      weight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.check_circle,
                    size: 18,
                    color: Color(0xff426129),
                  ),
                ],
              ),
            ),
          ),
        ),
    ],
  );
}

class _ProfileFact extends StatelessWidget {
  const _ProfileFact({
    required this.icon,
    required this.leading,
    required this.text,
  });
  final IconData icon;
  final String leading, text;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: ProfessionalReferenceTheme.muted, size: 22),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              leading,
              textAlign: TextAlign.center,
              style: referenceText(20, weight: FontWeight.w700),
            ),
          ),
        ],
      ),
      const SizedBox(height: 2),
      Text(
        text,
        textAlign: TextAlign.center,
        style: referenceText(
          14,
          color: ProfessionalReferenceTheme.muted,
          height: 1.5,
        ),
      ),
    ],
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.icon,
    this.action,
    this.star = false,
  });
  final String title;
  final IconData icon;
  final VoidCallback? action;
  final bool star;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final reflowAction =
          action != null &&
          (constraints.maxWidth < 310 ||
              (MediaQuery.textScalerOf(context).scale(14) > 16 &&
                  constraints.maxWidth < 380));
      final titleRow = Row(
        children: [
          Icon(
            icon,
            size: 24,
            color: star ? const Color(0xfff7ad21) : referenceOrange,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: referenceText(18, weight: FontWeight.w700, height: 1.3),
            ),
          ),
        ],
      );
      final actionButton = action == null
          ? null
          : Semantics(
              button: true,
              child: InkWell(
                onTap: action,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.l10n.referenceViewAll,
                        textAlign: TextAlign.center,
                        style: referenceText(
                          14,
                          color: ProfessionalReferenceTheme.action,
                          weight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Directionality(
                        textDirection: TextDirection.ltr,
                        child: Icon(
                          Icons.chevron_left,
                          color: ProfessionalReferenceTheme.action,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );

      if (reflowAction) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            titleRow,
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: actionButton,
            ),
          ],
        );
      }
      return ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(
          children: [
            Expanded(child: titleRow),
            ?actionButton,
          ],
        ),
      );
    },
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
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.title,
                  style: referenceText(
                    16,
                    weight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: ProfessionalReferenceTheme.muted,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        project.location ?? '',
                        style: referenceText(
                          14,
                          color: ProfessionalReferenceTheme.muted,
                          height: 1.5,
                        ),
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
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xffffdfc9),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: referenceText(
                      14,
                      color: ProfessionalReferenceTheme.action,
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
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10, top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titles[index],
                    style: referenceText(
                      16,
                      weight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    bodies[index],
                    style: referenceText(
                      14,
                      color: ProfessionalReferenceTheme.muted,
                      height: 1.5,
                    ),
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
    final score = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          listing.rating?.toStringAsFixed(1) ?? '—',
          style: referenceText(32, weight: FontWeight.w700, height: 1.2),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            5,
            (_) => const Icon(
              Icons.star_rounded,
              color: Color(0xffffaf17),
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          context.l10n.referenceReviewCount(listing.reviewCount),
          textAlign: TextAlign.center,
          style: referenceText(14, color: ProfessionalReferenceTheme.muted),
        ),
      ],
    );
    final distribution = Column(
      children: [
        for (int stars = 5; stars >= 1; stars--)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: Color(0xffffaf17),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  context.l10n.referenceStarCount(stars),
                  style: referenceText(
                    14,
                    color: ProfessionalReferenceTheme.muted,
                  ),
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
                        minHeight: 6,
                        color: stars == 5
                            ? referenceOrange
                            : const Color(0xffffb326),
                        backgroundColor: const Color(0xffe9e8ed),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${buckets[stars]}',
                  textAlign: TextAlign.center,
                  style: referenceText(
                    14,
                    color: ProfessionalReferenceTheme.muted,
                    weight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final stack =
            constraints.maxWidth < 350 ||
            MediaQuery.textScalerOf(context).scale(14) > 16;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: _quietBox(),
          child: stack
              ? Column(
                  children: [
                    score,
                    const Divider(height: 24, color: Color(0xfff0edf0)),
                    distribution,
                  ],
                )
              : IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(flex: 4, child: score),
                      Container(
                        width: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        color: const Color(0xfff0edf0),
                      ),
                      Expanded(flex: 5, child: distribution),
                    ],
                  ),
                ),
        );
      },
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
      padding: const EdgeInsets.all(12),
      decoration: _quietBox(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: ClipOval(child: ReferenceMedia(url: avatar)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  runSpacing: 4,
                  children: [
                    Text(
                      name,
                      style: referenceText(16, weight: FontWeight.w700),
                    ),
                    Text(
                      fixture
                          ? '${review.createdAt.day} سبتمبر ${review.createdAt.year}'
                          : DateFormat.yMMMd(
                              Localizations.localeOf(context).languageCode,
                            ).format(review.createdAt),
                      style: referenceText(
                        14,
                        color: ProfessionalReferenceTheme.muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < review.rating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: const Color(0xffffb21b),
                      size: 18,
                    ),
                  ),
                ),
                Text(
                  review.comment ?? '',
                  style: referenceText(
                    16,
                    color: ProfessionalReferenceTheme.muted,
                    height: 1.5,
                  ),
                ),
                if (review.isContactOrigin)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      context.l10n.professionalContactReviewAttribution,
                      style: referenceText(
                        14,
                        color: ProfessionalReferenceTheme.muted,
                        height: 1.5,
                      ),
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
        padding: const EdgeInsets.fromLTRB(17, 12, 17, 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stacked =
                constraints.maxWidth < 320 &&
                MediaQuery.textScalerOf(context).scale(14) > 16;
            final quote = _ActionButton(
              label: context.l10n.referenceRequestQuote,
              icon: Icons.assignment_outlined,
              onTap: onQuote,
              filled: true,
            );
            final contact = _ActionButton(
              label: context.l10n.referenceMessageProfessional,
              icon: Icons.chat_bubble_outline,
              onTap: onContact,
            );

            if (stacked) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [quote, const SizedBox(height: 8), contact],
              );
            }
            return Row(
              children: [
                Expanded(child: quote),
                const SizedBox(width: 8),
                Expanded(child: contact),
              ],
            );
          },
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
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: filled
              ? ProfessionalReferenceTheme.action
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: ProfessionalReferenceTheme.action.withValues(
              alpha: filled ? 1 : .8,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: filled ? Colors.white : ProfessionalReferenceTheme.action,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: referenceText(
                  14,
                  color: filled
                      ? Colors.white
                      : ProfessionalReferenceTheme.action,
                  weight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _RetrySection extends StatelessWidget {
  const _RetrySection({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onRetry,
    style: TextButton.styleFrom(
      minimumSize: const Size(48, 48),
      foregroundColor: ProfessionalReferenceTheme.action,
    ),
    child: Text(
      context.l10n.tryAgain,
      style: referenceText(
        14,
        color: ProfessionalReferenceTheme.action,
        weight: FontWeight.w600,
      ),
    ),
  );
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
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      heading,
      SizedBox(height: gap),
      body,
    ],
  );
}
