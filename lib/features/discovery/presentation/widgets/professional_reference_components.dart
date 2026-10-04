import '../../../../core/theme/professional_reference_theme.dart';
import '../../../../core/widgets/professional_reference_navigation.dart';
import '../../../../core/l10n/l10n_extension.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/utils/image_url.dart';
import '../../../../core/l10n/catalog_labels.dart';
import '../../domain/contractor_listing.dart';
import '../../domain/professional_reference_fixture.dart';

const referenceNavy = ProfessionalReferenceTheme.navy;
const referenceOrange = ProfessionalReferenceTheme.orange;
const referenceMuted = ProfessionalReferenceTheme.legacyMuted;
const referenceCream = ProfessionalReferenceTheme.cream;
const referenceBackground = ProfessionalReferenceTheme.background;
TextStyle referenceText(
  double size, {
  Color color = referenceNavy,
  FontWeight weight = FontWeight.w500,
  double height = 1.3,
}) => ProfessionalReferenceTheme.text(
  size,
  color: color,
  weight: weight,
  height: height,
);

bool referenceMediaAllowed(String? url) =>
    isDisplayableImageUrl(url) ||
    (professionalReferenceEnabled &&
        url != null &&
        const {
          'assets/images/professional_reference_living.jpg',
          'assets/images/professional_reference_living_card.png',
          'assets/images/professional_reference_living_profile.png',
          'assets/images/professional_reference_bedroom.jpg',
          'assets/images/professional_reference_bathroom.jpg',
          'assets/images/professional_reference_bathroom_card.png',
          'assets/images/professional_reference_avatar.png',
          'assets/images/professional_reference_review_ahmed.png',
          'assets/images/professional_reference_review_sara.png',
        }.contains(url));

class ReferenceMedia extends StatelessWidget {
  const ReferenceMedia({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
  });
  final String? url;
  final BoxFit fit;
  final Alignment alignment;
  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      color: const Color(0xfff0eee9),
      child: const Center(
        child: Icon(Icons.photo_outlined, color: referenceMuted),
      ),
    );
    if (!referenceMediaAllowed(url)) return fallback;
    if (url!.startsWith('assets/')) {
      final underlay = switch (url) {
        'assets/images/professional_reference_living_card.png' ||
        'assets/images/professional_reference_living_profile.png' =>
          ProfessionalReferenceFixture.livingRoomImage,
        'assets/images/professional_reference_bathroom_card.png' =>
          ProfessionalReferenceFixture.bathroomImage,
        _ => null,
      };
      if (underlay != null) {
        return Stack(
          fit: StackFit.expand,
          children: [
            ReferenceMedia(url: underlay, fit: fit, alignment: alignment),
            Image.asset(
              url!,
              fit: fit,
              alignment: alignment,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ],
        );
      }
      return Image.asset(
        url!,
        fit: fit,
        alignment: alignment,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    return CachedNetworkImage(
      imageUrl: url!,
      fit: fit,
      alignment: alignment,
      errorWidget: (_, _, _) => fallback,
      placeholder: (_, _) => fallback,
    );
  }
}

class ReferenceGallery extends StatefulWidget {
  const ReferenceGallery({
    super.key,
    required this.photos,
    this.ratio = 1.7,
    this.premium = false,
    this.premiumLabel = true,
    this.saved = false,
    this.onSave,
    this.onOpen,
    this.compact = false,
  });
  final List<String> photos;
  final double ratio;
  final bool premium, saved, compact, premiumLabel;
  final VoidCallback? onSave, onOpen;
  @override
  State<ReferenceGallery> createState() => _ReferenceGalleryState();
}

class _ReferenceGalleryState extends State<ReferenceGallery> {
  int _page = 0;
  @override
  void didUpdateWidget(covariant ReferenceGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_page >= widget.photos.length) _page = 0;
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(widget.compact ? 9 : 12),
    child: AspectRatio(
      aspectRatio: widget.ratio,
      child: Stack(
        children: [
          Positioned.fill(
            child: PageView.builder(
              itemCount: widget.photos.isEmpty ? 1 : widget.photos.length,
              onPageChanged: (value) => setState(() => _page = value),
              itemBuilder: (_, index) => GestureDetector(
                onTap: widget.onOpen,
                child: ReferenceMedia(
                  url: widget.photos.isEmpty ? null : widget.photos[index],
                ),
              ),
            ),
          ),
          if (widget.premium)
            Positioned(
              left: widget.compact ? 8 : 11,
              top: widget.compact ? 9 : 10,
              child: widget.premiumLabel
                  ? ReferencePremiumBadge(compact: widget.compact)
                  : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xffffe8af),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        context.l10n.referenceAdDisclosure,
                        style: referenceText(
                          widget.compact ? 10 : 11,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
            ),
          if (widget.onSave != null)
            Positioned(
              right: -.5,
              top: 1.5,
              child: ReferenceIconButton(
                icon: widget.saved ? Icons.favorite : Icons.favorite_border,
                color: Colors.white,
                size: 19,
                label: widget.saved
                    ? context.l10n.referenceUnsaveProfessional
                    : context.l10n.referenceSaveProfessional,
                onTap: widget.onSave!,
              ),
            ),
          if (widget.photos.length > 1)
            Positioned(
              bottom: widget.compact ? 5 : 7,
              left: 0,
              right: 0,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.photos.length,
                    (i) => Container(
                      width: widget.compact ? 6 : 6.5,
                      height: widget.compact ? 6 : 6.5,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == _page
                            ? Colors.white
                            : const Color(0xffc9cacc),
                      ),
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

class ReferencePremiumBadge extends StatelessWidget {
  const ReferencePremiumBadge({
    super.key,
    this.compact = false,
    this.readable = false,
  });
  final bool compact, readable;
  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(12) / 12;
    if (readable) {
      return Container(
        constraints: BoxConstraints(minHeight: 32 * textScale),
        padding: EdgeInsets.symmetric(
          horizontal: 8 * textScale,
          vertical: 6 * textScale,
        ),
        decoration: BoxDecoration(
          color: const Color(0xffffedcb),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 5 * textScale,
            runSpacing: 2 * textScale,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star_rounded,
                    color: const Color(0xffffb728),
                    size: 15 * textScale,
                  ),
                  SizedBox(width: 3 * textScale),
                  Text(
                    'Premium',
                    style: referenceText(
                      14,
                      color: const Color(0xff8f3824),
                      weight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Text(
                context.l10n.referencePremiumDisclosure,
                style: referenceText(14, color: const Color(0xff8f3824)),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: (compact ? 135 : 118) * textScale,
      height: (compact ? 22 : 23) * textScale,
      padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 4),
      decoration: BoxDecoration(
        color: const Color(0xffffedcb),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.star_rounded,
              color: const Color(0xffffb728),
              size: compact ? 14 : 15,
            ),
            const SizedBox(width: 3),
            Text(
              'Premium',
              style: referenceText(
                12,
                color: const Color(0xff8f3824),
                weight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              context.l10n.referencePremiumDisclosure,
              style: referenceText(
                compact ? 8 : 8.5,
                color: const Color(0xff8f3824),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReferenceIconButton extends StatelessWidget {
  const ReferenceIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = referenceNavy,
    this.size = 21,
    this.visualOffset = Offset.zero,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final double size;
  final Offset visualOffset;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 23,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Transform.translate(
            offset: visualOffset,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Icon(icon, size: size, color: color),
            ),
          ),
        ),
      ),
    ),
  );
}

class ReferenceAvatar extends StatelessWidget {
  const ReferenceAvatar({super.key, required this.listing, required this.size});
  final ContractorListing listing;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    padding: const EdgeInsets.all(1.5),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: listing.isSponsored
            ? const Color(0xffe1c9a8)
            : const Color(0xffedece9),
      ),
    ),
    child: ClipOval(child: ReferenceMedia(url: listing.logoUrl)),
  );
}

String referenceName(ContractorListing listing) =>
    listing.businessName.trim().isNotEmpty
    ? listing.businessName.trim()
    : listing.fullName.trim();
String referenceSpecialty(BuildContext context, ContractorListing listing) =>
    listing.specialties.isEmpty
    ? listing.providerKind.label(context)
    : localizedSpecialtyDisplayLabel(context, listing.specialties.first);

class ReferencePremiumSurface extends StatelessWidget {
  const ReferencePremiumSurface({
    super.key,
    required this.child,
    required this.premium,
    this.profile = false,
  });
  final Widget child;
  final bool premium, profile;
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      if (premium) Positioned.fill(child: Container(color: referenceCream)),
      if (premium && profile)
        Positioned.fill(
          child: IgnorePointer(
            child: Image.asset(
              'assets/images/professional_reference_pattern_identity.png',
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        ),
      if (premium && !profile) ...[
        Positioned(
          left: 0,
          bottom: 0,
          width: 21.5,
          height: 74,
          child: IgnorePointer(
            child: Image.asset(
              'assets/images/professional_reference_pattern_card_left.png',
              fit: BoxFit.contain,
              alignment: Alignment.bottomLeft,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          width: 42.5,
          height: 55,
          child: IgnorePointer(
            child: Image.asset(
              'assets/images/professional_reference_pattern_card_right.png',
              fit: BoxFit.contain,
              alignment: Alignment.bottomRight,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        ),
      ],
      child,
    ],
  );
}

class ReferenceProfessionalCard extends StatelessWidget {
  const ReferenceProfessionalCard({
    super.key,
    required this.listing,
    required this.saved,
    required this.photos,
    required this.onOpen,
    required this.onSave,
  });
  final ContractorListing listing;
  final bool saved;
  final List<String> photos;
  final VoidCallback onOpen, onSave;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: ReferenceGallery(
          photos: photos,
          premium: listing.isSponsored,
          premiumLabel: listing.isPro,
          saved: saved,
          onSave: onSave,
          onOpen: onOpen,
        ),
      ),
      ReferencePremiumSurface(
        premium: listing.isSponsored,
        child: InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 13, 11),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ReferenceAvatar(listing: listing, size: 36),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            referenceName(listing),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: referenceText(13, weight: FontWeight.w800),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${referenceSpecialty(context, listing)}  ·  ${listing.serviceAreas.firstOrNull ?? ''}',
                            style: referenceText(10, color: referenceMuted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: Color(0xffffb72a),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            listing.rating?.toStringAsFixed(1) ?? '—',
                            style: referenceText(13.5, weight: FontWeight.w700),
                          ),
                          Text(
                            ' (${listing.reviewCount})',
                            style: referenceText(12.5, color: referenceMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _CardFact(
                        icon: Icons.assignment_outlined,
                        label: context.l10n.referenceYearsExperienceCount(
                          '${listing.yearsExperience ?? '—'}',
                        ),
                      ),
                    ),
                    const _FactDivider(),
                    Expanded(
                      child: _CardFact(
                        icon: Icons.work_outline,
                        label: context.l10n.referenceCompletedProjectsCount(
                          listing.projectsCompleted,
                        ),
                      ),
                    ),
                    if (listing.verified) ...[
                      const _FactDivider(),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                context.l10n.referenceVerified,
                                style: referenceText(
                                  10,
                                  color: const Color(0xff477f20),
                                ),
                              ),
                            ),
                            const SizedBox(width: 3),
                            const Icon(
                              Icons.verified_user,
                              size: 13,
                              color: Color(0xff477f20),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        professionalReferenceEnabled &&
                                ProfessionalReferenceFixture.isFixtureId(
                                  listing.id,
                                )
                            ? 'استشارات  ·  تنفيذ وتشطيب  ·  تصميم 3D'
                            : listing.specialties
                                  .map(
                                    (s) => localizedSpecialtyDisplayLabel(
                                      context,
                                      s,
                                    ),
                                  )
                                  .join('  ·  '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: referenceText(10, color: referenceMuted),
                      ),
                    ),
                    Text(
                      context.l10n.referenceViewProfile,
                      style: referenceText(12, color: referenceOrange),
                    ),
                    const SizedBox(width: 3),
                    const Directionality(
                      textDirection: TextDirection.ltr,
                      child: Icon(
                        Icons.arrow_back,
                        color: referenceOrange,
                        size: 17,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

class _CardFact extends StatelessWidget {
  const _CardFact({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Flexible(
        child: Text(label, style: referenceText(9.5, color: referenceMuted)),
      ),
      const SizedBox(width: 4),
      Icon(icon, size: 13, color: referenceMuted),
    ],
  );
}

class _FactDivider extends StatelessWidget {
  const _FactDivider();
  @override
  Widget build(BuildContext context) =>
      Container(height: 10, width: 1, color: const Color(0xfff1cfb1));
}

class ReferenceBottomNavigation extends StatelessWidget {
  const ReferenceBottomNavigation({
    super.key,
    required this.onTap,
    this.index = 1,
  });
  final ValueChanged<int> onTap;
  final int index;
  @override
  Widget build(BuildContext context) =>
      ProfessionalReferenceNavigation(onTap: onTap, index: index);
}
