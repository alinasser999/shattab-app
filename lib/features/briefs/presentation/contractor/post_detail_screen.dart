import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/batsh_colors.dart';
import '../../../../core/theme/batsh_motion.dart';
import '../../../../core/theme/batsh_radius.dart';
import '../../../../core/theme/batsh_shadows.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/widgets/batsh_button.dart';
import '../../../../core/widgets/batsh_error.dart';
import '../../../../core/widgets/batsh_photo_viewer.dart';
import '../../../../core/widgets/batsh_scaffold.dart';
import '../../../../core/widgets/batsh_section_header.dart';
import '../../../../core/widgets/batsh_shimmer.dart';
import '../../../../core/widgets/contact_buttons.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../../core/utils/time_format.dart';
import '../../../onboarding/domain/onboarding_models.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../quotes/presentation/quote_sheet.dart';
import '../../domain/brief.dart';
import '../providers/briefs_providers.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  String? _cachedHomeownerId;
  Future<({String name, String phone})?>? _cachedFutureHomeowner;

  // Cache the Future by homeownerId so unrelated rebuilds (theme/locale/
  // motion toggles, ancestor state changes) don't refire the network call.
  Future<({String name, String phone})?> _futureHomeowner(String homeownerId) {
    if (_cachedHomeownerId != homeownerId) {
      _cachedHomeownerId = homeownerId;
      _cachedFutureHomeowner =
          ref.read(authRepositoryProvider).fetchProfileNameAndPhone(homeownerId);
    }
    return _cachedFutureHomeowner!;
  }

  static String _relativeTime(DateTime dt) => formatRelativeTime(dt);

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(briefByIdProvider(widget.postId));

    return BatshScaffold(
      title: S.postDetailTitle,
      body: async.when(
        loading: () => const _PostDetailSkeleton(),
        error: (e, _) => BatshError(
              message: ErrorMapper.map(e),
              onRetry: () => ref.invalidate(briefByIdProvider(widget.postId)),
            ),
        data: (brief) {
          if (brief == null) {
            return BatshError(message: S.postNotFound);
          }
          return _PostDetailBody(
            brief: brief,
            futureHomeowner: _futureHomeowner(brief.homeownerId),
            relativeTime: _relativeTime(brief.createdAt),
            onQuote: () => showQuoteSheet(context, briefId: brief.id),
          );
        },
      ),
    );
  }
}

class _PostDetailBody extends StatelessWidget {
  const _PostDetailBody({
    required this.brief,
    required this.futureHomeowner,
    required this.relativeTime,
    required this.onQuote,
  });

  final Brief brief;
  final Future<({String name, String phone})?> futureHomeowner;
  final String relativeTime;
  final VoidCallback onQuote;

  @override
  Widget build(BuildContext context) {
    final apt =
        OnboardingCatalog.apartmentLabels[brief.apartmentType] ??
            brief.apartmentType.name;
    final place = brief.district != null
        ? '${brief.city} · ${brief.district}'
        : brief.city;
    final reduced = MediaQuery.of(context).disableAnimations;
    final items = <Widget>[
      if (brief.photoUrls.isNotEmpty)
        _HeroImageSection(
          photoUrls: brief.photoUrls,
          location: place,
          apartmentLabel: apt,
          title: brief.workDescription,
        )
      else
        _NoHeroHeader(
          location: place,
          apartmentLabel: apt,
          time: relativeTime,
          title: brief.workDescription,
        ),
      _BriefInfoCard(brief: brief, apt: apt, time: relativeTime),
      const SizedBox(height: BatshSpacing.gutter),
      _HomeownerCard(future: futureHomeowner),
      if (brief.photoUrls.length > 1) ...[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.gutter),
          child: BatshSectionHeader(title: S.photos),
        ),
        _GallerySection(photoUrls: brief.photoUrls),
      ],
      const SizedBox(height: BatshSpacing.md),
      _ContactSection(future: futureHomeowner),
      const SizedBox(height: BatshSpacing.md),
    ];
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: reduced
                ? items
                : items.animate(interval: BatshMotion.staggerBase).fadeIn(
                      duration: BatshMotion.normal,
                      curve: Curves.easeOutQuad,
                    ).slideY(
                      begin: 0.06,
                      end: 0,
                      curve: BatshMotion.easeOut,
                    ),
          ),
        ),
        _StickyQuoteBar(onQuote: onQuote),
      ],
    );
  }
}

/// CTA docked to the bottom of the details screen, above the safe area.
class _StickyQuoteBar extends StatelessWidget {
  const _StickyQuoteBar({required this.onQuote});
  final VoidCallback onQuote;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: BatshColors.cardBackground,
        boxShadow: BatshShadows.raised,
        border: Border(
          top: BorderSide(
            color: BatshColors.outlineVariant.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            BatshSpacing.gutter,
            BatshSpacing.sm,
            BatshSpacing.gutter,
            BatshSpacing.sm,
          ),
          child: BatshButton(
            label: S.sendQuoteButton,
            icon: Icons.request_quote_outlined,
            onPressed: onQuote,
          ),
        ),
      ),
    );
  }
}

/// Photo grid: at most one row of four tiles, the last carrying a "+N" count
/// when there are more. Tapping any tile opens the full set in the viewer, so
/// nothing is unreachable — a 12-photo brief used to render four rows of grid
/// that pushed the description and contact CTA off-screen.
class _GallerySection extends StatelessWidget {
  const _GallerySection({required this.photoUrls});
  final List<String> photoUrls;

  static const _maxTiles = 4;

  @override
  Widget build(BuildContext context) {
    final tileCount =
        photoUrls.length <= _maxTiles ? photoUrls.length : _maxTiles;
    final overflow = photoUrls.length - tileCount;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.gutter),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _maxTiles,
          crossAxisSpacing: BatshSpacing.xs,
          mainAxisSpacing: BatshSpacing.xs,
        ),
        itemCount: tileCount,
        itemBuilder: (context, i) {
          final isLastTile = i == tileCount - 1;
          final showOverflow = isLastTile && overflow > 0;
          return Semantics(
            button: true,
            label: S.openPhotoViewer,
            child: GestureDetector(
              onTap: () => BatshPhotoViewer.show(
                context,
                urls: photoUrls,
                initialIndex: i,
              ),
              child: ClipRRect(
                borderRadius: BatshRadius.brMd,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: photoUrls[i],
                      fit: BoxFit.cover,
                      // Thumbnail tile — a quarter of the screen width.
                      memCacheWidth: 320,
                      placeholder: (_, _) =>
                          Container(color: BatshColors.surfaceContainer),
                      errorWidget: (_, _, _) =>
                          Container(color: BatshColors.surfaceContainer),
                    ),
                    if (showOverflow)
                      ColoredBox(
                        color: BatshColors.scrim.withValues(alpha: 0.6),
                        child: Center(
                          child: Text(
                            S.morePhotosCount(overflow),
                            style: BatshTypography.titleMd.copyWith(
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
        },
      ),
    );
  }
}

class _PostDetailSkeleton extends StatelessWidget {
  const _PostDetailSkeleton();
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        BatshShimmerBox(width: double.infinity, height: 200, borderRadius: BatshRadius.brLg),
        const SizedBox(height: BatshSpacing.gutter),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BatshShimmerBox(width: 200, height: 14, borderRadius: BatshRadius.brSm),
              const SizedBox(height: BatshSpacing.sm),
              BatshShimmerBox(width: double.infinity, height: 12, borderRadius: BatshRadius.brSm),
              const SizedBox(height: BatshSpacing.sm),
              BatshShimmerBox(width: double.infinity, height: 12, borderRadius: BatshRadius.brSm),
              const SizedBox(height: BatshSpacing.sm),
              BatshShimmerBox(width: 140, height: 12, borderRadius: BatshRadius.brSm),
            ],
          ),
        ),
        const SizedBox(height: BatshSpacing.gutter),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.gutter),
          child: BatshShimmerBox(width: double.infinity, height: 60, borderRadius: BatshRadius.brLg),
        ),
        const SizedBox(height: BatshSpacing.gutter),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.gutter),
          child: BatshShimmerBox(width: double.infinity, height: 48, borderRadius: BatshRadius.brMd),
        ),
        const SizedBox(height: BatshSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.gutter),
          child: Column(
            children: [
              BatshShimmerBox(width: double.infinity, height: 48, borderRadius: BatshRadius.brMd),
              const SizedBox(height: BatshSpacing.sm),
              BatshShimmerBox(width: double.infinity, height: 48, borderRadius: BatshRadius.brMd),
            ],
          ),
        ),
      ],
    );
  }
}

/// Swipeable hero. The counter and dots track the live page, and a tap opens
/// the same photos full-screen — the old version showed a static "1 / N" label
/// on an image that could not be swiped.
class _HeroImageSection extends StatefulWidget {
  const _HeroImageSection({
    required this.photoUrls,
    required this.location,
    required this.apartmentLabel,
    required this.title,
  });

  final List<String> photoUrls;
  final String location;
  final String apartmentLabel;
  final String title;

  @override
  State<_HeroImageSection> createState() => _HeroImageSectionState();
}

class _HeroImageSectionState extends State<_HeroImageSection> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.photoUrls;
    const radius =
        BorderRadius.vertical(bottom: Radius.circular(BatshRadius.xl));

    return SizedBox(
      height: 240,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: radius,
              child: PageView.builder(
                controller: _controller,
                itemCount: urls.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => Semantics(
                  button: true,
                  label: S.openPhotoViewer,
                  child: GestureDetector(
                    onTap: () => BatshPhotoViewer.show(
                      context,
                      urls: urls,
                      initialIndex: i,
                    ),
                    child: CachedNetworkImage(
                      imageUrl: urls[i],
                      fit: BoxFit.cover,
                      placeholder: (_, _) =>
                          Container(color: BatshColors.surfaceContainer),
                      errorWidget: (_, _, _) =>
                          Container(color: BatshColors.surfaceContainer),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Scrim sits above the pager but must not eat its swipes.
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: radius,
                ),
              ),
            ),
          ),
          Positioned(
            right: BatshSpacing.gutter,
            left: BatshSpacing.gutter,
            bottom: BatshSpacing.gutter,
            child: IgnorePointer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      _Pill(
                          label: widget.apartmentLabel,
                          bgColor: Colors.white24,
                          textColor: Colors.white),
                      const SizedBox(width: BatshSpacing.sm),
                      Flexible(
                        child: _Pill(
                            label: widget.location,
                            bgColor: Colors.white24,
                            textColor: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: BatshSpacing.sm),
                  Text(
                    widget.title,
                    style: BatshTypography.titleLg.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (urls.length > 1) ...[
                    const SizedBox(height: BatshSpacing.sm),
                    _PageDots(count: urls.length, index: _index),
                  ],
                ],
              ),
            ),
          ),
          if (urls.length > 1)
            PositionedDirectional(
              top: BatshSpacing.md,
              end: BatshSpacing.gutter,
              child: IgnorePointer(
                child: _Pill(
                  label: S.photoIndexOf(_index + 1, urls.length),
                  bgColor: Colors.black38,
                  textColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Position indicator for the hero pager. Width, not colour alone, marks the
/// active page so it survives a colour-blind / greyscale check.
class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.index});
  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: BatshMotion.fast,
            curve: BatshMotion.easeOut,
            margin: const EdgeInsetsDirectional.only(end: 5),
            width: i == index ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: i == index ? 0.95 : 0.45),
              borderRadius: BatshRadius.brFull,
            ),
          ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.bgColor,
    required this.textColor,
  });

  final String label;
  final Color bgColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BatshRadius.brFull,
      ),
      child: Text(label,
          style: BatshTypography.labelSm.copyWith(
              color: textColor, fontWeight: FontWeight.w600)),
    );
  }
}

class _NoHeroHeader extends StatelessWidget {
  const _NoHeroHeader({
    required this.location,
    required this.apartmentLabel,
    required this.time,
    required this.title,
  });

  final String location;
  final String apartmentLabel;
  final String time;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BatshSpacing.gutter,
        BatshSpacing.md,
        BatshSpacing.gutter,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Pill(
                  label: apartmentLabel,
                  bgColor: BatshColors.primaryFixed.withValues(alpha: 0.4),
                  textColor: BatshColors.primary),
              const SizedBox(width: BatshSpacing.sm),
              Icon(Icons.place_outlined,
                  size: 14, color: BatshColors.onSurfaceVariant),
              const SizedBox(width: 4),
              Expanded(
                child: Text(location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BatshTypography.labelMd
                        .copyWith(color: BatshColors.onSurfaceVariant)),
              ),
            ],
          ),
          const SizedBox(height: BatshSpacing.sm),
          Text(title,
              style: BatshTypography.titleLg.copyWith(
                fontWeight: FontWeight.w700,
              )),
          const SizedBox(height: BatshSpacing.xs),
          Row(
            children: [
              Icon(Icons.access_time,
                  size: 14, color: BatshColors.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(time,
                  style: BatshTypography.labelSm
                      .copyWith(color: BatshColors.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}

class _BriefInfoCard extends StatelessWidget {
  const _BriefInfoCard({
    required this.brief,
    required this.apt,
    required this.time,
  });

  final Brief brief;
  final String apt;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BatshSpacing.gutter,
        BatshSpacing.gutter,
        BatshSpacing.gutter,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.all(BatshSpacing.gutter),
        decoration: BoxDecoration(
          color: BatshColors.cardBackground,
          borderRadius: BatshRadius.brCard,
          boxShadow: BatshShadows.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The three facts a contractor scans for before reading prose.
            // Budget and required timeline belong here too, but `briefs` has no
            // column for either yet — see the note in the section header below.
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _SpecTile(
                    icon: Icons.handyman_outlined,
                    label: S.workTypeSpecLabel,
                    value: _workTypeValue(brief.targetSpecialties),
                  ),
                ),
                const SizedBox(width: BatshSpacing.sm),
                Expanded(
                  child: _SpecTile(
                    icon: Icons.home_outlined,
                    label: S.apartmentTypeLabel,
                    value: apt,
                  ),
                ),
                const SizedBox(width: BatshSpacing.sm),
                Expanded(
                  child: _SpecTile(
                    icon: Icons.schedule_outlined,
                    label: S.publishedSpecLabel,
                    value: time,
                  ),
                ),
              ],
            ),
            const SizedBox(height: BatshSpacing.lg),
            Text(S.postDescriptionLabel,
                style: BatshTypography.labelMd.copyWith(
                    color: BatshColors.onSurfaceVariant)),
            const SizedBox(height: BatshSpacing.sm),
            Text(brief.workDescription,
                style: BatshTypography.bodyLg.copyWith(height: 1.6)),
          ],
        ),
      ),
    );
  }
}

/// One fact from the brief: muted label, then the value in the reading weight.
/// Three of these sit in a row, so the value wraps to two lines rather than
/// truncating — Arabic specialty names are long and a clipped word is worse
/// than a taller tile.
class _SpecTile extends StatelessWidget {
  const _SpecTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: BatshSpacing.sm, vertical: BatshSpacing.md),
      decoration: BoxDecoration(
        color: BatshColors.surfaceContainerLow,
        borderRadius: BatshRadius.brMd,
        border: Border.all(
          color: BatshColors.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: BatshColors.onSurfaceVariant),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BatshTypography.labelSm
                      .copyWith(color: BatshColors.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: BatshSpacing.xs),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: BatshTypography.labelLg.copyWith(
              color: BatshColors.onSurface,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

/// Arabic labels for the brief's target specialties, capped at two so the tile
/// stays a glance and not a list. Falls back to an em-free dash when a brief
/// carries no specialties (older rows, or a homeowner who skipped the field).
String _workTypeValue(List<String> specialties) {
  if (specialties.isEmpty) return '—';
  return specialties
      .take(2)
      .map((s) => OnboardingCatalog.specialtiesCatalog[s] ?? s)
      .join(' · ');
}

class _HomeownerCard extends StatelessWidget {
  const _HomeownerCard({required this.future});

  final Future<({String name, String phone})?> future;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.gutter),
      child: FutureBuilder(
        future: future,
        builder: (context, snap) {
          final h = snap.data;
          return Container(
            padding: const EdgeInsets.all(BatshSpacing.gutter),
            decoration: BoxDecoration(
              color: BatshColors.cardBackground,
              borderRadius: BorderRadius.circular(BatshRadius.lg),
              boxShadow: BatshShadows.soft,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: BatshColors.secondaryContainer,
                    borderRadius: BatshRadius.brMd,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    h != null && h.name.isNotEmpty
                        ? h.name.characters.first
                        : '?',
                    style: BatshTypography.titleMd.copyWith(
                      color: BatshColors.onSecondaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: BatshSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        h?.name ?? '...',
                        style: BatshTypography.bodyLg.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      // "موثوق" row removed — no verification process backs
                      // it yet; showing it inflated trust artificially.
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ContactSection extends StatelessWidget {
  const _ContactSection({required this.future});

  final Future<({String name, String phone})?> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: future,
      builder: (context, snap) {
        final homeowner = snap.data;
        if (homeowner == null || homeowner.phone.isEmpty) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.gutter),
          child: Column(
            children: [
              WhatsAppButton(
                phone: homeowner.phone,
                message: S.whatsappPostGreeting,
              ),
              const SizedBox(height: BatshSpacing.sm),
              CallButton(phone: homeowner.phone),
            ],
          ),
        );
      },
    );
  }
}
