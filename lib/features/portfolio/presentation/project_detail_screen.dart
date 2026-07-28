import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../core/theme/batsh_colors.dart';
import '../../../core/theme/batsh_radius.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/theme/batsh_typography.dart';
import '../../../core/widgets/batsh_error.dart';
import '../../../core/widgets/batsh_shimmer.dart';
import '../../../core/utils/error_mapper.dart';
import 'providers/portfolio_providers.dart';
import '../../../core/theme/batsh_icon_size.dart';

import 'package:batsh/core/theme/theme_extension.dart';

class ProjectDetailScreen extends ConsumerWidget {
  const ProjectDetailScreen({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(portfolioProjectProvider(projectId));

    return Scaffold(
      backgroundColor: context.colorScheme.background,
      body: async.when(
        loading: () => const BatshHeroDetailSkeleton(),
        error: (e, _) => BatshError(
          message: ErrorMapper.map(e),
          onRetry: () => ref.invalidate(portfolioProjectProvider(projectId)),
        ),
        data: (project) {
          if (project == null) {
            return BatshError(message: context.l10n.projectNotFound);
          }
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 320,
                pinned: true,
                backgroundColor: context.colorScheme.background,
                foregroundColor: context.colorScheme.onSurface,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: 'portfolio-${project.id}',
                        child: CachedNetworkImage(
                          imageUrl: project.coverPhotoUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              context.colorScheme.background.withValues(
                                alpha: 0.9,
                              ),
                            ],
                            stops: const [0.6, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(BatshSpacing.marginMobile),
                sliver: SliverList.list(
                  children: [
                    if (project.category != null)
                      Text(
                        project.category!.toUpperCase(),
                        style: BatshTypography.labelSm.copyWith(
                          color: context.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    const SizedBox(height: BatshSpacing.xs),
                    Text(project.title, style: BatshTypography.headlineLg),
                    const SizedBox(height: BatshSpacing.md),
                    if (project.description != null)
                      Text(project.description!, style: BatshTypography.bodyLg),
                    const SizedBox(height: BatshSpacing.lg),
                    Container(
                      padding: const EdgeInsets.all(BatshSpacing.gutter),
                      decoration: BoxDecoration(
                        color: context.colorScheme.surfaceContainerLow,
                        borderRadius: BatshRadius.brLg,
                      ),
                      child: Wrap(
                        spacing: BatshSpacing.lg,
                        runSpacing: BatshSpacing.md,
                        children: [
                          if (project.location != null)
                            _MetaItem(
                              icon: Icons.place_outlined,
                              label: context.l10n.projectLocationLabel,
                              value: project.location!,
                            ),
                          if (project.yearCompleted != null)
                            _MetaItem(
                              icon: Icons.event_outlined,
                              label: context.l10n.projectYearLabel,
                              value: '${project.yearCompleted}',
                            ),
                          if (project.apartmentType != null)
                            _MetaItem(
                              icon: Icons.home_outlined,
                              label: context.l10n.apartmentTypeLabel,
                              value: project.apartmentType!,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: BatshSpacing.xl),
                    if (project.photoUrls.isNotEmpty)
                      ...project.photoUrls.map(
                        (url) => Padding(
                          padding: const EdgeInsets.only(
                            bottom: BatshSpacing.md,
                          ),
                          child: ClipRRect(
                            borderRadius: BatshRadius.brLg,
                            child: CachedNetworkImage(
                              imageUrl: url,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: context.colorScheme.primary, size: BatshIconSize.md),
        const SizedBox(width: BatshSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: BatshTypography.labelSm.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              style: BatshTypography.labelMd.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
