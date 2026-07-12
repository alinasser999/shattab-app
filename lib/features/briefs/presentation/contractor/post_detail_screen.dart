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
import '../../../../core/widgets/batsh_scaffold.dart';
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
      _BriefInfoCard(brief: brief, apt: apt, place: place, time: relativeTime),
      const SizedBox(height: BatshSpacing.gutter),
      _HomeownerCard(future: futureHomeowner),
      const SizedBox(height: BatshSpacing.gutter),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BatshButton(
              label: S.sendQuoteButton,
              icon: Icons.request_quote_outlined,
              onPressed: onQuote,
            ),
          ],
        ),
      ),
      const SizedBox(height: BatshSpacing.md),
      _ContactSection(future: futureHomeowner),
      const SizedBox(height: BatshSpacing.xl),
    ];
    return ListView(
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

class _HeroImageSection extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(BatshRadius.xl)),
              child: CachedNetworkImage(
                  imageUrl: photoUrls.first,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => Container(
                      color: BatshColors.surfaceContainer),
                  errorWidget: (_, _, _) => Container(
                      color: BatshColors.surfaceContainer)),
            ),
          ),
          Positioned.fill(
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
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(BatshRadius.xl)),
              ),
            ),
          ),
          Positioned(
            right: BatshSpacing.gutter,
            left: BatshSpacing.gutter,
            bottom: BatshSpacing.gutter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    _Pill(label: apartmentLabel,
                        bgColor: Colors.white24, textColor: Colors.white),
                    const SizedBox(width: BatshSpacing.sm),
                    _Pill(label: location,
                        bgColor: Colors.white24, textColor: Colors.white),
                  ],
                ),
                const SizedBox(height: BatshSpacing.sm),
                Text(
                  title,
                  style: BatshTypography.titleLg.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (photoUrls.length > 1)
            Positioned(
              top: BatshSpacing.md,
              left: BatshSpacing.gutter,
              child: _Pill(
                label: '1 / ${photoUrls.length}',
                bgColor: Colors.black38,
                textColor: Colors.white,
              ),
            ),
        ],
      ),
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
    required this.place,
    required this.time,
  });

  final Brief brief;
  final String apt;
  final String place;
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
          borderRadius: BorderRadius.circular(BatshRadius.lg),
          boxShadow: BatshShadows.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _InfoChip(
                    icon: Icons.home_outlined,
                    label: apt,
                    color: BatshColors.primary),
                const SizedBox(width: BatshSpacing.sm),
                _InfoChip(
                    icon: Icons.place_outlined,
                    label: place,
                    color: BatshColors.secondary),
              ],
            ),
            const SizedBox(height: BatshSpacing.lg),
            Text(S.postDescriptionLabel,
                style: BatshTypography.labelMd.copyWith(
                    color: BatshColors.onSurfaceVariant)),
            const SizedBox(height: BatshSpacing.sm),
          Text(brief.workDescription,
                style: BatshTypography.bodyLg.copyWith(height: 1.6)),
            const SizedBox(height: BatshSpacing.lg),
            Row(
              children: [
                Icon(Icons.access_time,
                    size: 15, color: BatshColors.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(time,
                    style: BatshTypography.labelMd
                        .copyWith(color: BatshColors.onSurfaceVariant)),
                if (brief.photoUrls.isNotEmpty) ...[
                  const Spacer(),
                  Icon(Icons.photo_camera_outlined,
                      size: 15, color: BatshColors.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text('${brief.photoUrls.length} ${S.photos}',
                      style: BatshTypography.labelMd.copyWith(
                          color: BatshColors.onSurfaceVariant)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BatshRadius.brSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label,
              maxLines: 1,
              style: BatshTypography.labelSm.copyWith(
                  color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
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
