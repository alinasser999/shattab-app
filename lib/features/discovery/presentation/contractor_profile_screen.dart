import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/batsh_colors.dart';
import '../../../core/theme/batsh_radius.dart';
import '../../../core/theme/batsh_shadows.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/theme/batsh_typography.dart';
import '../../../core/widgets/batsh_button.dart';
import '../../../core/widgets/batsh_error.dart';
import '../../../core/widgets/batsh_loading.dart';
import '../../../core/widgets/contact_buttons.dart';
import '../../onboarding/domain/onboarding_models.dart';
import '../../portfolio/domain/portfolio_project.dart';
import '../../portfolio/presentation/providers/portfolio_providers.dart';
import '../../saved/presentation/providers/saved_providers.dart';
import '../domain/contractor_listing.dart';
import 'providers/discovery_providers.dart';

class ContractorProfileScreen extends ConsumerWidget {
  const ContractorProfileScreen({super.key, required this.contractorId});

  final String contractorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(contractorByIdProvider(contractorId));

    return Scaffold(
      backgroundColor: BatshColors.background,
      body: async.when(
        loading: () => const BatshLoading(),
        error: (e, _) => BatshError(message: e.toString()),
        data: (c) {
          if (c == null) {
            return const Center(child: Text('المقاول مش موجود'));
          }
          return _ProfileBody(contractor: c);
        },
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.contractor});
  final ContractorListing contractor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedIds = ref.watch(savedContractorIdsProvider).value ?? const {};
    final isSaved = savedIds.contains(contractor.id);
    final portfolio =
        ref.watch(portfolioForContractorProvider(contractor.id)).value ??
            const <PortfolioProject>[];

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 240,
              pinned: true,
              backgroundColor: BatshColors.background,
              foregroundColor: BatshColors.onSurface,
              elevation: 0,
              actions: [
                IconButton(
                  icon: Icon(
                    isSaved ? Icons.favorite : Icons.favorite_border,
                    color:
                        isSaved ? BatshColors.primary : BatshColors.onSurface,
                  ),
                  onPressed: () => ref
                      .read(savedControllerProvider.notifier)
                      .toggle(contractor.id),
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () {},
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: _CoverHero(coverUrl: contractor.coverPhotoUrl),
              ),
            ),
            SliverToBoxAdapter(
              child: Transform.translate(
                offset: const Offset(0, -56),
                child: Column(
                  children: [
                    _AvatarRing(logoUrl: contractor.logoUrl),
                    const SizedBox(height: BatshSpacing.md),
                    _NameHeadline(contractor: contractor),
                    const SizedBox(height: BatshSpacing.md),
                    _RatingPill(rating: contractor.computedRating),
                    const SizedBox(height: BatshSpacing.lg),
                    _StatsRow(contractor: contractor, isSaved: isSaved),
                    const SizedBox(height: BatshSpacing.lg),
                    _CtaBlock(contractor: contractor),
                    const SizedBox(height: BatshSpacing.xl),
                    if (contractor.bio != null && contractor.bio!.isNotEmpty)
                      _BioSection(bio: contractor.bio!),
                    const SizedBox(height: BatshSpacing.xl),
                    _ChipsSection(
                      title: 'التخصصات',
                      labels: contractor.specialties
                          .map((s) =>
                              OnboardingCatalog.specialtiesCatalog[s] ?? s)
                          .toList(),
                    ),
                    const SizedBox(height: BatshSpacing.lg),
                    _ChipsSection(
                      title: 'بيشتغل في',
                      labels: contractor.serviceAreas,
                    ),
                    const SizedBox(height: BatshSpacing.xl),
                    _PortfolioSection(
                      contractor: contractor,
                      projects: portfolio,
                    ),
                    const SizedBox(height: 96),
                  ],
                ),
              ),
            ),
          ],
        ),
        Positioned(
          top: 8,
          right: 8,
          child: SafeArea(
            child: Material(
              color: Colors.white.withValues(alpha: 0.9),
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.arrow_forward,
                    color: BatshColors.onSurface),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ),
        ),
      ],
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
            imageUrl: coverUrl!,
            fit: BoxFit.cover,
            errorWidget: (_, _, _) => const _CoverFallback(),
          )
        else
          const _CoverFallback(),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                BatshColors.primary.withValues(alpha: 0.0),
                BatshColors.primary.withValues(alpha: 0.45),
                BatshColors.background.withValues(alpha: 0.95),
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
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            BatshColors.primaryContainer,
            BatshColors.tertiaryContainer,
          ],
        ),
      ),
    );
  }
}

class _AvatarRing extends StatelessWidget {
  const _AvatarRing({this.logoUrl});
  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 116,
      height: 116,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: BatshColors.background,
        shape: BoxShape.circle,
        boxShadow: BatshShadows.raised,
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: BatshColors.surfaceContainer,
          border: Border.all(color: BatshColors.primary, width: 3),
        ),
        clipBehavior: Clip.antiAlias,
        child: logoUrl != null
            ? CachedNetworkImage(imageUrl: logoUrl!, fit: BoxFit.cover)
            : const Icon(Icons.engineering_outlined,
                size: 48, color: BatshColors.primary),
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
      padding:
          const EdgeInsets.symmetric(horizontal: BatshSpacing.marginMobile),
      child: Column(
        children: [
          Text(name,
              textAlign: TextAlign.center,
              style: BatshTypography.headlineMd),
          if (contractor.headline != null) ...[
            const SizedBox(height: BatshSpacing.xs),
            Text(
              contractor.headline!,
              textAlign: TextAlign.center,
              style: BatshTypography.bodyMd
                  .copyWith(color: BatshColors.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

class _RatingPill extends StatelessWidget {
  const _RatingPill({required this.rating});
  final double rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: BatshSpacing.gutter, vertical: BatshSpacing.sm),
      decoration: BoxDecoration(
        color: BatshColors.tertiaryFixed,
        borderRadius: BatshRadius.brFull,
        border: Border.all(color: BatshColors.tertiary, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (i) {
              final filled = i < rating.floor();
              final half = !filled && i == rating.floor() && rating % 1 >= 0.4;
              return Icon(
                half ? Icons.star_half : Icons.star,
                size: 14,
                color: filled || half
                    ? BatshColors.tertiary
                    : BatshColors.surfaceContainerHigh,
              );
            }),
          ),
          const SizedBox(width: BatshSpacing.sm),
          Text(
            rating.toStringAsFixed(1),
            style: BatshTypography.labelMd.copyWith(
              color: BatshColors.onTertiaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.contractor, required this.isSaved});
  final ContractorListing contractor;
  final bool isSaved;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: BatshSpacing.marginMobile),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              value: '${contractor.responseRate}%',
              label: 'معدل الرد',
              icon: Icons.bolt_outlined,
            ),
          ),
          const SizedBox(width: BatshSpacing.sm),
          Expanded(
            child: _StatCard(
              value: '${contractor.projectsCompleted}',
              label: 'مشروع متنفّذ',
              icon: Icons.home_work_outlined,
            ),
          ),
          const SizedBox(width: BatshSpacing.sm),
          Expanded(
            child: _StatCard(
              value: contractor.yearsExperience != null
                  ? '${contractor.yearsExperience}'
                  : '—',
              label: 'سنة خبرة',
              icon: Icons.workspace_premium_outlined,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
  });
  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          vertical: BatshSpacing.md, horizontal: BatshSpacing.sm),
      decoration: BoxDecoration(
        color: BatshColors.surfaceContainerLowest,
        borderRadius: BatshRadius.brLg,
        border: Border.all(color: BatshColors.outlineVariant, width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: BatshColors.primary, size: 20),
          const SizedBox(height: BatshSpacing.xs),
          Text(value,
              style: BatshTypography.titleLg.copyWith(
                  color: BatshColors.onSurface, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: BatshTypography.labelSm
                  .copyWith(color: BatshColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _CtaBlock extends StatelessWidget {
  const _CtaBlock({required this.contractor});
  final ContractorListing contractor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: BatshSpacing.marginMobile),
      child: Column(
        children: [
          BatshButton(
            label: 'ابعت تفاصيل مشروعك',
            onPressed: () => context.push(
                Routes.homeownerSendBriefPath(contractor.id)),
          ),
          const SizedBox(height: BatshSpacing.sm),
          Row(
            children: [
              Expanded(
                child: WhatsAppButton(
                  phone: contractor.phone,
                  message:
                      'السلام عليكم، شفت بروفايلك على شطب وحبيت أكلمك',
                ),
              ),
              const SizedBox(width: BatshSpacing.sm),
              Expanded(child: CallButton(phone: contractor.phone)),
            ],
          ),
        ],
      ),
    );
  }
}

class _BioSection extends StatelessWidget {
  const _BioSection({required this.bio});
  final String bio;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: BatshSpacing.marginMobile),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(BatshSpacing.gutter),
        decoration: BoxDecoration(
          color: BatshColors.surfaceContainerLow,
          borderRadius: BatshRadius.brLg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('عن المقاول',
                style: BatshTypography.labelMd.copyWith(
                  color: BatshColors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(height: BatshSpacing.sm),
            Text(bio, style: BatshTypography.bodyLg),
          ],
        ),
      ),
    );
  }
}

class _ChipsSection extends StatelessWidget {
  const _ChipsSection({required this.title, required this.labels});
  final String title;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: BatshSpacing.marginMobile),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: BatshTypography.titleLg
                  .copyWith(color: BatshColors.onSurface)),
          const SizedBox(height: BatshSpacing.sm),
          Wrap(
            spacing: BatshSpacing.sm,
            runSpacing: BatshSpacing.sm,
            children: [
              for (final label in labels)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: BatshSpacing.gutter,
                      vertical: BatshSpacing.sm),
                  decoration: BoxDecoration(
                    color: BatshColors.surfaceContainer,
                    borderRadius: BatshRadius.brFull,
                    border: Border.all(
                        color: BatshColors.outlineVariant, width: 1),
                  ),
                  child: Text(label,
                      style: BatshTypography.labelMd.copyWith(
                          color: BatshColors.onSurface,
                          fontWeight: FontWeight.w600)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PortfolioSection extends StatelessWidget {
  const _PortfolioSection({required this.contractor, required this.projects});
  final ContractorListing contractor;
  final List<PortfolioProject> projects;

  @override
  Widget build(BuildContext context) {
    if (projects.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: BatshSpacing.marginMobile),
          child: Row(
            children: [
              Text('معرض الأعمال',
                  style: BatshTypography.titleLg
                      .copyWith(color: BatshColors.onSurface)),
              const Spacer(),
              TextButton(
                onPressed: () => context.push(
                    Routes.homeownerContractorPortfolioPath(contractor.id)),
                child: const Text('شاهد الكل'),
              ),
            ],
          ),
        ),
        const SizedBox(height: BatshSpacing.sm),
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
                horizontal: BatshSpacing.marginMobile),
            itemCount: projects.length,
            separatorBuilder: (_, _) =>
                const SizedBox(width: BatshSpacing.gutter),
            itemBuilder: (context, i) {
              final p = projects[i];
              return _PortfolioTile(
                project: p,
                onTap: () => context
                    .push(Routes.homeownerProjectDetailPath(contractor.id, p.id)),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PortfolioTile extends StatelessWidget {
  const _PortfolioTile({required this.project, required this.onTap});
  final PortfolioProject project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Material(
        color: BatshColors.surfaceContainerLowest,
        borderRadius: BatshRadius.brLg,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 10,
                child: CachedNetworkImage(
                  imageUrl: project.coverPhotoUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => Container(
                      color: BatshColors.surfaceContainer,
                      child: const Icon(Icons.image_outlined,
                          color: BatshColors.onSurfaceVariant)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(BatshSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(project.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: BatshTypography.labelMd
                            .copyWith(fontWeight: FontWeight.w700)),
                    if (project.category != null) ...[
                      const SizedBox(height: 2),
                      Text(project.category!,
                          style: BatshTypography.labelSm.copyWith(
                              color: BatshColors.onSurfaceVariant)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
