import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/batsh_radius.dart';
import '../../../core/theme/batsh_shadows.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/theme/batsh_typography.dart';
import '../../../core/widgets/batsh_empty_state.dart';
import '../../../core/widgets/batsh_error.dart';
import '../../../core/widgets/batsh_scaffold.dart';
import '../../../core/widgets/batsh_shimmer.dart';
import '../../discovery/presentation/providers/discovery_providers.dart';
import '../../../core/utils/error_mapper.dart';
import '../domain/portfolio_project.dart';
import 'providers/portfolio_providers.dart';
import '../../../core/theme/batsh_icon_size.dart';

import 'package:batsh/core/theme/theme_extension.dart';

class PortfolioGalleryScreen extends ConsumerWidget {
  const PortfolioGalleryScreen({super.key, required this.contractorId});

  final String contractorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contractor = ref.watch(contractorByIdProvider(contractorId)).value;
    final projectsAsync = ref.watch(
      portfolioForContractorProvider(contractorId),
    );

    return BatshScaffold(
      title: context.l10n.portfolioGalleryTitle,
      body: projectsAsync.when(
        loading: () => const _GallerySkeleton(),
        error: (e, _) => BatshError(
          message: ErrorMapper.map(e),
          onRetry: () =>
              ref.invalidate(portfolioForContractorProvider(contractorId)),
        ),
        data: (projects) {
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(portfolioForContractorProvider(contractorId)),
            child: projects.isEmpty
                ? ListView(
                    children: [
                      BatshEmptyState(
                        title: context.l10n.noWorksTitle,
                        message: context.l10n.noWorksMessage,
                        icon: Icons.photo_library_outlined,
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(
                      vertical: BatshSpacing.md,
                    ),
                    children: [
                      if (contractor != null) ...[
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: BatshSpacing.md,
                          ),
                          child: Text(
                            contractor.businessName.isNotEmpty
                                ? contractor.businessName
                                : contractor.fullName,
                            style: BatshTypography.titleLg.copyWith(
                              color: context.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                      for (final p in projects) ...[
                        _ProjectMagazineCard(
                          project: p,
                          onTap: () => context.push(
                            Routes.homeownerProjectDetailPath(
                              contractorId,
                              p.id,
                            ),
                          ),
                        ),
                        const SizedBox(height: BatshSpacing.lg),
                      ],
                    ],
                  ),
          );
        },
      ),
    );
  }
}

class _ProjectMagazineCard extends StatelessWidget {
  const _ProjectMagazineCard({required this.project, required this.onTap});
  final PortfolioProject project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colorScheme.surfaceContainerLowest,
      borderRadius: BatshRadius.brLg,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 11,
              child: DecoratedBox(
                decoration: BoxDecoration(boxShadow: BatshShadows.soft),
                child: Hero(
                  tag: 'portfolio-${project.id}',
                  child: CachedNetworkImage(
                    imageUrl: project.coverPhotoUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => Container(
                      color: context.colorScheme.surfaceContainer,
                      child: Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: BatshIconSize.xxl,
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(BatshSpacing.gutter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (project.category != null) ...[
                    Text(
                      project.category!.toUpperCase(),
                      style: BatshTypography.labelSm.copyWith(
                        color: context.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: BatshSpacing.xs),
                  ],
                  Text(
                    project.title,
                    style: BatshTypography.headlineMd.copyWith(
                      fontSize: 22,
                      height: 30 / 22,
                    ),
                  ),
                  if (project.description != null) ...[
                    const SizedBox(height: BatshSpacing.sm),
                    Text(
                      project.description!,
                      style: BatshTypography.bodyMd.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: BatshSpacing.md),
                  _Specs(project: project),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Specs extends StatelessWidget {
  const _Specs({required this.project});
  final PortfolioProject project;

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String)>[];
    if (project.location != null) {
      items.add((Icons.place_outlined, project.location!));
    }
    if (project.yearCompleted != null) {
      items.add((Icons.event_outlined, '${project.yearCompleted}'));
    }
    if (items.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: BatshSpacing.gutter,
      runSpacing: BatshSpacing.sm,
      children: [
        for (final (icon, label) in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: BatshIconSize.sm,
                color: context.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: BatshTypography.labelMd.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _GallerySkeleton extends StatelessWidget {
  const _GallerySkeleton();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: BatshSpacing.md),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BatshSpacing.marginMobile,
          ),
          child: BatshShimmerBox(
            width: 180,
            height: 18,
            borderRadius: BatshRadius.brSm,
          ),
        ),
        const SizedBox(height: BatshSpacing.md),
        for (var i = 0; i < 3; i++) ...[
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: BatshSpacing.marginMobile,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BatshShimmerBox(
                  width: double.infinity,
                  height: 180,
                  borderRadius: BatshRadius.brLg,
                ),
                const SizedBox(height: BatshSpacing.gutter),
                BatshShimmerBox(
                  width: 100,
                  height: 12,
                  borderRadius: BatshRadius.brSm,
                ),
                const SizedBox(height: BatshSpacing.xs),
                BatshShimmerBox(
                  width: 200,
                  height: 18,
                  borderRadius: BatshRadius.brSm,
                ),
                const SizedBox(height: BatshSpacing.xs),
                BatshShimmerBox(
                  width: double.infinity,
                  height: 14,
                  borderRadius: BatshRadius.brSm,
                ),
              ],
            ),
          ),
          const SizedBox(height: BatshSpacing.lg),
        ],
      ],
    );
  }
}
