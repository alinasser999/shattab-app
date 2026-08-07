import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../core/analytics/app_analytics.dart';
import '../../../core/theme/batsh_icon_size.dart';
import '../../../core/theme/batsh_radius.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/theme/batsh_typography.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../core/widgets/batsh_empty_state.dart';
import '../../../core/widgets/batsh_error.dart';
import '../../../core/widgets/batsh_loading.dart';
import '../../../core/widgets/batsh_snack.dart';
import '../../../core/widgets/notification_preferences_sheet.dart';
import '../../auth/domain/profile.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../../core/router/routes.dart';
import '../domain/app_notification.dart';
import 'providers/notifications_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.notificationInboxTitle),
        actions: [
          IconButton(
            tooltip: context.l10n.notificationMarkAllRead,
            onPressed: notifications.maybeWhen(
              data: (items) => items.any((item) => !item.isRead)
                  ? () => _markAllRead(context, ref)
                  : null,
              orElse: () => null,
            ),
            icon: const Icon(Icons.done_all_rounded),
          ),
          IconButton(
            tooltip: context.l10n.notificationsTitle,
            onPressed: () => showNotificationPreferencesSheet(context),
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: notifications.when(
        loading: () => const BatshLoading(),
        error: (error, _) => BatshError(
          message: ErrorMapper.map(error),
          onRetry: () => ref.invalidate(notificationsProvider),
        ),
        data: (items) => items.isEmpty
            ? BatshEmptyState(
                icon: Icons.notifications_none_rounded,
                title: context.l10n.notificationEmptyTitle,
                message: context.l10n.notificationEmptyBody,
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(notificationsProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    BatshSpacing.gutter,
                    BatshSpacing.sm,
                    BatshSpacing.gutter,
                    BatshSpacing.xxl,
                  ),
                  itemCount: items.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: BatshSpacing.xs),
                  itemBuilder: (context, index) => _NotificationTile(
                    item: items[index],
                    onTap: () => _openNotification(context, ref, items[index]),
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _markAllRead(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(notificationsControllerProvider.notifier).markAllRead();
      unawaited(AppAnalytics.track('notifications_marked_read'));
    } catch (error) {
      if (context.mounted) {
        BatshSnack.error(context, ErrorMapper.map(error));
      }
    }
  }

  Future<void> _openNotification(
    BuildContext context,
    WidgetRef ref,
    AppNotification item,
  ) async {
    if (!item.isRead) {
      unawaited(
        ref.read(notificationsControllerProvider.notifier).markRead(item.id),
      );
    }
    unawaited(
      AppAnalytics.track(
        'notification_opened',
        properties: {'kind': item.kind},
      ),
    );
    final entityId = item.entityId;
    if (entityId == null || !context.mounted) return;

    final role = ref.read(currentProfileProvider).value?.role;
    if (item.entityType == 'brief') {
      context.push(
        role == UserRole.contractor
            ? Routes.contractorPostDetailPath(entityId)
            : Routes.homeownerBriefDetailPath(entityId),
      );
    } else if (item.entityType == 'post') {
      context.push(
        role == UserRole.contractor
            ? Routes.contractorCommunityPostPath(entityId)
            : Routes.homeownerCommunityPostPath(entityId),
      );
    }
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});

  final AppNotification item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = item.isRead
        ? context.colorScheme.onSurfaceVariant
        : context.colorScheme.primary;
    return Semantics(
      button: true,
      label: '${_title(context)}. ${_body(context)}',
      child: Material(
        color: item.isRead
            ? context.colorScheme.surfaceContainerLowest
            : context.colorScheme.primaryContainer.withValues(alpha: 0.32),
        borderRadius: BatshRadius.brCard,
        child: InkWell(
          onTap: onTap,
          borderRadius: BatshRadius.brCard,
          child: Padding(
            padding: const EdgeInsets.all(BatshSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: context.colorScheme.surface,
                    borderRadius: BatshRadius.brMd,
                  ),
                  child: Icon(_icon, color: color, size: BatshIconSize.md),
                ),
                const SizedBox(width: BatshSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _title(context),
                        style: BatshTypography.titleMd.copyWith(
                          fontWeight: item.isRead
                              ? FontWeight.w600
                              : FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: BatshSpacing.xxs),
                      Text(
                        _body(context),
                        style: BatshTypography.bodySm.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: BatshSpacing.xs),
                      Text(
                        _relativeTime(context),
                        style: BatshTypography.labelSm.copyWith(color: color),
                      ),
                    ],
                  ),
                ),
                if (!item.isRead)
                  Padding(
                    padding: const EdgeInsets.only(top: BatshSpacing.xs),
                    child: Icon(Icons.circle, size: 8, color: color),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData get _icon => switch (item.kind) {
    'new_quote' => Icons.request_quote_outlined,
    'quote_accepted' => Icons.check_circle_outline,
    'quote_declined' => Icons.reply_outlined,
    'completion_requested' || 'job_completed' => Icons.handyman_outlined,
    'new_review' => Icons.star_border_rounded,
    'verification_approved' ||
    'verification_rejected' => Icons.verified_user_outlined,
    'post_liked' || 'comment_liked' => Icons.favorite_border_rounded,
    'post_commented' || 'comment_replied' => Icons.chat_bubble_outline_rounded,
    _ => Icons.notifications_none_rounded,
  };

  String _title(BuildContext context) => switch (item.titleKey) {
    'notificationNewQuoteTitle' => context.l10n.notificationNewQuoteTitle,
    'notificationQuoteDecisionTitle' =>
      context.l10n.notificationQuoteDecisionTitle,
    'notificationCompletionTitle' => context.l10n.notificationCompletionTitle,
    'notificationNewReviewTitle' => context.l10n.notificationNewReviewTitle,
    'notificationVerificationTitle' =>
      context.l10n.notificationVerificationTitle,
    'notificationPaymentTitle' => context.l10n.notificationPaymentTitle,
    'notificationCommunityTitle' => context.l10n.notificationCommunityTitle,
    _ => context.l10n.notificationsTitle,
  };

  String _body(BuildContext context) => switch (item.bodyKey) {
    'notificationNewQuoteBody' => context.l10n.notificationNewQuoteBody,
    'notificationQuoteAcceptedBody' =>
      context.l10n.notificationQuoteAcceptedBody,
    'notificationQuoteDeclinedBody' =>
      context.l10n.notificationQuoteDeclinedBody,
    'notificationCompletionRequestedBody' =>
      context.l10n.notificationCompletionRequestedBody,
    'notificationJobCompletedBody' => context.l10n.notificationJobCompletedBody,
    'notificationNewReviewBody' => context.l10n.notificationNewReviewBody,
    'notificationVerificationApprovedBody' =>
      context.l10n.notificationVerificationApprovedBody,
    'notificationVerificationRejectedBody' =>
      context.l10n.notificationVerificationRejectedBody,
    'notificationPaymentApprovedBody' =>
      context.l10n.notificationPaymentApprovedBody,
    'notificationPaymentRejectedBody' =>
      context.l10n.notificationPaymentRejectedBody,
    'notificationPostLikedBody' => context.l10n.notificationPostLikedBody,
    'notificationPostCommentedBody' =>
      context.l10n.notificationPostCommentedBody,
    'notificationCommentRepliedBody' =>
      context.l10n.notificationCommentRepliedBody,
    'notificationCommentLikedBody' =>
      context.l10n.notificationCommentLikedBody,
    _ => context.l10n.notificationsSubtitle,
  };

  String _relativeTime(BuildContext context) {
    final elapsed = DateTime.now().difference(item.createdAt.toLocal());
    if (elapsed.inMinutes < 1) return context.l10n.agoNow;
    if (elapsed.inHours < 1) return context.l10n.minsAgo(elapsed.inMinutes);
    if (elapsed.inDays < 1) {
      return elapsed.inHours == 1
          ? context.l10n.hourAgo(1)
          : context.l10n.hoursAgo(elapsed.inHours);
    }
    return elapsed.inDays == 1
        ? context.l10n.dayAgo(1)
        : context.l10n.daysAgo(elapsed.inDays);
  }
}
