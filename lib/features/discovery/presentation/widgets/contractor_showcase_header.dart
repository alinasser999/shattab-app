part of 'contractor_showcase.dart';

class _BackButton extends StatelessWidget {
  const _BackButton();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        // Was a raw `Colors.white` scrim, which also stayed white in dark mode.
        color: context.colorScheme.surfaceContainerLowest.withValues(
          alpha: 0.9,
        ),
        shape: const CircleBorder(),
        child: IconButton(
          // `Icons.arrow_back` is declared with matchTextDirection, so it
          // mirrors to point right in Arabic and left in English. The previous
          // hardcoded `arrow_forward` was correct only in RTL.
          icon: Icon(Icons.arrow_back, color: context.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
    );
  }
}

class _CoverHero extends StatelessWidget {
  const _CoverHero({this.coverUrl, this.name});
  final String? coverUrl;

  /// Feeds the no-photo plate, so a contractor without a cover gets their own
  /// initial here and the same one on their card in the feed.
  final String? name;

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
                ColoredBox(color: context.colorScheme.surfaceContainer),
            errorWidget: (_, _, _) => BatshInitialPlate(name: name),
          )
        else
          BatshInitialPlate(name: name),
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
                context.colorScheme.background.withValues(alpha: 0.55),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
      ],
    );
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
        color: context.colorScheme.background,
        shape: BoxShape.circle,
        boxShadow: BatshShadows.elevated,
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: context.colorScheme.surfaceContainer,
          border: Border.all(
            color: context.colorScheme.primary.withValues(alpha: 0.55),
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
                    ColoredBox(color: context.colorScheme.surfaceContainer),
              )
            : Icon(
                Icons.engineering_outlined,
                size: BatshIconSize.xxl,
                color: context.colorScheme.primary,
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
                label: contractor.providerKind.label(context),
                icon: contractor.providerKind.icon,
                emphasis: BatshBadgeEmphasis.outline,
              ),
              if (contractor.verified)
                BatshBadge(
                  label: context.l10n.verified,
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
                color: context.colorScheme.onSurfaceVariant,
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
          color: context.colorScheme.secondaryContainer,
          borderRadius: BatshRadius.brFull,
          border: Border.all(color: context.colorScheme.secondary, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome,
              size: BatshIconSize.sm,
              color: context.colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: BatshSpacing.xs),
            Text(
              context.l10n.noRatingsYet,
              style: BatshTypography.labelMd.copyWith(
                color: context.colorScheme.onSecondaryContainer,
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
      color: context.colorScheme.tertiaryFixed,
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
            border: Border.all(color: context.colorScheme.tertiary, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.star_rounded,
                size: BatshIconSize.md,
                color: context.colorScheme.tertiary,
              ),
              const SizedBox(width: BatshSpacing.xs),
              Text(
                avg.toStringAsFixed(1),
                style: BatshTypography.labelMd.copyWith(
                  color: context.colorScheme.onTertiaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: BatshSpacing.xs),
              Text(
                '· $reviewCount ${context.l10n.reviewsCount}',
                style: BatshTypography.labelSm.copyWith(
                  color: context.colorScheme.onTertiaryContainer,
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 2),
                Icon(
                  Icons.arrow_forward_ios,
                  size: BatshIconSize.xs,
                  color: context.colorScheme.onTertiaryContainer,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
