import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/batsh_colors.dart';
import '../../../core/theme/batsh_radius.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/theme/batsh_typography.dart';
import '../../../core/widgets/batsh_error.dart';
import '../../../core/widgets/batsh_loading.dart';
import 'providers/portfolio_providers.dart';

class ProjectDetailScreen extends ConsumerWidget {
  const ProjectDetailScreen({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(portfolioProjectProvider(projectId));

    return Scaffold(
      backgroundColor: BatshColors.background,
      body: async.when(
        loading: () => const BatshLoading(),
        error: (e, _) => BatshError(message: e.toString()),
        data: (project) {
          if (project == null) {
            return const BatshError(message: 'العمل مش موجود');
          }
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 320,
                pinned: true,
                backgroundColor: BatshColors.background,
                foregroundColor: BatshColors.onSurface,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: project.coverPhotoUrl,
                        fit: BoxFit.cover,
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              BatshColors.background.withValues(alpha: 0.9),
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
                      Text(project.category!.toUpperCase(),
                          style: BatshTypography.labelSm.copyWith(
                            color: BatshColors.primary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          )),
                    const SizedBox(height: BatshSpacing.xs),
                    Text(project.title,
                        style: BatshTypography.headlineLg),
                    const SizedBox(height: BatshSpacing.md),
                    if (project.description != null)
                      Text(project.description!,
                          style: BatshTypography.bodyLg),
                    const SizedBox(height: BatshSpacing.lg),
                    Container(
                      padding: const EdgeInsets.all(BatshSpacing.gutter),
                      decoration: BoxDecoration(
                        color: BatshColors.surfaceContainerLow,
                        borderRadius: BatshRadius.brLg,
                      ),
                      child: Wrap(
                        spacing: BatshSpacing.lg,
                        runSpacing: BatshSpacing.md,
                        children: [
                          if (project.location != null)
                            _MetaItem(
                                icon: Icons.place_outlined,
                                label: 'المكان',
                                value: project.location!),
                          if (project.yearCompleted != null)
                            _MetaItem(
                                icon: Icons.event_outlined,
                                label: 'سنة التنفيذ',
                                value: '${project.yearCompleted}'),
                          if (project.apartmentType != null)
                            _MetaItem(
                                icon: Icons.home_outlined,
                                label: 'نوع الوحدة',
                                value: project.apartmentType!),
                        ],
                      ),
                    ),
                    const SizedBox(height: BatshSpacing.xl),
                    if (project.photoUrls.isNotEmpty)
                      ...project.photoUrls.map((url) => Padding(
                            padding: const EdgeInsets.only(
                                bottom: BatshSpacing.md),
                            child: ClipRRect(
                              borderRadius: BatshRadius.brLg,
                              child: CachedNetworkImage(
                                imageUrl: url,
                                fit: BoxFit.cover,
                              ),
                            ),
                          )),
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
  const _MetaItem(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: BatshColors.primary, size: 18),
        const SizedBox(width: BatshSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: BatshTypography.labelSm.copyWith(
                    color: BatshColors.onSurfaceVariant)),
            Text(value,
                style: BatshTypography.labelMd
                    .copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    );
  }
}
