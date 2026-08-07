import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/batsh_icon_size.dart';
import '../../../core/theme/batsh_radius.dart';
import '../../../core/theme/batsh_shadows.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/theme/batsh_typography.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../core/widgets/batsh_empty_state.dart';
import '../../../core/widgets/batsh_error.dart';
import '../../../core/widgets/batsh_pressable.dart';
import '../../../core/widgets/batsh_scaffold.dart';
import '../../../core/widgets/batsh_shimmer.dart';
import '../../portfolio/domain/portfolio_project.dart';
import '../../portfolio/presentation/providers/portfolio_providers.dart';
import 'widgets/mockup_assets.dart';

/// Full portfolio-project collection opened from the discover work rail.
/// Each tile keeps the existing project-detail route, so the page is a real
/// catalogue of completed work rather than a shortcut to contractor listings.
class CompletedWorkScreen extends ConsumerStatefulWidget {
  const CompletedWorkScreen({super.key});

  @override
  ConsumerState<CompletedWorkScreen> createState() =>
      _CompletedWorkScreenState();
}

class _CompletedWorkScreenState extends ConsumerState<CompletedWorkScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _loadingMore = false;
  Object? _paginationError;

  bool get _hasMore => ref.read(recentWorkCollectionProvider.notifier).hasMore;

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() {
      _loadingMore = true;
      _paginationError = null;
    });
    try {
      await ref.read(recentWorkCollectionProvider.notifier).loadMore();
    } catch (error) {
      if (mounted) setState(() => _paginationError = error);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(recentWorkCollectionProvider);
    await ref.read(recentWorkCollectionProvider.future);
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.extentAfter < 520) _loadMore();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(recentWorkCollectionProvider);

    return BatshScaffold(
      title: context.l10n.recentWorkTitle,
      body: projectsAsync.when(
        loading: () => const _CompletedWorkSkeleton(),
        error: (error, _) =>
            BatshError(message: ErrorMapper.map(error), onRetry: _refresh),
        data: (projects) {
          if (projects.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.55,
                  child: BatshEmptyState(
                    title: context.l10n.noWorksTitle,
                    message: context.l10n.noWorksMessage,
                    icon: Icons.photo_library_outlined,
                    action: OutlinedButton(
                      onPressed: _refresh,
                      child: Text(context.l10n.tryAgain),
                    ),
                  ),
                ),
              ],
            );
          }

          final showFooter =
              _hasMore || _loadingMore || _paginationError != null;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(
                top: BatshSpacing.sm,
                bottom: BatshSpacing.xxl,
              ),
              itemCount: projects.length + (showFooter ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == projects.length) {
                  return _CompletedWorkFooter(
                    loading: _loadingMore,
                    error: _paginationError,
                    hasMore: _hasMore,
                    onRetry: _loadMore,
                  );
                }
                final project = projects[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: BatshSpacing.lg),
                  child: _CompletedWorkCard(project: project),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _CompletedWorkCard extends StatelessWidget {
  const _CompletedWorkCard({required this.project});

  final PortfolioProject project;

  @override
  Widget build(BuildContext context) {
    final metadata = <(IconData, String)>[
      if (project.category case final category? when category.isNotEmpty)
        (Icons.handyman_outlined, category),
      if (project.location case final location? when location.isNotEmpty)
        (Icons.place_outlined, location),
      if (project.yearCompleted case final year?)
        (Icons.event_outlined, '$year'),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BatshRadius.brCard,
        boxShadow: BatshShadows.soft,
      ),
      child: BatshPressable(
        onTap: () => context.push(
          Routes.homeownerProjectDetailPath(project.contractorId, project.id),
        ),
        semanticLabel: project.title,
        child: Material(
          color: context.colorScheme.surfaceContainerLowest,
          borderRadius: BatshRadius.brCard,
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 16 / 10,
                child: MockupImage(
                  url: project.coverPhotoUrl,
                  memCacheWidth: 900,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(BatshSpacing.gutter),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: BatshTypography.titleLg,
                      ),
                      if (metadata.isNotEmpty) ...[
                        const SizedBox(height: BatshSpacing.sm),
                        Wrap(
                          spacing: BatshSpacing.md,
                          runSpacing: BatshSpacing.xs,
                          children: [
                            for (final (icon, label) in metadata)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    icon,
                                    size: BatshIconSize.sm,
                                    color: context.colorScheme.primary,
                                  ),
                                  const SizedBox(width: BatshSpacing.xxs),
                                  Text(
                                    label,
                                    style: BatshTypography.labelMd.copyWith(
                                      color:
                                          context.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: BatshSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              context.l10n.completedProjectsShort,
                              style: BatshTypography.bodySm.copyWith(
                                color: context.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: BatshIconSize.xs,
                            color: context.colorScheme.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompletedWorkFooter extends StatelessWidget {
  const _CompletedWorkFooter({
    required this.loading,
    required this.error,
    required this.hasMore,
    required this.onRetry,
  });

  final bool loading;
  final Object? error;
  final bool hasMore;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: BatshSpacing.lg),
        child: Center(
          child: Semantics(
            label: context.l10n.loadingMore,
            child: const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: BatshSpacing.md),
        child: OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(context.l10n.tryAgain),
        ),
      );
    }
    if (!hasMore) return const SizedBox(height: BatshSpacing.md);
    return const SizedBox(height: BatshSpacing.md);
  }
}

class _CompletedWorkSkeleton extends StatelessWidget {
  const _CompletedWorkSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(
        top: BatshSpacing.sm,
        bottom: BatshSpacing.xxl,
      ),
      children: [
        for (var i = 0; i < 3; i++) ...[
          const BatshShimmerBox(
            width: double.infinity,
            height: 220,
            borderRadius: BatshRadius.brCard,
          ),
          const SizedBox(height: BatshSpacing.sm),
          const BatshShimmerBox(width: 190, height: 20),
          const SizedBox(height: BatshSpacing.xs),
          const BatshShimmerBox(width: 240, height: 14),
          const SizedBox(height: BatshSpacing.xl),
        ],
      ],
    );
  }
}
