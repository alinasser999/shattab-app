import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/batsh_icon_size.dart';
import '../../../../core/theme/batsh_motion.dart';
import '../../../../core/theme/batsh_radius.dart';
import '../../../../core/theme/batsh_shadows.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../../core/utils/time_format.dart';
import '../../../../core/widgets/avatar_with_initials.dart';
import '../../../../core/widgets/batsh_error.dart';
import '../../../../core/widgets/batsh_photo_viewer.dart';
import '../../../../core/widgets/batsh_scaffold.dart';
import '../../../../core/widgets/batsh_shimmer.dart';
import '../../../../core/widgets/batsh_snack.dart';
import '../../../onboarding/domain/onboarding_models.dart';
import '../../../onboarding/presentation/providers/onboarding_provider.dart';
import '../../../portfolio/presentation/providers/my_portfolio_providers.dart';
import '../../../quotes/domain/quote.dart';
import '../../../quotes/presentation/providers/quotes_providers.dart';
import '../../../quotes/presentation/quote_sheet.dart';
import '../../domain/brief.dart';
import '../../domain/homeowner_profile_preview.dart';
import '../../domain/opportunity_experience.dart';
import '../providers/briefs_providers.dart';
import '../providers/opportunity_experience_provider.dart';
import '../widgets/completion_card.dart';

class PostDetailScreen extends ConsumerWidget {
  const PostDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final briefAsync = ref.watch(briefByIdProvider(postId));
    final quoteAsync = ref.watch(myQuoteForBriefProvider(postId));
    final contractor = ref.watch(contractorProfileProvider).value;
    final portfolio = ref.watch(myPortfolioProvider).value ?? const [];
    final interactions = ref.watch(opportunityInteractionsProvider);
    final saved = interactions.savedIds.contains(postId);

    void toggleSaved() {
      final isSaved = ref
          .read(opportunityInteractionsProvider.notifier)
          .toggleSaved(postId);
      BatshSnack.success(
        context,
        isSaved
            ? context.l10n.opportunitySaved
            : context.l10n.opportunityRemovedFromSaved,
      );
    }

    return BatshScaffold(
      title: context.l10n.opportunityDetailsTitle,
      padding: EdgeInsets.zero,
      animateEntrance: false,
      actions: [
        IconButton(
          onPressed: toggleSaved,
          tooltip: saved
              ? context.l10n.removeOpportunityFromSaved
              : context.l10n.saveOpportunity,
          icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
          color: saved ? context.colorScheme.primary : null,
        ),
      ],
      body: briefAsync.when(
        loading: () => const _OpportunityDetailSkeleton(),
        error: (error, _) => BatshError(
          message: ErrorMapper.map(error),
          onRetry: () => ref.invalidate(briefByIdProvider(postId)),
        ),
        data: (brief) {
          if (brief == null) {
            return BatshError(message: context.l10n.postNotFound);
          }
          final quote = quoteAsync.value;
          final match = calculateOpportunityMatch(
            brief: brief,
            contractor: contractor,
            portfolio: portfolio,
          );
          return Consumer(
            builder: (context, ref, _) {
              final homeownerAsync = ref.watch(
                homeownerProfilePreviewProvider(brief.homeownerId),
              );
              return _OpportunityDetailBody(
                brief: brief,
                match: match,
                quote: quote,
                contractor: contractor,
                homeowner: homeownerAsync.value,
                homeownerLoading: homeownerAsync.isLoading,
                saved: saved,
                onSave: toggleSaved,
                onApply: () =>
                    showQuoteSheet(context, briefId: brief.id, existing: quote),
                onFollowQuote: () => context.push(Routes.contractorMyQuotes),
                onCompleteProfile: () =>
                    context.push(Routes.contractorEditProfile),
                onViewHomeowner: () => context.push(
                  Routes.contractorHomeownerProfilePath(brief.homeownerId),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _OpportunityDetailBody extends StatelessWidget {
  const _OpportunityDetailBody({
    required this.brief,
    required this.match,
    required this.quote,
    required this.contractor,
    required this.homeowner,
    required this.homeownerLoading,
    required this.saved,
    required this.onSave,
    required this.onApply,
    required this.onFollowQuote,
    required this.onCompleteProfile,
    required this.onViewHomeowner,
  });

  final Brief brief;
  final OpportunityMatch match;
  final Quote? quote;
  final ContractorProfile? contractor;
  final PublicHomeownerProfile? homeowner;
  final bool homeownerLoading;
  final bool saved;
  final VoidCallback onSave;
  final VoidCallback onApply;
  final VoidCallback onFollowQuote;
  final VoidCallback onCompleteProfile;
  final VoidCallback onViewHomeowner;

  bool get _profileReady =>
      contractor != null &&
      contractor!.specialties.isNotEmpty &&
      contractor!.serviceAreas.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: BatshSpacing.lg),
            children: [
              if (brief.photoUrls.isNotEmpty)
                _OpportunityGallery(photoUrls: brief.photoUrls),
              _PageWidth(child: _OpportunitySummary(brief: brief)),
              _PageWidth(
                child: _HomeownerProfileCard(
                  profile: homeowner,
                  loading: homeownerLoading,
                  onTap: homeowner == null ? null : onViewHomeowner,
                ),
              ),
              _PageWidth(child: _OpportunityMatchCard(match: match)),
              _PageWidth(
                child: _OpportunityTrustBar(brief: brief, quote: quote),
              ),
              _PageWidth(child: _OpportunityTimeline(brief: brief)),
              _PageWidth(
                child: CompletionCard(
                  brief: brief,
                  role: CompletionRole.contractor,
                ),
              ),
              _PageWidth(child: _OwnerNoteCard(brief: brief)),
              _PageWidth(child: _ProjectDetails(brief: brief)),
              _PageWidth(child: const _BudgetUnavailableCard()),
            ],
          ),
        ),
        _OpportunityStickyActions(
          brief: brief,
          quote: quote,
          profileReady: _profileReady,
          saved: saved,
          onSave: onSave,
          onApply: onApply,
          onFollowQuote: onFollowQuote,
          onCompleteProfile: onCompleteProfile,
        ),
      ],
    );
  }
}

class _PageWidth extends StatelessWidget {
  const _PageWidth({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: child,
      ),
    );
  }
}

class _OpportunityGallery extends StatefulWidget {
  const _OpportunityGallery({required this.photoUrls});

  final List<String> photoUrls;

  @override
  State<_OpportunityGallery> createState() => _OpportunityGalleryState();
}

class _OpportunityGalleryState extends State<_OpportunityGallery> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            BatshSpacing.md,
            BatshSpacing.sm,
            BatshSpacing.md,
            0,
          ),
          child: AspectRatio(
            aspectRatio: 16 / 8.5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(BatshRadius.xl),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: widget.photoUrls.length,
                      onPageChanged: (value) => setState(() => _index = value),
                      itemBuilder: (_, index) => Semantics(
                        button: true,
                        label: context.l10n.openPhotoViewer,
                        child: InkWell(
                          onTap: () => BatshPhotoViewer.show(
                            context,
                            urls: widget.photoUrls,
                            initialIndex: index,
                          ),
                          child: CachedNetworkImage(
                            imageUrl: widget.photoUrls[index],
                            fit: BoxFit.cover,
                            memCacheWidth: 1000,
                            placeholder: (_, _) => ColoredBox(
                              color: context.colorScheme.surfaceContainerLow,
                            ),
                            errorWidget: (_, _, _) => ColoredBox(
                              color: context.colorScheme.surfaceContainerLow,
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                color: context.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    top: BatshSpacing.sm,
                    start: BatshSpacing.sm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: BatshSpacing.sm,
                        vertical: BatshSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: context.colorScheme.scrim.withValues(
                          alpha: 0.72,
                        ),
                        borderRadius: BatshRadius.brFull,
                      ),
                      child: Text(
                        '${_index + 1}/${widget.photoUrls.length}',
                        style: BatshTypography.labelSm.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  if (widget.photoUrls.length > 1)
                    Positioned(
                      bottom: BatshSpacing.sm,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < widget.photoUrls.length; i++)
                            AnimatedContainer(
                              duration: BatshMotion.fast,
                              width: i == _index ? 18 : 6,
                              height: 6,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(
                                  alpha: i == _index ? 0.95 : 0.55,
                                ),
                                borderRadius: BatshRadius.brFull,
                              ),
                            ),
                        ],
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
}

class _OpportunitySummary extends StatelessWidget {
  const _OpportunitySummary({required this.brief});

  final Brief brief;

  @override
  Widget build(BuildContext context) {
    final location = brief.district == null
        ? brief.city
        : '${brief.district}، ${brief.city}';
    return Padding(
      padding: const EdgeInsets.all(BatshSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: BatshSpacing.sm,
            children: [
              _StatusChip(
                label: brief.isActive
                    ? context.l10n.opportunityOpen
                    : context.l10n.opportunityClosed,
                active: brief.isActive,
              ),
              _CategoryChip(label: _specialtyLabel(brief)),
            ],
          ),
          const SizedBox(height: BatshSpacing.sm),
          Text(
            opportunityHeadline(brief.workDescription, maxLength: 90),
            style: BatshTypography.titleLg.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          const SizedBox(height: BatshSpacing.sm),
          Wrap(
            spacing: BatshSpacing.xs,
            runSpacing: BatshSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: BatshIconSize.xs,
                color: context.colorScheme.onSurfaceVariant,
              ),
              Text(
                location,
                style: BatshTypography.labelMd.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
              Icon(
                Icons.schedule_outlined,
                size: BatshIconSize.xs,
                color: context.colorScheme.onSurfaceVariant,
              ),
              Text(
                formatRelativeTime(brief.createdAt),
                style: BatshTypography.labelMd.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeownerProfileCard extends StatelessWidget {
  const _HomeownerProfileCard({
    required this.profile,
    required this.loading,
    required this.onTap,
  });

  final PublicHomeownerProfile? profile;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(BatshRadius.lg);
    final details = profile?.details;
    final location = [
      details?.district,
      details?.city,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).join('، ');
    final name = profile?.profile.fullName.trim().isNotEmpty == true
        ? profile!.profile.fullName
        : context.l10n.opportunityPostedBy;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BatshSpacing.md,
        0,
        BatshSpacing.md,
        BatshSpacing.sm,
      ),
      child: Semantics(
        button: onTap != null,
        label: onTap != null
            ? context.l10n.viewHomeownerProfile
            : context.l10n.opportunityPostedBy,
        child: Material(
          color: context.colorScheme.surfaceContainerLowest,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Container(
              padding: const EdgeInsets.all(BatshSpacing.md),
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(
                  color: context.colorScheme.outlineVariant.withValues(
                    alpha: 0.55,
                  ),
                ),
              ),
              child: loading
                  ? const Row(
                      children: [
                        BatshShimmerBox(
                          width: 48,
                          height: 48,
                          borderRadius: BatshRadius.brFull,
                        ),
                        SizedBox(width: BatshSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              BatshShimmerBox(width: 92, height: 12),
                              SizedBox(height: BatshSpacing.xs),
                              BatshShimmerBox(width: 150, height: 16),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        AvatarWithInitials(
                          imageUrl: profile?.profile.avatarUrl,
                          name: name,
                          radius: 24,
                        ),
                        const SizedBox(width: BatshSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.l10n.opportunityPostedBy,
                                style: BatshTypography.labelSm.copyWith(
                                  color: context.colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: BatshTypography.titleMd.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (location.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: BatshTypography.labelSm.copyWith(
                                    color: context.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (onTap != null)
                          Icon(
                            Icons.chevron_left_rounded,
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OpportunityMatchCard extends StatelessWidget {
  const _OpportunityMatchCard({required this.match});

  final OpportunityMatch match;

  @override
  Widget build(BuildContext context) {
    final reasons = match.reasons
        .where(
          (reason) => reason != OpportunityRecommendationReason.projectPhotos,
        )
        .take(4)
        .toList();
    return _SectionCard(
      margin: const EdgeInsets.fromLTRB(
        BatshSpacing.md,
        0,
        BatshSpacing.md,
        BatshSpacing.sm,
      ),
      tint: context.colorScheme.secondaryContainer.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.whyOpportunityMatches,
                  style: BatshTypography.titleMd.copyWith(
                    color: context.colorScheme.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: BatshSpacing.sm,
                  vertical: BatshSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: context.colorScheme.surface,
                  borderRadius: BatshRadius.brFull,
                ),
                child: Text(
                  match.isStrong
                      ? context.l10n.strongMatch
                      : context.l10n.relevantOpportunity,
                  style: BatshTypography.labelSm.copyWith(
                    color: context.colorScheme.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: BatshSpacing.sm),
          if (reasons.isEmpty)
            Text(
              context.l10n.matchDataInsufficient,
              style: BatshTypography.bodyMd.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            )
          else
            for (final reason in reasons)
              Padding(
                padding: const EdgeInsets.only(bottom: BatshSpacing.xs),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: context.colorScheme.secondary,
                      size: BatshIconSize.xs,
                    ),
                    const SizedBox(width: BatshSpacing.xs),
                    Expanded(
                      child: Text(
                        _recommendationLabel(context, reason),
                        style: BatshTypography.bodyMd,
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

class _OpportunityTrustBar extends StatelessWidget {
  const _OpportunityTrustBar({required this.brief, required this.quote});

  final Brief brief;
  final Quote? quote;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BatshSpacing.md,
        0,
        BatshSpacing.md,
        BatshSpacing.md,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: context.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(BatshRadius.lg),
          border: Border.all(
            color: context.colorScheme.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: _TrustMetric(
                icon: Icons.schedule_outlined,
                label: formatRelativeTime(brief.createdAt),
              ),
            ),
            const _MetricDivider(),
            Expanded(
              child: _TrustMetric(
                icon: Icons.photo_library_outlined,
                label: context.l10n.photosCount(brief.photoUrls.length),
              ),
            ),
            const _MetricDivider(),
            Expanded(
              child: _TrustMetric(
                icon: quote == null
                    ? Icons.request_quote_outlined
                    : Icons.check_circle_outline,
                label: quote == null
                    ? context.l10n.opportunityAcceptingOffers
                    : context.l10n.quoteAlreadySent,
                trust: quote != null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrustMetric extends StatelessWidget {
  const _TrustMetric({
    required this.icon,
    required this.label,
    this.trust = false,
  });

  final IconData icon;
  final String label;
  final bool trust;

  @override
  Widget build(BuildContext context) {
    final color = trust
        ? context.colorScheme.secondary
        : context.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BatshSpacing.xs,
        vertical: BatshSpacing.sm,
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: BatshIconSize.sm),
          const SizedBox(height: BatshSpacing.xs),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: BatshTypography.labelSm.copyWith(color: color, height: 1.3),
          ),
        ],
      ),
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 56,
      color: context.colorScheme.outlineVariant.withValues(alpha: 0.5),
    );
  }
}

class _OpportunityTimeline extends StatelessWidget {
  const _OpportunityTimeline({required this.brief});

  final Brief brief;

  int get _stage => switch (brief.stage) {
    BriefStage.open => 0,
    BriefStage.hired => 1,
    BriefStage.completionRequested || BriefStage.completed => 2,
  };

  @override
  Widget build(BuildContext context) {
    final labels = [
      context.l10n.timelineAcceptOffers,
      context.l10n.timelineChooseContractor,
      context.l10n.timelineStartWork,
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BatshSpacing.md,
        0,
        BatshSpacing.md,
        BatshSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.opportunityTimeline,
            style: BatshTypography.titleMd.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: BatshSpacing.md),
          Row(
            children: [
              for (var index = 0; index < labels.length; index++) ...[
                Expanded(
                  child: _TimelineStep(
                    label: labels[index],
                    complete: index <= _stage,
                    current: index == _stage,
                  ),
                ),
                if (index < labels.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: index < _stage
                          ? context.colorScheme.primary
                          : context.colorScheme.outlineVariant,
                    ),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.label,
    required this.complete,
    required this.current,
  });

  final String label;
  final bool complete;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final color = complete
        ? context.colorScheme.primary
        : context.colorScheme.outlineVariant;
    return Column(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: current
                ? color
                : complete
                ? context.colorScheme.primaryContainer
                : context.colorScheme.surfaceContainerHigh,
            shape: BoxShape.circle,
          ),
          child: Icon(
            complete ? Icons.check_rounded : Icons.circle_outlined,
            size: BatshIconSize.xs,
            color: current
                ? context.colorScheme.onPrimary
                : complete
                ? context.colorScheme.primary
                : context.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: BatshSpacing.xs),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: BatshTypography.labelSm.copyWith(
            color: current
                ? context.colorScheme.onSurface
                : context.colorScheme.onSurfaceVariant,
            fontWeight: current ? FontWeight.w700 : FontWeight.w500,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

class _OwnerNoteCard extends StatelessWidget {
  const _OwnerNoteCard({required this.brief});

  final Brief brief;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      margin: const EdgeInsets.fromLTRB(
        BatshSpacing.md,
        0,
        BatshSpacing.md,
        BatshSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.format_quote_rounded,
                color: context.colorScheme.primary,
              ),
              const SizedBox(width: BatshSpacing.sm),
              Text(
                context.l10n.ownerNoteTitle,
                style: BatshTypography.titleMd.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: BatshSpacing.sm),
          Text(
            brief.workDescription,
            style: BatshTypography.bodyLg.copyWith(height: 1.65),
          ),
          const SizedBox(height: BatshSpacing.sm),
          Text(
            context.l10n.ownerPrivacyHint,
            style: BatshTypography.labelSm.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectDetails extends StatelessWidget {
  const _ProjectDetails({required this.brief});

  final Brief brief;

  @override
  Widget build(BuildContext context) {
    final specialties = brief.targetSpecialties
        .map((key) => OnboardingCatalog.specialtiesCatalog[key] ?? key)
        .join('، ');
    final apartment =
        OnboardingCatalog.apartmentLabels[brief.apartmentType] ??
        brief.apartmentType.name;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BatshSpacing.md,
        0,
        BatshSpacing.md,
        BatshSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.projectDetailsTitle,
            style: BatshTypography.titleMd.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: BatshSpacing.sm),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth - BatshSpacing.sm) / 2;
              return Wrap(
                spacing: BatshSpacing.sm,
                runSpacing: BatshSpacing.sm,
                children: [
                  _DetailTile(
                    width: width,
                    icon: Icons.home_outlined,
                    label: context.l10n.apartmentTypeLabel,
                    value: apartment,
                  ),
                  _DetailTile(
                    width: width,
                    icon: Icons.location_city_outlined,
                    label: context.l10n.cityLabel,
                    value: brief.city,
                  ),
                  if (brief.district != null)
                    _DetailTile(
                      width: width,
                      icon: Icons.location_on_outlined,
                      label: context.l10n.districtLabel,
                      value: brief.district!,
                    ),
                  _DetailTile(
                    width: width,
                    icon: Icons.handyman_outlined,
                    label: context.l10n.filterCategory,
                    value: specialties.isEmpty
                        ? context.l10n.notSpecified
                        : specialties,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
  });

  final double width;
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(BatshSpacing.sm),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(BatshRadius.md),
        border: Border.all(
          color: context.colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: BatshIconSize.xs,
                color: context.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: BatshSpacing.xs),
              Expanded(
                child: Text(
                  label,
                  style: BatshTypography.labelSm.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: BatshSpacing.xs),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: BatshTypography.labelMd.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetUnavailableCard extends StatelessWidget {
  const _BudgetUnavailableCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      margin: const EdgeInsets.fromLTRB(
        BatshSpacing.md,
        0,
        BatshSpacing.md,
        BatshSpacing.md,
      ),
      tint: context.colorScheme.surfaceContainerLow,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.payments_outlined,
            color: context.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: BatshSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.budgetAndTimingTitle,
                  style: BatshTypography.titleMd.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: BatshSpacing.xs),
                Text(
                  context.l10n.budgetAndTimingUnavailable,
                  style: BatshTypography.bodyMd.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                    height: 1.5,
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child, required this.margin, this.tint});

  final Widget child;
  final EdgeInsets margin;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(BatshSpacing.md),
      decoration: BoxDecoration(
        color: tint ?? context.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(BatshRadius.lg),
        border: Border.all(
          color: context.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: tint == null ? BatshShadows.soft : null,
      ),
      child: child,
    );
  }
}

class _OpportunityStickyActions extends StatelessWidget {
  const _OpportunityStickyActions({
    required this.brief,
    required this.quote,
    required this.profileReady,
    required this.saved,
    required this.onSave,
    required this.onApply,
    required this.onFollowQuote,
    required this.onCompleteProfile,
  });

  final Brief brief;
  final Quote? quote;
  final bool profileReady;
  final bool saved;
  final VoidCallback onSave;
  final VoidCallback onApply;
  final VoidCallback onFollowQuote;
  final VoidCallback onCompleteProfile;

  @override
  Widget build(BuildContext context) {
    final enabled = brief.isActive;
    final primaryLabel = !enabled
        ? context.l10n.opportunityClosed
        : quote != null
        ? context.l10n.followQuoteAction
        : !profileReady
        ? context.l10n.completeProfileBeforeApplying
        : context.l10n.submitYourQuote;
    final primaryAction = !enabled
        ? null
        : quote != null
        ? onFollowQuote
        : !profileReady
        ? onCompleteProfile
        : onApply;

    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerLowest,
        border: Border(
          top: BorderSide(
            color: context.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        boxShadow: BatshShadows.raised,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            BatshSpacing.md,
            BatshSpacing.sm,
            BatshSpacing.md,
            BatshSpacing.sm,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 52,
                height: 52,
                child: OutlinedButton(
                  onPressed: onSave,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    side: BorderSide(color: context.colorScheme.primary),
                  ),
                  child: Icon(
                    saved ? Icons.bookmark : Icons.bookmark_border,
                    color: context.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: BatshSpacing.sm),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: primaryAction,
                    icon: Icon(
                      quote != null
                          ? Icons.receipt_long_outlined
                          : Icons.send_outlined,
                    ),
                    label: Text(
                      primaryLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BatshTypography.labelLg.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? context.colorScheme.secondary
        : context.colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BatshSpacing.sm,
        vertical: BatshSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: active
            ? context.colorScheme.secondaryContainer.withValues(alpha: 0.6)
            : context.colorScheme.surfaceContainerHigh,
        borderRadius: BatshRadius.brFull,
      ),
      child: Text(
        label,
        style: BatshTypography.labelSm.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: BatshSpacing.sm,
        vertical: BatshSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: context.colorScheme.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BatshRadius.brFull,
      ),
      child: Text(
        label,
        style: BatshTypography.labelSm.copyWith(
          color: context.colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _OpportunityDetailSkeleton extends StatelessWidget {
  const _OpportunityDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(BatshSpacing.md),
      children: const [
        BatshShimmerBox(
          width: double.infinity,
          height: 210,
          borderRadius: BatshRadius.brXl,
        ),
        SizedBox(height: BatshSpacing.md),
        BatshShimmerBox(width: 120, height: 24, borderRadius: BatshRadius.brMd),
        SizedBox(height: BatshSpacing.sm),
        BatshShimmerBox(
          width: double.infinity,
          height: 28,
          borderRadius: BatshRadius.brMd,
        ),
        SizedBox(height: BatshSpacing.md),
        BatshShimmerBox(
          width: double.infinity,
          height: 170,
          borderRadius: BatshRadius.brLg,
        ),
        SizedBox(height: BatshSpacing.md),
        BatshShimmerBox(
          width: double.infinity,
          height: 92,
          borderRadius: BatshRadius.brLg,
        ),
      ],
    );
  }
}

String _specialtyLabel(Brief brief) {
  if (brief.targetSpecialties.isEmpty) return '';
  final key = brief.targetSpecialties.first;
  return OnboardingCatalog.specialtiesCatalog[key] ?? key;
}

String _recommendationLabel(
  BuildContext context,
  OpportunityRecommendationReason reason,
) => switch (reason) {
  OpportunityRecommendationReason.specialtyMatch =>
    context.l10n.matchReasonSpecialty,
  OpportunityRecommendationReason.serviceAreaMatch =>
    context.l10n.matchReasonServiceArea,
  OpportunityRecommendationReason.similarPortfolio =>
    context.l10n.matchReasonPortfolio,
  OpportunityRecommendationReason.fresh => context.l10n.matchReasonFresh,
  OpportunityRecommendationReason.projectPhotos =>
    context.l10n.matchReasonPhotos,
};
