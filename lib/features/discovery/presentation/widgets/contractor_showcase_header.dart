part of 'contractor_showcase.dart';

class _BackButton extends StatelessWidget {
  const _BackButton();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        // Was a raw `Colors.white` scrim, which also stayed white in dark mode.
        color: BatshColors.surfaceContainerLowest.withValues(alpha: 0.9),
        shape: const CircleBorder(),
        child: IconButton(
          // `Icons.arrow_back` is declared with matchTextDirection, so it
          // mirrors to point right in Arabic and left in English. The previous
          // hardcoded `arrow_forward` was correct only in RTL.
          icon: const Icon(Icons.arrow_back, color: BatshColors.onSurface),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
    );
  }
}

class _CoverHero extends StatelessWidget {
  const _CoverHero({this.coverUrl});
  final String? coverUrl;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (coverUrl != null)
          CachedNetworkImage(
            imageUrl: sizedImageUrl(coverUrl!, width: 900),
            fit: BoxFit.cover,
            memCacheWidth: 900,
            placeholder: (_, _) =>
                const ColoredBox(color: BatshColors.surfaceContainer),
            errorWidget: (_, _, _) => const _CoverFallback(),
          )
        else
          const _CoverFallback(),
        // Neutral photographic scrim. The previous ramp reached the page
        // background at 92% with 0.86 alpha, which erased the bottom third of
        // the photo — a cover you cannot see reads as a rendering accident.
        // This keeps the image legible under the avatar and stops short of
        // painting over it.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0x00000000),
                const Color(0x14000000),
                BatshColors.background.withValues(alpha: 0.55),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}

class _CoverFallback extends StatelessWidget {
  const _CoverFallback();
  @override
  Widget build(BuildContext context) {
    return const BatshGradientFallback();
  }
}

class _AvatarRing extends StatelessWidget {
  const _AvatarRing({this.logoUrl});
  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: BatshColors.background,
        shape: BoxShape.circle,
        boxShadow: BatshShadows.elevated,
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: BatshColors.surfaceContainer,
          border: Border.all(
            color: BatshColors.primary.withValues(alpha: 0.55),
            width: 2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: logoUrl != null
            ? CachedNetworkImage(
                imageUrl: sizedImageUrl(logoUrl!, width: 200),
                fit: BoxFit.cover,
                memCacheWidth: 200,
                placeholder: (_, _) =>
                    const ColoredBox(color: BatshColors.surfaceContainer),
              )
            : const Icon(
                Icons.engineering_outlined,
                size: BatshIconSize.xxl,
                color: BatshColors.primary,
              ),
      ),
    );
  }
}

class _NameHeadline extends StatelessWidget {
  const _NameHeadline({required this.contractor});
  final ContractorListing contractor;

  @override
  Widget build(BuildContext context) {
    final name = contractor.businessName.isNotEmpty
        ? contractor.businessName
        : contractor.fullName;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BatshSpacing.marginMobile,
      ),
      child: Column(
        children: [
          Text(
            name,
            textAlign: TextAlign.center,
            style: BatshTypography.headlineLgMobile,
          ),
          const SizedBox(height: BatshSpacing.sm),
          // Kind first, then verification, then the earned level: what they
          // are, whether we checked, and what the work record says. Wrap so
          // the set reflows instead of overflowing at large text scales.
          Wrap(
            alignment: WrapAlignment.center,
            spacing: BatshSpacing.xs,
            runSpacing: BatshSpacing.xs,
            children: [
              BatshBadge(
                label: contractor.providerKind.label,
                icon: contractor.providerKind.icon,
                emphasis: BatshBadgeEmphasis.outline,
              ),
              if (contractor.verified)
                BatshBadge(
                  label: S.verified,
                  icon: Icons.verified_rounded,
                  tone: BatshBadgeTone.brand,
                ),
              // Tappable here because this is where a homeowner is actually
              // deciding, and an unexplained rank is just another glyph.
              TierBadge(tier: contractor.tier, explainOnTap: true),
            ],
          ),
          if (contractor.headline != null &&
              contractor.headline!.isNotEmpty) ...[
            const SizedBox(height: BatshSpacing.xs),
            Text(
              contractor.headline!,
              textAlign: TextAlign.center,
              style: BatshTypography.bodyMd.copyWith(
                color: BatshColors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// What the professional calls themselves — مقاول, مهندس, مكتب هندسي, and so
/// on.
///
/// Styled as a neutral outline rather than a filled accent so it reads as a
/// statement of fact, not an award. Verification is the award, and the two must
/// not look alike.

/// Verification, labelled.
///
/// This was a bare 22px checkmark beside the name. Verification is the whole
/// point of the request flow behind migration 0015, and an unlabelled glyph is
/// the one form most users will not decode. Icon plus word, like `RoleBadge`,
/// so it survives a greyscale read.

class _RatingPill extends StatelessWidget {
  const _RatingPill({required this.rating, this.reviewCount, this.onTap});

  /// Null when unreviewed — the pill then shows the neutral "new" state.
  final double? rating;
  final int? reviewCount;

  /// Opens the review list.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Cold-start: a brand-new contractor has no reviews. Showing empty stars +
    // "0.0" reads as *bad*; a neutral "جديد" badge reads as *new*. Same data,
    // opposite trust signal (Airbnb/Upwork pattern). Icon + text, not colour
    // alone, so it survives accessibility/colour-blind checks.
    // Local copy: a nullable field cannot be type-promoted by the null check.
    final avg = rating;
    if (avg == null || reviewCount == null || reviewCount == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: BatshSpacing.gutter,
          vertical: BatshSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: BatshColors.secondaryContainer,
          borderRadius: BatshRadius.brFull,
          border: Border.all(color: BatshColors.secondary, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_awesome,
              size: BatshIconSize.sm,
              color: BatshColors.onSecondaryContainer,
            ),
            const SizedBox(width: BatshSpacing.xs),
            Text(
              S.newProfessional,
              style: BatshTypography.labelMd.copyWith(
                color: BatshColors.onSecondaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    // One star, the number, then the tappable count. The old pill encoded the
    // same value three times — five 14px stars *and* "4.5" *and* "(12 تقييم)" —
    // and the star row also rendered 4.9 as a half star, because a half was
    // drawn whenever the fractional part cleared 0.4.
    return Material(
      color: BatshColors.tertiaryFixed,
      borderRadius: BatshRadius.brFull,
      child: InkWell(
        borderRadius: BatshRadius.brFull,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: BatshSpacing.gutter,
            vertical: BatshSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BatshRadius.brFull,
            border: Border.all(color: BatshColors.tertiary, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.star_rounded,
                size: BatshIconSize.md,
                color: BatshColors.tertiary,
              ),
              const SizedBox(width: BatshSpacing.xs),
              Text(
                avg.toStringAsFixed(1),
                style: BatshTypography.labelMd.copyWith(
                  color: BatshColors.onTertiaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: BatshSpacing.xs),
              Text(
                '· $reviewCount ${S.reviewsCount}',
                style: BatshTypography.labelSm.copyWith(
                  color: BatshColors.onTertiaryContainer,
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 2),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: BatshIconSize.xs,
                  color: BatshColors.onTertiaryContainer,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
