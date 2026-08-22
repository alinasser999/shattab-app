import 'package:flutter/material.dart';

import '../../../../core/l10n/catalog_labels.dart';
import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/theme/batsh_colors.dart';
import '../../../../core/theme/batsh_icon_size.dart';
import '../../../../core/theme/batsh_radius.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/utils/image_url.dart';
import '../../../../core/widgets/batsh_shimmer.dart';
import '../../../../core/widgets/batsh_stars.dart';
import '../../domain/contractor_listing.dart';
import 'mockup_assets.dart';

/// The featured professional, drawn into the Shattab card template.
///
/// The frame — contour lines, the hexagonal crest, the pyramid illustration,
/// the geometric fill on the button — is a single supplied artwork, rendered
/// untouched. Nothing here redraws any part of it. This widget only fills the
/// empty regions the artwork leaves: the photograph, the crest interior, and
/// the bands of type between them.
///
/// Every featured professional gets this treatment; it is the one card the
/// discover tab puts under "محترف مميز".
class FeaturedProfessionalCard extends StatelessWidget {
  const FeaturedProfessionalCard({
    super.key,
    required this.listing,
    required this.onTap,
  });

  final ContractorListing listing;
  final VoidCallback onTap;

  static const String _template = 'assets/images/featured_card_template.png';

  /// The artwork's own proportions. The card is locked to them so the regions
  /// below stay aligned to the frame at every width.
  static const double aspectRatio = 1054 / 1492;

  // ── Regions ────────────────────────────────────────────────────────────────
  //
  // Fractions of the artwork, measured off it. Everything positional lives
  // here: if the frame is ever redrawn, these are the only numbers to revisit.

  /// The grey plate the photograph replaces.
  static const Rect _photo = Rect.fromLTRB(0.021, 0.013, 0.982, 0.410);

  /// The plain hexagon inside the ornate ring — the logo's window. The ring
  /// itself belongs to the artwork and is never drawn over.
  /// Runs a hair wide of the measured window so the artwork's grey placeholder
  /// is fully covered; the surplus tucks under the ring rather than showing.
  static const Rect _crest = Rect.fromLTRB(0.755, 0.327, 0.926, 0.448);

  /// The open band between the crest and the trust panel: name, trade and
  /// place, then the three statistics.
  static const Rect _content = Rect.fromLTRB(0.055, 0.455, 0.945, 0.700);

  /// Inside the trust panel, clear of the pyramids at its left.
  static const Rect _trust = Rect.fromLTRB(0.310, 0.730, 0.930, 0.835);

  /// The terracotta pill. Only its label and arrow are ours.
  static const Rect _cta = Rect.fromLTRB(0.074, 0.866, 0.944, 0.945);

  @override
  Widget build(BuildContext context) {
    final name = listing.businessName.isNotEmpty
        ? listing.businessName
        : listing.fullName;
    final isPlaceholder = !isDisplayableImageUrl(listing.coverPhotoUrl);

    return Semantics(
      button: true,
      label: name,
      child: GestureDetector(
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;

              Widget at(Rect r, Widget child) => Positioned(
                left: r.left * w,
                top: r.top * h,
                width: r.width * w,
                height: r.height * h,
                child: child,
              );

              return Stack(
                children: [
                  // The artwork, edge to edge and unmodified.
                  Positioned.fill(
                    child: Image.asset(
                      _template,
                      fit: BoxFit.fill,
                      // Decorative: the card is already labelled by its name.
                      excludeFromSemantics: true,
                    ),
                  ),
                  at(
                    _photo,
                    _TemplatePhoto(
                      listing: listing,
                      isPlaceholder: isPlaceholder,
                    ),
                  ),
                  at(_crest, _CrestLogo(logoUrl: listing.logoUrl, name: name)),
                  at(_content, _Content(listing: listing, name: name)),
                  at(_trust, _TrustText(listing: listing)),
                  at(_cta, const _CtaLabel()),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─── Photograph ──────────────────────────────────────────────────────────────

/// The cover, cut to the shape of the plate the artwork leaves for it.
class _TemplatePhoto extends StatelessWidget {
  const _TemplatePhoto({required this.listing, required this.isPlaceholder});

  final ContractorListing listing;
  final bool isPlaceholder;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: const FeaturedCardImageClipper(),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Unchanged behaviour: an account with no cover of its own borrows a
          // curated interior, and says so on the photograph.
          Hero(
            tag: 'professional-gallery-${listing.id}',
            child: MockupImage(
              url: listing.coverPhotoUrl ?? mockupPortfolioImages.first,
              memCacheWidth: 900,
            ),
          ),
          // Only as deep as the pill needs.
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                  colors: [Color(0x59000000), Color(0x00000000)],
                ),
              ),
            ),
          ),
          PositionedDirectional(
            top: BatshSpacing.xs,
            start: BatshSpacing.xs,
            end: BatshSpacing.xs,
            child: Wrap(
              spacing: BatshSpacing.xs,
              runSpacing: BatshSpacing.xs,
              children: [
                if (listing.tier.isPublic) _LevelBadge(tier: listing.tier),
                if (isPlaceholder) const MockupSampleBadge(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The silhouette of the artwork's photo plate: rounded at the top, flat along
/// the bottom, sweeping up on the right to clear the crest.
///
/// Traced from the frame rather than invented. A mismatch shows as a grey
/// fringe, so the path runs a hair generous at the sweep — an overlap of a
/// pixel disappears into the artwork's own soft edge, where a gap of one does
/// not.
class FeaturedCardImageClipper extends CustomClipper<Path> {
  const FeaturedCardImageClipper();

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    // Corner radius of the plate, as a fraction of its own width.
    final r = w * 0.042;
    return Path()
      ..moveTo(0, r)
      ..arcToPoint(Offset(r, 0), radius: Radius.circular(r))
      ..lineTo(w - r, 0)
      ..arcToPoint(Offset(w, r), radius: Radius.circular(r))
      // Down the right edge to where the sweep begins.
      ..lineTo(w, h * 0.36)
      // The sweep: out to the right, then flattening onto the bottom edge.
      ..cubicTo(w * 0.95, h * 0.62, w * 0.79, h * 1.005, w * 0.60, h * 1.005)
      ..lineTo(r, h)
      ..arcToPoint(Offset(0, h - r), radius: Radius.circular(r))
      ..close();
  }

  @override
  bool shouldReclip(FeaturedCardImageClipper oldClipper) => false;
}

// ─── Crest ───────────────────────────────────────────────────────────────────

/// The contractor's mark, dropped into the artwork's hexagonal window.
///
/// The ornate ring around it is the frame's, not ours. When there is no logo
/// the contractor's own initial stands in — never a substitute mark, because a
/// fake crest on a hiring card misrepresents who you are dealing with.
class _CrestLogo extends StatelessWidget {
  const _CrestLogo({required this.logoUrl, required this.name});

  final String? logoUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    final hasLogo = logoUrl != null && logoUrl!.isNotEmpty;
    return ExcludeSemantics(
      child: ClipPath(
        clipper: const _HexClipper(),
        child: ColoredBox(
          color: hasLogo ? BatshColors.primary : BatshColors.primaryContainer,
          child: hasLogo
              ? MockupImage(
                  url: sizedImageUrl(logoUrl!, width: 240),
                  memCacheWidth: 240,
                )
              : Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.all(BatshSpacing.xs),
                      child: Text(
                        name.trim().isEmpty ? '?' : name.trim().substring(0, 1),
                        style: BatshTypography.headlineSm.copyWith(
                          color: BatshColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

/// The window's shape: flat top and bottom, a point at each side.
class _HexClipper extends CustomClipper<Path> {
  const _HexClipper();

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(0, h / 2)
      ..lineTo(w * 0.25, 0)
      ..lineTo(w * 0.75, 0)
      ..lineTo(w, h / 2)
      ..lineTo(w * 0.75, h)
      ..lineTo(w * 0.25, h)
      ..close();
  }

  @override
  bool shouldReclip(_HexClipper oldClipper) => false;
}

// ─── Level badge ─────────────────────────────────────────────────────────────

/// The earned tier, worn over the photograph. Olive and white are fixed: the
/// pill sits on a contractor's own upload, so its contrast cannot depend on
/// which surface the page is painting.
class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.tier});

  final ContractorTier tier;

  @override
  Widget build(BuildContext context) {
    final label = tier.label(context);
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: BatshSpacing.sm,
          vertical: BatshSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: BatshColors.secondary,
          borderRadius: BatshRadius.brFull,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ExcludeSemantics(
              child: Icon(
                Icons.emoji_events_rounded,
                size: BatshIconSize.inline,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: BatshSpacing.xxs),
            ExcludeSemantics(
              child: Text(
                label,
                style: BatshTypography.labelMd.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: BatshSpacing.xxs),
            const ExcludeSemantics(
              child: Icon(
                Icons.verified_user_rounded,
                size: BatshIconSize.inline,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Identity and statistics ─────────────────────────────────────────────────

/// Name, trade and place, then the three numbers — sharing one open band.
///
/// Ink is taken from the palette directly rather than from the scheme: the
/// surface behind this text is a fixed cream artwork, so following a dark
/// theme here would put white type on a pale ground.
class _Content extends StatelessWidget {
  const _Content({required this.listing, required this.name});

  final ContractorListing listing;
  final String name;

  @override
  Widget build(BuildContext context) {
    final trade = listing.specialties.isNotEmpty
        ? localizedSpecialtyLabel(context, listing.specialties.first)
        : listing.providerKind.label(context);
    final areas = listing.serviceAreas.take(2).toList();

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Scales down instead of clipping: the band is a fixed slot in the
        // artwork, and a long company name has to fit inside it.
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              children: [
                Text(
                  name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: BatshTypography.headlineMd.copyWith(
                    color: BatshColors.onSurface,
                  ),
                ),
                const SizedBox(height: BatshSpacing.xs),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      trade,
                      style: BatshTypography.bodyMd.copyWith(
                        color: BatshColors.onSurfaceVariant,
                      ),
                    ),
                    for (final area in areas) ...[
                      const SizedBox(width: BatshSpacing.sm),
                      const Icon(
                        Icons.place_outlined,
                        size: BatshIconSize.inline,
                        color: BatshColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: BatshSpacing.xxxs),
                      Text(
                        area,
                        style: BatshTypography.bodyMd.copyWith(
                          color: BatshColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        Flexible(child: _StatsRow(listing: listing)),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.listing});

  final ContractorListing listing;

  @override
  Widget build(BuildContext context) {
    final stats = <Widget>[
      if (listing.hasReviews)
        _Stat(
          value: listing.rating!.toStringAsFixed(1),
          label: '${listing.reviewCount} ${context.l10n.reviewsCount}',
          below: BatshStars(
            rating: listing.reviewAvg,
            size: BatshIconSize.inline,
            color: BatshColors.starGold,
          ),
        ),
      if (listing.projectsCompleted > 0)
        _Stat(
          value: '${listing.projectsCompleted}',
          label: context.l10n.completedProjectsShort,
          icon: Icons.apartment_rounded,
        ),
      if (listing.yearsExperience != null && listing.yearsExperience! > 0)
        _Stat(
          value: '${listing.yearsExperience}',
          label: context.l10n.yearsExperience,
        ),
    ];

    if (stats.isEmpty) {
      return Align(
        alignment: AlignmentDirectional.center,
        child: Text(
          context.l10n.newBadge,
          style: BatshTypography.labelMd.copyWith(
            color: BatshColors.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    const divider = VerticalDivider(
      width: 1,
      thickness: 1,
      indent: BatshSpacing.xxs,
      endIndent: BatshSpacing.xxs,
      color: BatshColors.outlineVariant,
    );
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var index = 0; index < stats.length; index++) ...[
            if (index > 0) divider,
            Expanded(child: stats[index]),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, this.label, this.below, this.icon});

  final String value;
  final String? label;
  final Widget? below;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final stack = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: BatshTypography.titleLg.copyWith(
            fontWeight: FontWeight.w700,
            color: BatshColors.onSurface,
          ),
        ),
        const SizedBox(height: BatshSpacing.xxxs),
        if (below != null)
          below!
        else if (label != null)
          Text(
            label!,
            maxLines: 2,
            textAlign: TextAlign.center,
            style: BatshTypography.bodySm.copyWith(
              color: BatshColors.onSurfaceVariant,
            ),
          ),
      ],
    );

    final content = icon == null
        ? stack
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: stack),
              const SizedBox(width: BatshSpacing.xxs),
              ExcludeSemantics(
                child: Icon(
                  icon,
                  size: BatshIconSize.action,
                  color: BatshColors.primary,
                ),
              ),
            ],
          );

    // Every cell shrinks rather than clips: the band is a fixed slot, and the
    // three cells have to stay on one line whatever the numbers say.
    return FittedBox(fit: BoxFit.scaleDown, child: content);
  }
}

// ─── Trust panel ─────────────────────────────────────────────────────────────

/// What the contractor says about themselves and — only when it is true — that
/// Shattab has checked them. The panel and its pyramids come from the artwork.
class _TrustText extends StatelessWidget {
  const _TrustText({required this.listing});

  final ContractorListing listing;

  @override
  Widget build(BuildContext context) {
    final description = (listing.headline?.trim().isNotEmpty ?? false)
        ? listing.headline!.trim()
        : listing.bio?.trim();
    final hasDescription = description != null && description.isNotEmpty;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasDescription)
          Flexible(
            child: Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: BatshTypography.bodySm.copyWith(
                color: BatshColors.onSurfaceVariant,
              ),
            ),
          ),
        if (listing.verified) ...[
          if (hasDescription) const SizedBox(height: BatshSpacing.xxs),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ExcludeSemantics(
                child: Icon(
                  Icons.verified_user_outlined,
                  size: BatshIconSize.inline,
                  color: BatshColors.secondary,
                ),
              ),
              const SizedBox(width: BatshSpacing.xxs),
              Flexible(
                child: Text(
                  context.l10n.verifiedByShattab,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BatshTypography.labelMd.copyWith(
                    color: BatshColors.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ─── Call to action ──────────────────────────────────────────────────────────

/// The label over the artwork's terracotta pill. The pill, and the geometry
/// filling its far end, are drawn by the frame.
class _CtaLabel extends StatelessWidget {
  const _CtaLabel();

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return IgnorePointer(
      child: Stack(
        alignment: Alignment.center,
        children: [
          ExcludeSemantics(
            child: Text(
              context.l10n.viewContractorProfile,
              style: BatshTypography.titleMd.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          PositionedDirectional(
            end: BatshSpacing.ml,
            child: ExcludeSemantics(
              // "Onward" points left in Arabic, right in English.
              child: Icon(
                rtl ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded,
                color: Colors.white,
                size: BatshIconSize.action,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Loading ─────────────────────────────────────────────────────────────────

/// The card's footprint in grey, so the swap to content shifts nothing.
class FeaturedProfessionalCardSkeleton extends StatelessWidget {
  const FeaturedProfessionalCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: FeaturedProfessionalCard.aspectRatio,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          borderRadius: BatshRadius.brXxl,
          border: Border.all(color: context.colorScheme.outlineVariant),
        ),
        child: const Padding(
          padding: EdgeInsets.all(BatshSpacing.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 40,
                child: BatshShimmerBox(borderRadius: BatshRadius.brImage),
              ),
              SizedBox(height: BatshSpacing.lg),
              Expanded(
                flex: 26,
                child: BatshShimmerBox(borderRadius: BatshRadius.brXs),
              ),
              SizedBox(height: BatshSpacing.lg),
              Expanded(
                flex: 14,
                child: BatshShimmerBox(borderRadius: BatshRadius.brXl),
              ),
              SizedBox(height: BatshSpacing.sm),
              Expanded(
                flex: 10,
                child: BatshShimmerBox(borderRadius: BatshRadius.brXxl),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
