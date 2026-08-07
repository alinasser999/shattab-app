import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../../core/l10n/l10n_extension.dart';
import '../../../../../core/theme/batsh_icon_size.dart';
import '../../../../../core/theme/batsh_radius.dart';
import '../../../../../core/theme/batsh_shadows.dart';
import '../../../../../core/theme/batsh_spacing.dart';
import '../../../../../core/theme/batsh_typography.dart';
import '../../../../../core/theme/theme_extension.dart';
import '../../../../../core/utils/image_url.dart';
import '../../../../../core/utils/time_format.dart';
import '../../../../../core/widgets/shattab_pattern.dart';
import '../../../../onboarding/domain/onboarding_models.dart';
import '../../../domain/brief.dart';
import '../../../domain/opportunity_experience.dart';

const _terrazzoAsset = 'assets/images/opportunity_terrazzo.png';

class OpportunityCard extends StatelessWidget {
  const OpportunityCard({
    super.key,
    required this.brief,
    required this.match,
    required this.onTap,
    required this.onSave,
    this.recommended = false,
    this.applied = false,
    this.saved = false,
    this.viewed = false,
  });

  final Brief brief;
  final OpportunityMatch match;
  final VoidCallback onTap;
  final VoidCallback onSave;
  final bool recommended;
  final bool applied;
  final bool saved;
  final bool viewed;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(
      recommended ? BatshRadius.xl : BatshRadius.lg,
    );
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: opportunityHeadline(brief.workDescription),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: viewed
              ? context.colorScheme.surfaceContainerLowest.withValues(
                  alpha: 0.82,
                )
              : context.colorScheme.surfaceContainerLowest,
          borderRadius: radius,
          border: Border.all(
            color: recommended
                ? context.colorScheme.primary.withValues(alpha: 0.28)
                : context.colorScheme.outlineVariant.withValues(alpha: 0.55),
          ),
          boxShadow: recommended ? BatshShadows.soft : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(BatshSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: _FreshLabel(createdAt: brief.createdAt)),
                    _SaveButton(saved: saved, onTap: onSave),
                  ],
                ),
                const SizedBox(height: BatshSpacing.sm),
                _OpportunityBody(
                  brief: brief,
                  match: match,
                  recommended: recommended,
                ),
                const SizedBox(height: BatshSpacing.md),
                _OpportunityFacts(brief: brief, applied: applied),
                const SizedBox(height: BatshSpacing.md),
                _DetailsButton(applied: applied, onTap: onTap),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OpportunityBody extends StatelessWidget {
  const _OpportunityBody({
    required this.brief,
    required this.match,
    required this.recommended,
  });

  final Brief brief;
  final OpportunityMatch match;
  final bool recommended;

  @override
  Widget build(BuildContext context) {
    final image = _firstDisplayableImage(brief.photoUrls);
    final photoCount = _displayableImageCount(brief.photoUrls);
    final copy = Expanded(
      child: _CardCopy(brief: brief, match: match),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        copy,
        const SizedBox(width: BatshSpacing.md),
        image == null
            ? _OpportunityPatternPlaceholder(
                kind: _patternForBrief(brief),
                width: recommended ? 116 : 92,
                height: recommended ? 126 : 104,
              )
            : _OpportunityImage(
                url: image,
                count: photoCount,
                width: recommended ? 116 : 92,
                height: recommended ? 126 : 104,
              ),
      ],
    );
  }
}

class _CardCopy extends StatelessWidget {
  const _CardCopy({required this.brief, required this.match});

  final Brief brief;
  final OpportunityMatch match;

  @override
  Widget build(BuildContext context) {
    final specialty = _specialtyLabel(brief);
    final reasons = match.reasons.take(2).toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          specialty.isEmpty ? context.l10n.relevantOpportunity : specialty,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: BatshTypography.labelSm.copyWith(
            color: context.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: BatshSpacing.xs),
        Text(
          opportunityHeadline(brief.workDescription),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: BatshTypography.titleLg.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
        ),
        const SizedBox(height: BatshSpacing.sm),
        _LocationTime(brief: brief),
        if (reasons.isNotEmpty) ...[
          const SizedBox(height: BatshSpacing.sm),
          Wrap(
            spacing: BatshSpacing.xs,
            runSpacing: BatshSpacing.xs,
            children: [
              for (final reason in reasons)
                _ReasonPill(label: _recommendationLabel(context, reason)),
            ],
          ),
        ],
      ],
    );
  }
}

class _OpportunityFacts extends StatelessWidget {
  const _OpportunityFacts({required this.brief, required this.applied});

  final Brief brief;
  final bool applied;

  @override
  Widget build(BuildContext context) {
    final photoCount = _displayableImageCount(brief.photoUrls);
    return Wrap(
      spacing: BatshSpacing.sm,
      runSpacing: BatshSpacing.sm,
      children: [
        _Fact(
          icon: Icons.home_work_outlined,
          label:
              OnboardingCatalog.apartmentLabels[brief.apartmentType] ??
              brief.apartmentType.name,
        ),
        if (photoCount > 0)
          _Fact(
            icon: Icons.photo_library_outlined,
            label: context.l10n.photosCount(photoCount),
          ),
        _Fact(
          icon: applied ? Icons.check_circle_outline : Icons.handyman_outlined,
          label: applied
              ? context.l10n.quoteAlreadySent
              : context.l10n.opportunityAcceptingOffers,
          trust: !applied,
        ),
      ],
    );
  }
}

class _OpportunityImage extends StatelessWidget {
  const _OpportunityImage({
    required this.url,
    required this.count,
    required this.width,
    required this.height,
  });

  final String url;
  final int count;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: context.l10n.projectPhotoLabel,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(BatshRadius.md),
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: sizedImageUrl(url, width: 480),
                fit: BoxFit.cover,
                memCacheWidth: 600,
                placeholder: (_, _) =>
                    _ImagePlaceholder(label: context.l10n.projectPhotoLoading),
                errorWidget: (_, _, _) => _ImagePlaceholder(
                  label: context.l10n.opportunityMediaUnavailable,
                ),
              ),
              if (count > 1)
                PositionedDirectional(
                  end: BatshSpacing.xs,
                  bottom: BatshSpacing.xs,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: BatshSpacing.sm,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: context.colorScheme.scrim.withValues(alpha: 0.72),
                      borderRadius: BatshRadius.brFull,
                    ),
                    child: Text(
                      context.l10n.photosCount(count),
                      style: BatshTypography.labelSm.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
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

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.colorScheme.surfaceContainerLow,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          semanticLabel: label,
          color: context.colorScheme.onSurfaceVariant,
          size: BatshIconSize.lg,
        ),
      ),
    );
  }
}

class _OpportunityPatternPlaceholder extends StatelessWidget {
  const _OpportunityPatternPlaceholder({
    required this.kind,
    required this.width,
    required this.height,
  });

  final ShattabPatternKind kind;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: context.l10n.opportunityMediaUnavailable,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(BatshRadius.md),
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(_terrazzoAsset, fit: BoxFit.cover),
              ColoredBox(
                color: context.colorScheme.surfaceContainerLow.withValues(
                  alpha: context.theme.brightness == Brightness.dark
                      ? 0.78
                      : 0.46,
                ),
              ),
              Positioned.fill(
                child: Opacity(
                  opacity: context.theme.brightness == Brightness.dark
                      ? 0.12
                      : 0.2,
                  child: ShattabPattern(
                    kind: kind,
                    color: context.colorScheme.primary,
                    strokeWidth: 1,
                  ),
                ),
              ),
              Center(
                child: Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.colorScheme.surfaceContainerLowest
                        .withValues(alpha: 0.8),
                    borderRadius: BatshRadius.brMd,
                  ),
                  child: ShattabMotifIcon(
                    motif: ShattabMotif.tile,
                    color: context.colorScheme.primary,
                    size: 22,
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

class _ReasonPill extends StatelessWidget {
  const _ReasonPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 190),
      padding: const EdgeInsets.symmetric(
        horizontal: BatshSpacing.sm,
        vertical: BatshSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: context.colorScheme.secondaryContainer.withValues(alpha: 0.55),
        borderRadius: BatshRadius.brFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: BatshIconSize.xs,
            color: context.colorScheme.secondary,
          ),
          const SizedBox(width: BatshSpacing.xs),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: BatshTypography.labelSm.copyWith(
                color: context.colorScheme.secondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FreshLabel extends StatelessWidget {
  const _FreshLabel({required this.createdAt});

  final DateTime createdAt;

  @override
  Widget build(BuildContext context) {
    final fresh =
        !DateTime.now().difference(createdAt).isNegative &&
        DateTime.now().difference(createdAt) < const Duration(hours: 24);
    return Text(
      _cleanCardCopy(
        fresh
            ? '${context.l10n.newBadge} · ${formatRelativeTime(createdAt)}'
            : formatRelativeTime(createdAt),
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: BatshTypography.labelSm.copyWith(
        color: fresh
            ? context.colorScheme.secondary
            : context.colorScheme.onSurfaceVariant,
        fontWeight: fresh ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }
}

class _LocationTime extends StatelessWidget {
  const _LocationTime({required this.brief});

  final Brief brief;

  @override
  Widget build(BuildContext context) {
    final location = brief.district == null
        ? brief.city
        : '${brief.district}، ${brief.city}';
    return Wrap(
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
          _cleanCardCopy(location),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: BatshTypography.labelSm.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label, this.trust = false});

  final IconData icon;
  final String label;
  final bool trust;

  @override
  Widget build(BuildContext context) {
    final color = trust
        ? context.colorScheme.secondary
        : context.colorScheme.onSurfaceVariant;
    return Container(
      constraints: const BoxConstraints(maxWidth: 190),
      padding: const EdgeInsets.symmetric(
        horizontal: BatshSpacing.sm,
        vertical: BatshSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: trust
            ? context.colorScheme.secondaryContainer.withValues(alpha: 0.5)
            : context.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(BatshRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: BatshIconSize.xs, color: color),
          const SizedBox(width: BatshSpacing.xs),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: BatshTypography.labelSm.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsButton extends StatelessWidget {
  const _DetailsButton({required this.applied, required this.onTap});

  final bool applied;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (!applied) {
      return SizedBox(
        height: 50,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(BatshRadius.md),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(_terrazzoAsset, fit: BoxFit.cover),
              ColoredBox(
                color: context.colorScheme.primary.withValues(alpha: 0.92),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  splashColor: context.colorScheme.onPrimary.withValues(
                    alpha: 0.14,
                  ),
                  child: Center(
                    child: Text(
                      context.l10n.viewOpportunityDetails,
                      style: BatshTypography.labelMd.copyWith(
                        color: context.colorScheme.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return SizedBox(
      height: 48,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: applied
              ? context.colorScheme.secondaryContainer
              : context.colorScheme.primary,
          foregroundColor: applied
              ? context.colorScheme.onSecondaryContainer
              : context.colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BatshRadius.md),
          ),
        ),
        child: Text(
          applied
              ? context.l10n.followQuoteAction
              : context.l10n.viewOpportunityDetails,
          style: BatshTypography.labelMd.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.saved, required this.onTap});

  final bool saved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = saved
        ? context.l10n.removeOpportunityFromSaved
        : context.l10n.saveOpportunity;
    return Semantics(
      button: true,
      label: label,
      child: IconButton(
        onPressed: onTap,
        tooltip: label,
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        padding: EdgeInsets.zero,
        icon: Icon(
          saved ? Icons.bookmark : Icons.bookmark_border,
          size: BatshIconSize.md,
        ),
        color: saved
            ? context.colorScheme.primary
            : context.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

String? _firstDisplayableImage(List<String> urls) {
  for (final url in urls) {
    if (isDisplayableImageUrl(url)) return url.trim();
  }
  return null;
}

int _displayableImageCount(List<String> urls) =>
    urls.where(isDisplayableImageUrl).length;

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

ShattabPatternKind _patternForBrief(Brief brief) {
  final seed = brief.id.codeUnits.fold<int>(0, (sum, code) => sum + code);
  return ShattabPatternKind.values[seed % ShattabPatternKind.values.length];
}

String _cleanCardCopy(String value) => value
    .replaceAll(String.fromCharCodes(const [0x0622, 0x00b7]), '\u2022')
    .replaceAll(String.fromCharCodes(const [0x0637, 0x0152]), '\u060c');
