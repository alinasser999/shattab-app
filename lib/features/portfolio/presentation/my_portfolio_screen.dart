import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/batsh_motion.dart';
import '../../../core/theme/batsh_radius.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/theme/batsh_typography.dart';
import '../../../core/utils/image_url.dart';
import '../../../core/widgets/batsh_button.dart';
import '../../../core/widgets/batsh_empty_state.dart';
import '../../../core/widgets/batsh_error.dart';
import '../../../core/widgets/batsh_pressable.dart';
import '../../../core/widgets/batsh_scaffold.dart';
import '../../../core/widgets/batsh_shimmer.dart';
import '../../../core/utils/error_mapper.dart';
import '../domain/portfolio_project.dart';
import 'providers/my_portfolio_providers.dart';
import '../../../core/theme/batsh_icon_size.dart';
import '../../../core/widgets/batsh_snack.dart';

import 'package:batsh/core/theme/theme_extension.dart';

/// Contractor-facing portfolio manager (Tab 3). Grid of own projects;
/// tap to edit, long-press to delete, FAB to add.
class MyPortfolioScreen extends ConsumerWidget {
  const MyPortfolioScreen({super.key});

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    PortfolioProject p,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.deleteWork),
        content: Text(context.l10n.deleteWorkConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: context.colorScheme.error,
            ),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(portfolioControllerProvider.notifier).remove(p.id);
      if (context.mounted) {
        BatshSnack.success(context, context.l10n.projectDeletedSuccess);
      }
    } catch (_) {
      if (context.mounted) {
        BatshSnack.error(context, context.l10n.unknownErrorRetry);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(myPortfolioProvider);

    return BatshScaffold(
      title: context.l10n.myPortfolioTitle,
      headerStyle: BatshHeaderStyle.primary,
      floatingActionButton: projectsAsync.maybeWhen(
        data: (projects) => projects.isEmpty
            ? null
            : TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: BatshMotion.slower,
                curve: BatshMotion.easeOut,
                builder: (context, value, child) => Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 40 * (1 - value)),
                    child: child,
                  ),
                ),
                child: FloatingActionButton.extended(
                  onPressed: () => context.push(Routes.contractorPortfolioNew),
                  icon: const Icon(Icons.add),
                  label: Text(context.l10n.addWork),
                ),
              ),
        orElse: () => null,
      ),
      body: projectsAsync.when(
        loading: () => const _PortfolioSkeleton(),
        error: (e, _) => BatshError(
          message: ErrorMapper.map(e),
          onRetry: () => ref.invalidate(myPortfolioProvider),
        ),
        data: (projects) {
          if (projects.isEmpty) {
            return BatshEmptyState(
              title: context.l10n.portfolioEmptyTitle,
              message: context.l10n.portfolioEmptyMessage,
              icon: Icons.photo_library_outlined,
              action: BatshButton(
                label: context.l10n.addWork,
                icon: Icons.add,
                fullWidth: false,
                onPressed: () => context.push(Routes.contractorPortfolioNew),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(myPortfolioProvider);
              await ref.read(myPortfolioProvider.future);
            },
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(vertical: BatshSpacing.md),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: BatshSpacing.md,
                mainAxisSpacing: BatshSpacing.md,
                childAspectRatio: 3 / 4,
              ),
              itemCount: projects.length,
              itemBuilder: (context, i) {
                final p = projects[i];
                final reduced = MediaQuery.disableAnimationsOf(context);
                final tile = _PortfolioTile(
                  project: p,
                  onTap: () =>
                      context.push(Routes.contractorPortfolioEditPath(p.id)),
                  onLongPress: () => _confirmDelete(context, ref, p),
                );
                return reduced
                    ? tile
                    : tile
                          .animate()
                          .fadeIn(
                            duration: 320.ms,
                            delay: (60 * i.clamp(0, 7)).ms,
                            curve: BatshMotion.easeOut,
                          )
                          .slideY(
                            begin: 0.08,
                            end: 0,
                            curve: BatshMotion.easeOut,
                          );
              },
            ),
          );
        },
      ),
    );
  }
}

class _PortfolioSkeleton extends StatelessWidget {
  const _PortfolioSkeleton();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(BatshSpacing.gutter),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: BatshSpacing.md,
          mainAxisSpacing: BatshSpacing.md,
          childAspectRatio: 3 / 4,
        ),
        itemCount: 4,
        itemBuilder: (_, i) {
          final reduced = MediaQuery.disableAnimationsOf(context);
          final box = BatshShimmerBox(borderRadius: BatshRadius.brLg);
          return reduced
              ? box
              : box.animate().fadeIn(
                  duration: 320.ms,
                  delay: (60 * i.clamp(0, 7)).ms,
                  curve: BatshMotion.easeOut,
                );
        },
      ),
    );
  }
}

class _PortfolioTile extends StatelessWidget {
  const _PortfolioTile({
    required this.project,
    required this.onTap,
    required this.onLongPress,
  });

  final PortfolioProject project;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return BatshPressable(
      onTap: onTap,
      onLongPress: onLongPress,
      semanticLabel: project.title,
      child: Material(
        color: context.colorScheme.surfaceContainerLowest,
        borderRadius: BatshRadius.brLg,
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: sizedImageUrl(project.coverPhotoUrl, width: 480),
              fit: BoxFit.cover,
              memCacheWidth: 480,
              errorWidget: (_, _, _) => Container(
                color: context.colorScheme.surfaceContainer,
                child: Center(
                  child: Icon(
                    Icons.image_outlined,
                    size: BatshIconSize.xl,
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.center,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
            ),
            Positioned(
              left: BatshSpacing.sm,
              right: BatshSpacing.sm,
              bottom: BatshSpacing.sm,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (project.category != null)
                    Text(
                      project.category!.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BatshTypography.labelSm.copyWith(
                        color: context.colorScheme.tertiaryFixed,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                  Text(
                    project.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: BatshTypography.bodyMd.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: BatshSpacing.xs,
              right: BatshSpacing.xs,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(
                    Icons.edit_outlined,
                    size: BatshIconSize.sm,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
