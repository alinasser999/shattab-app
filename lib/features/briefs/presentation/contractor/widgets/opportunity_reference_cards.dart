import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/env/env.dart';
import '../../../../../core/l10n/catalog_labels.dart';
import '../../../../../core/l10n/l10n_extension.dart';
import '../../../../../core/theme/batsh_icon_size.dart';
import '../../../../../core/theme/batsh_radius.dart';
import '../../../../../core/theme/batsh_shadows.dart';
import '../../../../../core/theme/batsh_spacing.dart';
import '../../../../../core/theme/batsh_typography.dart';
import '../../../../../core/theme/theme_extension.dart';
import '../../../../../core/utils/image_url.dart';
import '../../../../../core/utils/time_format.dart';
import '../../../../quotes/domain/quote.dart';
import '../../../domain/brief.dart';
import '../../../domain/opportunity_experience.dart';

class OpportunityReferenceSectionHeading extends StatelessWidget {
  const OpportunityReferenceSectionHeading({
    super.key,
    required this.title,
    required this.icon,
    required this.onSeeAll,
    this.subtitle,
    this.showSeeAll = true,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onSeeAll;
  final bool showSeeAll;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      BatshSpacing.md,
      BatshSpacing.md,
      BatshSpacing.md,
      BatshSpacing.xs,
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: context.colorScheme.primary,
                    size: BatshIconSize.sm,
                  ),
                  const SizedBox(width: BatshSpacing.xs),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BatshTypography.titleMd.copyWith(
                        color: context.colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 24),
                  child: Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BatshTypography.labelSm.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (showSeeAll)
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.chevron_left_rounded,
                  size: BatshIconSize.sm,
                  color: context.colorScheme.primary,
                ),
                Text(
                  context.l10n.viewAll,
                  style: BatshTypography.labelMd.copyWith(
                    color: context.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

class OpportunityReferenceFeaturedCard extends StatelessWidget {
  const OpportunityReferenceFeaturedCard({
    super.key,
    required this.brief,
    required this.saved,
    required this.onTap,
    required this.onSave,
  });

  final Brief brief;
  final bool saved;
  final VoidCallback onTap;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: BatshSpacing.md),
    padding: const EdgeInsets.all(BatshSpacing.xs),
    decoration: BoxDecoration(
      color: context.colorScheme.surfaceContainerLowest,
      borderRadius: BatshRadius.brLg,
      border: Border.all(
        color: context.colorScheme.outlineVariant.withValues(alpha: .65),
      ),
      boxShadow: BatshShadows.subtle,
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BatshRadius.brMd,
        child: SizedBox(
          height: 112,
          child: Row(
            children: [
              Expanded(
                child: _FeaturedCopy(brief: brief, onTap: onTap),
              ),
              const SizedBox(width: BatshSpacing.xs),
              SizedBox(
                width: 134,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _BriefPhoto(
                      brief: brief,
                      label: context.l10n.projectPhotoLabel,
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      child: _SaveControl(
                        saved: saved,
                        onTap: onSave,
                        photoBadge: true,
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
  );
}

class _FeaturedCopy extends StatelessWidget {
  const _FeaturedCopy({required this.brief, required this.onTap});

  final Brief brief;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(
                Icons.workspace_premium_outlined,
                size: BatshIconSize.sm,
                color: context.colorScheme.primary,
              ),
              const SizedBox(width: BatshSpacing.xxs),
              Expanded(
                child: Text(
                  context.l10n.recommendedForYou,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BatshTypography.labelMd.copyWith(
                    color: context.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: BatshSpacing.xs),
          Text(
            opportunityHeadline(
              brief.projectTitle?.trim().isNotEmpty == true
                  ? brief.projectTitle!
                  : brief.workDescription,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: BatshTypography.titleMd.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: BatshSpacing.xxs),
          Text(
            brief.workDescription,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: BatshTypography.labelSm.copyWith(
              color: context.colorScheme.onSurfaceVariant,
              height: 1.2,
            ),
          ),
          const SizedBox(height: BatshSpacing.xxs),
          _BriefMetadata(brief: brief, compact: true),
        ],
      ),
    ),
  );
}

class OpportunityReferenceRailCard extends StatelessWidget {
  const OpportunityReferenceRailCard({
    super.key,
    required this.brief,
    required this.saved,
    required this.onTap,
    required this.onSave,
  });

  final Brief brief;
  final bool saved;
  final VoidCallback onTap;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) => Container(
    width: 116,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: context.colorScheme.surfaceContainerLowest,
      borderRadius: BatshRadius.brMd,
      border: Border.all(
        color: context.colorScheme.outlineVariant.withValues(alpha: .65),
      ),
      boxShadow: BatshShadows.subtle,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 74,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _BriefPhoto(
                    brief: brief,
                    label: context.l10n.projectPhotoLabel,
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    child: _SaveControl(
                      saved: saved,
                      onTap: onSave,
                      photoBadge: true,
                    ),
                  ),
                  PositionedDirectional(
                    bottom: BatshSpacing.xxs,
                    end: BatshSpacing.xxs,
                    child: const _ArrowCircle(),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  BatshSpacing.xs,
                  BatshSpacing.xxs,
                  BatshSpacing.xs,
                  BatshSpacing.xs,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      opportunityHeadline(
                        brief.projectTitle?.trim().isNotEmpty == true
                            ? brief.projectTitle!
                            : brief.workDescription,
                        maxLength: 42,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: BatshTypography.labelMd.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: BatshSpacing.xxs),
                    _LocationLine(brief: brief),
                    const Spacer(),
                    _RailBriefMetadata(brief: brief),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

/// The fresh row uses the reference's compact photo-and-copy card, while the
/// recommendation and area rails keep their portrait card treatment.
class OpportunityReferenceFreshCard extends StatelessWidget {
  const OpportunityReferenceFreshCard({
    super.key,
    required this.brief,
    required this.saved,
    required this.onTap,
    required this.onSave,
  });

  final Brief brief;
  final bool saved;
  final VoidCallback onTap;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) => Container(
    width: 116,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: context.colorScheme.surfaceContainerLowest,
      borderRadius: BatshRadius.brMd,
      border: Border.all(
        color: context.colorScheme.outlineVariant.withValues(alpha: .65),
      ),
      boxShadow: BatshShadows.subtle,
    ),
    child: Row(
      textDirection: ui.TextDirection.ltr,
      children: [
        SizedBox(
          width: 48,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  child: _BriefPhoto(
                    brief: brief,
                    label: context.l10n.projectPhotoLabel,
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                child: _SaveControl(
                  saved: saved,
                  onTap: onSave,
                  photoBadge: true,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(4, 4, 5, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      opportunityHeadline(
                        brief.projectTitle?.trim().isNotEmpty == true
                            ? brief.projectTitle!
                            : brief.workDescription,
                        maxLength: 36,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: BatshTypography.labelSm.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    _LocationLine(brief: brief),
                    const Spacer(),
                    _RailBriefMetadata(brief: brief),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class OpportunityReferenceQuoteRow extends StatelessWidget {
  const OpportunityReferenceQuoteRow({
    super.key,
    required this.quote,
    required this.brief,
    required this.onTap,
  });

  final Quote quote;
  final Brief? brief;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = brief == null
        ? context.l10n.postDetailTitle
        : opportunityHeadline(
            brief!.projectTitle?.trim().isNotEmpty == true
                ? brief!.projectTitle!
                : brief!.workDescription,
          );
    final status = _quoteStatus(context, quote.status);
    return Container(
      margin: const EdgeInsets.only(bottom: BatshSpacing.xs),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerLowest,
        borderRadius: BatshRadius.brMd,
        border: Border.all(
          color: context.colorScheme.outlineVariant.withValues(alpha: .55),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BatshRadius.brMd,
          child: SizedBox(
            height: 62,
            child: Row(
              textDirection: ui.TextDirection.ltr,
              children: [
                const SizedBox(width: BatshSpacing.xs),
                SizedBox(
                  width: 50,
                  height: 48,
                  child: _BriefPhoto(
                    brief: brief,
                    label: context.l10n.projectPhotoLabel,
                  ),
                ),
                const SizedBox(width: BatshSpacing.xs),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: BatshTypography.labelMd.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (brief != null) _LocationLine(brief: brief!),
                    ],
                  ),
                ),
                const SizedBox(width: BatshSpacing.xs),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatRelativeTime(quote.createdAt),
                      maxLines: 1,
                      style: BatshTypography.labelSm.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      constraints: const BoxConstraints(maxWidth: 94),
                      padding: const EdgeInsets.symmetric(
                        horizontal: BatshSpacing.xs,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: status.$2.withValues(alpha: .13),
                        borderRadius: BatshRadius.brSm,
                      ),
                      child: Text(
                        status.$1,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: BatshTypography.labelSm.copyWith(
                          color: status.$2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: BatshSpacing.xs),
                Icon(
                  Icons.chevron_left_rounded,
                  color: context.colorScheme.primary,
                  size: BatshIconSize.sm,
                ),
                const SizedBox(width: BatshSpacing.xxs),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OpportunityReferenceListRow extends StatelessWidget {
  const OpportunityReferenceListRow({
    super.key,
    required this.brief,
    required this.match,
    required this.onTap,
  });

  final Brief brief;
  final OpportunityMatch match;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: BatshSpacing.xs),
    decoration: BoxDecoration(
      color: context.colorScheme.surfaceContainerLowest,
      borderRadius: BatshRadius.brMd,
      border: Border.all(
        color: context.colorScheme.outlineVariant.withValues(alpha: .55),
      ),
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BatshRadius.brMd,
        child: Padding(
          padding: const EdgeInsets.all(BatshSpacing.xs),
          child: Row(
            textDirection: ui.TextDirection.ltr,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: _BriefPhoto(
                  brief: brief,
                  label: context.l10n.projectPhotoLabel,
                ),
              ),
              const SizedBox(width: BatshSpacing.xxs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      opportunityHeadline(
                        brief.projectTitle?.trim().isNotEmpty == true
                            ? brief.projectTitle!
                            : brief.workDescription,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BatshTypography.labelMd.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (brief.targetSpecialties.isNotEmpty)
                      Text(
                        localizedSpecialtyDisplayLabel(
                          context,
                          brief.targetSpecialties.first,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: BatshTypography.labelSm.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    _LocationLine(brief: brief),
                  ],
                ),
              ),
              const SizedBox(width: BatshSpacing.xxs),
              SizedBox(width: 48, child: _ListBriefMetadata(brief: brief)),
              const SizedBox(width: BatshSpacing.xxxs),
              _OpportunityListStatusPill(brief: brief, match: match),
              const SizedBox(width: BatshSpacing.xxxs),
              Container(
                width: 1,
                height: 30,
                color: context.colorScheme.primary.withValues(alpha: .72),
              ),
              const SizedBox(width: BatshSpacing.xxxs),
              Icon(
                Icons.chevron_right_rounded,
                color: context.colorScheme.primary,
                size: BatshIconSize.sm,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class OpportunityAdviceBanner extends StatelessWidget {
  const OpportunityAdviceBanner({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(
      BatshSpacing.md,
      BatshSpacing.md,
      BatshSpacing.md,
      BatshSpacing.md,
    ),
    padding: const EdgeInsets.all(BatshSpacing.md),
    decoration: BoxDecoration(
      color: context.colorScheme.primaryContainer,
      borderRadius: BatshRadius.brLg,
      border: Border.all(
        color: context.colorScheme.primary.withValues(alpha: .18),
      ),
    ),
    child: Row(
      children: [
        Icon(
          Icons.lightbulb_outline_rounded,
          size: BatshIconSize.lg,
          color: context.colorScheme.primary,
        ),
        const SizedBox(width: BatshSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.workAdviceTitle,
                style: BatshTypography.titleMd.copyWith(
                  fontSize: 16,
                  height: 22 / 16,
                  color: context.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: BatshSpacing.xxs),
              Text(
                context.l10n.workAdviceBody,
                style: BatshTypography.labelSm.copyWith(height: 1.3),
              ),
            ],
          ),
        ),
        const SizedBox(width: BatshSpacing.xs),
        FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.sm),
          ),
          child: Text(
            context.l10n.workUpdateProfile,
            textAlign: TextAlign.center,
            style: BatshTypography.labelSm,
          ),
        ),
      ],
    ),
  );
}

class OpportunityReferenceEmptyRail extends StatelessWidget {
  const OpportunityReferenceEmptyRail({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsetsDirectional.only(
      start: BatshSpacing.md,
      end: BatshSpacing.md,
      bottom: BatshSpacing.xs,
    ),
    constraints: const BoxConstraints(minHeight: 56),
    alignment: AlignmentDirectional.centerStart,
    padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.md),
    decoration: BoxDecoration(
      color: context.colorScheme.surfaceContainerLowest,
      borderRadius: BatshRadius.brMd,
      border: Border.all(
        color: context.colorScheme.outlineVariant.withValues(alpha: .55),
      ),
    ),
    child: Text(
      label,
      style: BatshTypography.labelMd.copyWith(
        color: context.colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

class _BriefPhoto extends StatelessWidget {
  const _BriefPhoto({required this.brief, required this.label});

  final Brief? brief;
  final String label;

  @override
  Widget build(BuildContext context) {
    final url = brief?.photoUrls.where(_isTrustedBriefPhotoUrl).firstOrNull;
    if (url == null)
      return _UnavailablePhoto(label: context.l10n.opportunityMediaUnavailable);
    return Semantics(
      image: true,
      label: label,
      child: ClipRRect(
        borderRadius: BatshRadius.brSm,
        child: CachedNetworkImage(
          imageUrl: sizedImageUrl(url, width: 480),
          fit: BoxFit.cover,
          memCacheWidth: 600,
          placeholder: (_, _) =>
              _UnavailablePhoto(label: context.l10n.projectPhotoLoading),
          errorWidget: (_, _, _) => _UnavailablePhoto(
            label: context.l10n.opportunityMediaUnavailable,
          ),
        ),
      ),
    );
  }
}

bool _isTrustedBriefPhotoUrl(String? value) {
  if (!isDisplayableImageUrl(value)) return false;
  final photoUri = Uri.tryParse(value!.trim());
  if (photoUri == null || photoUri.userInfo.isNotEmpty) return false;

  try {
    final storageOrigin = Uri.parse(Env.supabaseUrl);
    if (photoUri.origin != storageOrigin.origin) return false;
  } catch (_) {
    // Without the configured Supabase origin, do not fetch a user-provided URL.
    return false;
  }

  final segments = photoUri.pathSegments;
  final isOriginalBriefObject =
      segments.length > 5 &&
      segments[0] == 'storage' &&
      segments[1] == 'v1' &&
      segments[2] == 'object' &&
      segments[3] == 'public' &&
      segments[4] == 'brief-photos';
  final isTransformedBriefObject =
      segments.length > 6 &&
      segments[0] == 'storage' &&
      segments[1] == 'v1' &&
      segments[2] == 'render' &&
      segments[3] == 'image' &&
      segments[4] == 'public' &&
      segments[5] == 'brief-photos';
  return isOriginalBriefObject || isTransformedBriefObject;
}

class _UnavailablePhoto extends StatelessWidget {
  const _UnavailablePhoto({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: label,
    child: ColoredBox(
      color: context.colorScheme.surfaceContainerLow,
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: BatshIconSize.md,
          color: context.colorScheme.onSurfaceVariant,
        ),
      ),
    ),
  );
}

class _SaveControl extends StatelessWidget {
  const _SaveControl({
    required this.saved,
    required this.onTap,
    this.photoBadge = false,
  });

  final bool saved;
  final VoidCallback onTap;
  final bool photoBadge;

  @override
  Widget build(BuildContext context) {
    final label = saved
        ? context.l10n.removeOpportunityFromSaved
        : context.l10n.saveOpportunity;
    return Semantics(
      button: true,
      onTap: onTap,
      label: label,
      child: ExcludeSemantics(
        child: photoBadge
            ? SizedBox(
                width: 48,
                height: 48,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BatshRadius.brSm,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: context.colorScheme.surfaceContainerLowest
                              .withValues(alpha: .96),
                          borderRadius: BatshRadius.brSm,
                        ),
                        child: Icon(
                          saved
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          size: BatshIconSize.sm,
                          color: context.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            : SizedBox(
                width: 48,
                height: 48,
                child: IconButton(
                  onPressed: onTap,
                  tooltip: label,
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    saved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    size: BatshIconSize.md,
                  ),
                  color: context.colorScheme.primary,
                  style: IconButton.styleFrom(
                    backgroundColor: context.colorScheme.surfaceContainerLowest
                        .withValues(alpha: .94),
                    shape: RoundedRectangleBorder(
                      borderRadius: BatshRadius.brSm,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _OpportunityListStatusPill extends StatelessWidget {
  const _OpportunityListStatusPill({required this.brief, required this.match});

  final Brief brief;
  final OpportunityMatch match;

  @override
  Widget build(BuildContext context) {
    final (label, color, foreground, icon) = switch (true) {
      _ when match.isStrong => (
        context.l10n.opportunitySuitableLabel,
        context.colorScheme.successContainer,
        context.colorScheme.onSuccessContainer,
        Icons.check_circle_rounded,
      ),
      _ when match.reasons.contains(OpportunityRecommendationReason.fresh) => (
        context.l10n.opportunityFreshCount,
        context.colorScheme.warningContainer,
        context.colorScheme.onWarningContainer,
        Icons.schedule_rounded,
      ),
      _ when brief.isActive => (
        context.l10n.opportunityAvailableLabel,
        context.colorScheme.surfaceContainerLow,
        context.colorScheme.onSurfaceVariant,
        Icons.work_outline_rounded,
      ),
      _ => (
        context.l10n.opportunityClosed,
        context.colorScheme.errorContainer,
        context.colorScheme.onErrorContainer,
        Icons.lock_outline_rounded,
      ),
    };

    return Semantics(
      label: label,
      child: Container(
        width: 56,
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.xxxs),
        decoration: BoxDecoration(color: color, borderRadius: BatshRadius.brSm),
        child: Row(
          textDirection: ui.TextDirection.rtl,
          children: [
            Icon(icon, size: 10, color: foreground),
            const SizedBox(width: BatshSpacing.xxxs),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: BatshTypography.labelSm.copyWith(
                  fontSize: 9,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                  color: foreground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListBriefMetadata extends StatelessWidget {
  const _ListBriefMetadata({required this.brief});

  final Brief brief;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final date = DateFormat.yMMMd(locale).format(brief.createdAt.toLocal());
    final area = brief.estimatedArea == null
        ? null
        : context.l10n.workAreaSquareMeters(brief.estimatedArea!);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ListMetadataLine(icon: Icons.calendar_today_outlined, label: date),
        if (area != null) ...[
          const SizedBox(height: BatshSpacing.xxxs),
          _ListMetadataLine(icon: Icons.home_work_outlined, label: area),
        ],
      ],
    );
  }
}

class _ListMetadataLine extends StatelessWidget {
  const _ListMetadataLine({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 10, color: context.colorScheme.onSurfaceVariant),
      const SizedBox(width: BatshSpacing.xxxs),
      Expanded(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerEnd,
          child: Text(
            label,
            maxLines: 1,
            style: BatshTypography.labelSm.copyWith(
              fontSize: 8.5,
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    ],
  );
}

class _ArrowCircle extends StatelessWidget {
  const _ArrowCircle();

  @override
  Widget build(BuildContext context) => Material(
    color: context.colorScheme.surfaceContainerLowest,
    shape: const CircleBorder(),
    elevation: 1,
    child: const ExcludeSemantics(
      child: SizedBox(
        width: 32,
        height: 32,
        child: Icon(Icons.chevron_left_rounded, size: BatshIconSize.md),
      ),
    ),
  );
}

class _RailBriefMetadata extends StatelessWidget {
  const _RailBriefMetadata({required this.brief});

  final Brief brief;

  @override
  Widget build(BuildContext context) {
    final area = brief.estimatedArea;
    final date = DateFormat.yMMMd(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(brief.createdAt.toLocal());
    final style = BatshTypography.labelSm.copyWith(
      color: context.colorScheme.onSurfaceVariant,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (area != null)
          _RailMetadataLine(
            icon: Icons.home_work_outlined,
            label: context.l10n.workAreaSquareMeters(area),
            style: style,
          ),
        _RailMetadataLine(
          icon: Icons.calendar_today_outlined,
          label: date,
          style: style,
        ),
      ],
    );
  }
}

class _RailMetadataLine extends StatelessWidget {
  const _RailMetadataLine({
    required this.icon,
    required this.label,
    required this.style,
  });

  final IconData icon;
  final String label;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(
        icon,
        size: BatshIconSize.xs,
        color: context.colorScheme.onSurfaceVariant,
      ),
      const SizedBox(width: BatshSpacing.xxs),
      Expanded(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style,
        ),
      ),
    ],
  );
}

class _BriefMetadata extends StatelessWidget {
  const _BriefMetadata({required this.brief, required this.compact});

  final Brief brief;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final area = brief.estimatedArea;
    final label = area == null ? null : context.l10n.workAreaSquareMeters(area);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Icon(
            Icons.home_work_outlined,
            size: BatshIconSize.xs,
            color: context.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: BatshSpacing.xxs),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: BatshTypography.labelSm.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
        if (!compact) ...[
          const SizedBox(width: BatshSpacing.xs),
          Icon(
            Icons.calendar_today_outlined,
            size: BatshIconSize.xs,
            color: context.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: BatshSpacing.xxs),
          Text(
            formatRelativeTime(brief.createdAt),
            maxLines: 1,
            style: BatshTypography.labelSm.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _LocationLine extends StatelessWidget {
  const _LocationLine({required this.brief});
  final Brief brief;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(
        Icons.location_on_outlined,
        size: BatshIconSize.xs,
        color: context.colorScheme.onSurfaceVariant,
      ),
      const SizedBox(width: BatshSpacing.xxs),
      Expanded(
        child: Text(
          brief.district?.trim().isNotEmpty == true
              ? '${brief.district}، ${brief.city}'
              : brief.city,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: BatshTypography.labelSm.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    ],
  );
}

(String, Color) _quoteStatus(BuildContext context, QuoteStatus status) =>
    switch (status) {
      QuoteStatus.sent => (
        context.l10n.quoteStatusSent,
        context.colorScheme.tertiary,
      ),
      QuoteStatus.accepted => (
        context.l10n.quoteStatusAccepted,
        context.colorScheme.secondary,
      ),
      QuoteStatus.declined => (
        context.l10n.quoteStatusDeclined,
        context.colorScheme.error,
      ),
      QuoteStatus.withdrawn => (
        context.l10n.quoteStatusWithdrawn,
        context.colorScheme.onSurfaceVariant,
      ),
    };
