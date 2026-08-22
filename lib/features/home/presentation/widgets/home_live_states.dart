import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/theme/batsh_radius.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../../core/utils/support_contact.dart';
import '../../../../core/widgets/batsh_pressable.dart';
import '../../../../core/widgets/shattab_experience_state.dart';
import '../../../../core/widgets/shattab_pattern.dart';
import '../../../briefs/domain/brief.dart';
import '../../../briefs/presentation/providers/briefs_providers.dart';
import '../../../notifications/presentation/providers/notifications_providers.dart';
import '../../../notifications/presentation/notification_copy.dart';

/// A live home surface for request progress, recent activity, and first use.
class HomeLiveStateSection extends ConsumerWidget {
  const HomeLiveStateSection({
    super.key,
    required this.onOpenRequests,
    required this.onOpenNotifications,
    required this.onStartRequest,
  });

  final VoidCallback onOpenRequests;
  final VoidCallback onOpenNotifications;
  final VoidCallback onStartRequest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final briefs = ref.watch(myBriefsProvider);
    final notifications = ref.watch(notificationsProvider);
    final unreadCount = ref.watch(unreadNotificationsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.gutter),
      child: briefs.when(
        loading: () => const ShattabExperienceSkeleton(),
        error: (error, _) => ShattabExperienceState(
          icon: Icons.cloud_off_outlined,
          title: context.l10n.homeLiveErrorTitle,
          message: ErrorMapper.map(error),
          actionLabel: context.l10n.tryAgain,
          onAction: () => ref.invalidate(myBriefsProvider),
          secondaryActionLabel: context.l10n.helpSupport,
          onSecondaryAction: () => openShattabSupport(context),
          pattern: ShattabPatternKind.contour,
        ),
        data: (items) {
          final active = items
              .where(
                (brief) => brief.isActive || brief.awaitsCompletionConfirmation,
              )
              .firstOrNull;
          if (active != null) {
            return _HomeRequestActivityCard(
              brief: active,
              onOpen: onOpenRequests,
              unreadCount: unreadCount,
              onOpenNotifications: onOpenNotifications,
            );
          }

          final latest = notifications.asData?.value.firstOrNull;
          if (notifications.hasError) {
            return ShattabExperienceState(
              icon: Icons.cloud_off_outlined,
              title: context.l10n.homeLiveErrorTitle,
              message: ErrorMapper.map(notifications.error),
              actionLabel: context.l10n.homeLiveStartAction,
              onAction: onStartRequest,
              secondaryActionLabel: context.l10n.tryAgain,
              onSecondaryAction: () => ref.invalidate(notificationsProvider),
              pattern: ShattabPatternKind.contour,
            );
          }
          if (latest != null) {
            return _HomeLatestActivityCard(
              unreadCount: unreadCount,
              title: context.l10n.homeLiveLatestActivity,
              message:
                  '${notificationTitle(context, latest)}: ${notificationBody(context, latest)}',
              onOpenNotifications: onOpenNotifications,
              onOpenRequests: onOpenRequests,
            );
          }
          if (notifications.isLoading) {
            return const ShattabExperienceSkeleton(compact: true);
          }

          return ShattabExperienceState(
            icon: Icons.auto_awesome_outlined,
            title: context.l10n.homeLiveEmptyTitle,
            message: context.l10n.homeLiveEmptyMessage,
            actionLabel: context.l10n.homeLiveStartAction,
            onAction: onStartRequest,
            secondaryActionLabel: context.l10n.homeLiveOpenNotifications,
            onSecondaryAction: onOpenNotifications,
            pattern: ShattabPatternKind.arches,
          );
        },
      ),
    );
  }
}

class _HomeRequestActivityCard extends StatelessWidget {
  const _HomeRequestActivityCard({
    required this.brief,
    required this.onOpen,
    required this.unreadCount,
    required this.onOpenNotifications,
  });

  final Brief brief;
  final VoidCallback onOpen;
  final int unreadCount;
  final VoidCallback onOpenNotifications;

  int get _activeStep => switch (brief.stage) {
    BriefStage.open => 1,
    BriefStage.hired => 2,
    BriefStage.completionRequested => 3,
    BriefStage.completed => 4,
  };

  String _statusLabel(BuildContext context) => switch (brief.stage) {
    BriefStage.open => context.l10n.homeLiveAwaitingOffers,
    BriefStage.hired => context.l10n.homeLiveWorkInProgress,
    BriefStage.completionRequested => context.l10n.homeLiveReviewCompletion,
    BriefStage.completed => context.l10n.homeLiveCompleted,
  };

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final summary = brief.workDescription.trim().isEmpty
        ? context.l10n.homeActiveRequestFallback
        : brief.workDescription.trim();
    final steps = <String>[
      context.l10n.homeLiveRequestPosted,
      context.l10n.homeLiveAwaitingOffers,
      context.l10n.homeLiveWorkInProgress,
      context.l10n.homeLiveCompleted,
    ];

    return Semantics(
      container: true,
      label:
          '${context.l10n.homeActiveRequestTitle}. ${brief.city}. ${_statusLabel(context)}',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          borderRadius: BatshRadius.brCard,
          border: Border.all(color: scheme.primary.withValues(alpha: 0.26)),
        ),
        child: Stack(
          children: [
            PositionedDirectional(
              top: -18,
              end: -12,
              width: 132,
              height: 96,
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: Opacity(
                    opacity: 0.18,
                    child: ShattabPattern(
                      kind: ShattabPatternKind.contour,
                      color: scheme.primary,
                      opacity: 0.32,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(BatshSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.l10n.homeLiveActivityTitle,
                          style: BatshTypography.titleLg.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      _ActivityPill(label: _statusLabel(context)),
                    ],
                  ),
                  const SizedBox(height: BatshSpacing.xs),
                  Text(
                    summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: BatshTypography.bodyMd.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: BatshSpacing.xs),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 17,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: BatshSpacing.xxs),
                      Expanded(
                        child: Text(
                          brief.city,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: BatshTypography.labelMd.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if (unreadCount > 0)
                        _UnreadActivityButton(
                          count: unreadCount,
                          onTap: onOpenNotifications,
                        ),
                    ],
                  ),
                  const SizedBox(height: BatshSpacing.lg),
                  _RequestTimeline(steps: steps, activeStep: _activeStep),
                  const SizedBox(height: BatshSpacing.md),
                  BatshPressable(
                    onTap: onOpen,
                    semanticLabel: context.l10n.requestDetailTitle,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          context.l10n.requestDetailTitle,
                          style: BatshTypography.labelLg.copyWith(
                            color: scheme.primary,
                          ),
                        ),
                        const SizedBox(width: BatshSpacing.xxs),
                        Icon(
                          Icons.arrow_back_rounded,
                          size: 18,
                          color: scheme.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeLatestActivityCard extends StatelessWidget {
  const _HomeLatestActivityCard({
    required this.unreadCount,
    required this.title,
    required this.message,
    required this.onOpenNotifications,
    required this.onOpenRequests,
  });

  final int unreadCount;
  final String title;
  final String message;
  final VoidCallback onOpenNotifications;
  final VoidCallback onOpenRequests;

  @override
  Widget build(BuildContext context) {
    return ShattabExperienceState(
      icon: Icons.notifications_active_outlined,
      title: title,
      message: unreadCount > 0
          ? '$message · ${context.l10n.homeLiveUnreadCount(unreadCount)}'
          : message,
      actionLabel: context.l10n.homeLiveOpenNotifications,
      onAction: onOpenNotifications,
      secondaryActionLabel: context.l10n.homeLiveOpenRequests,
      onSecondaryAction: onOpenRequests,
      pattern: ShattabPatternKind.terrazzo,
      accent: context.colorScheme.secondary,
    );
  }
}

class _ActivityPill extends StatelessWidget {
  const _ActivityPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 142),
      padding: const EdgeInsets.symmetric(
        horizontal: BatshSpacing.sm,
        vertical: BatshSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: context.colorScheme.secondaryContainer,
        borderRadius: BatshRadius.brFull,
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: BatshTypography.labelSm.copyWith(
          color: context.colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _UnreadActivityButton extends StatelessWidget {
  const _UnreadActivityButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.homeLiveOpenNotifications,
      child: Material(
        color: context.colorScheme.primaryContainer.withValues(alpha: 0.48),
        borderRadius: BatshRadius.brFull,
        child: InkWell(
          onTap: onTap,
          borderRadius: BatshRadius.brFull,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: BatshSpacing.sm,
              vertical: BatshSpacing.xs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.notifications_none_rounded,
                  size: 16,
                  color: context.colorScheme.primary,
                ),
                const SizedBox(width: BatshSpacing.xxs),
                Text(
                  context.l10n.homeLiveUnreadCount(count),
                  style: BatshTypography.labelSm.copyWith(
                    color: context.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RequestTimeline extends StatelessWidget {
  const _RequestTimeline({required this.steps, required this.activeStep});

  final List<String> steps;
  final int activeStep;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < steps.length; index++) ...[
          Expanded(
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: index < activeStep
                        ? scheme.primary
                        : scheme.surfaceContainerHigh,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: index < activeStep
                          ? scheme.primary
                          : scheme.outlineVariant,
                    ),
                  ),
                  child: index < activeStep
                      ? Icon(
                          Icons.check_rounded,
                          size: 15,
                          color: scheme.onPrimary,
                        )
                      : null,
                ),
                const SizedBox(height: BatshSpacing.xs),
                Text(
                  steps[index],
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: BatshTypography.labelSm.copyWith(
                    color: index < activeStep
                        ? scheme.onSurface
                        : scheme.onSurfaceVariant,
                    fontWeight: index < activeStep
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          if (index != steps.length - 1)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 11),
                child: Divider(
                  color: index < activeStep - 1
                      ? scheme.primary
                      : scheme.outlineVariant,
                  thickness: 1.5,
                ),
              ),
            ),
        ],
      ],
    );
  }
}
