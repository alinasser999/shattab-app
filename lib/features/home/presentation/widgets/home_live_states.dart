import '../../../../core/utils/support_contact.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/l10n_extension.dart';
import '../../../../core/theme/professional_reference_theme.dart';
import '../../../../core/utils/connectivity.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../briefs/domain/brief.dart';
import '../../../briefs/presentation/providers/briefs_providers.dart';
import '../../../notifications/presentation/providers/notifications_providers.dart';
import '../../../notifications/presentation/notification_copy.dart';

/// Preserve source errors and keep the start action independent of notifications.
class HomeLiveStateSection extends ConsumerWidget {
  const HomeLiveStateSection({
    super.key,
    required this.onOpenRequests,
    required this.onOpenNotifications,
    required this.onStartRequest,
    this.child,
    this.childHorizontalInset,
  });
  final VoidCallback onOpenRequests, onOpenNotifications, onStartRequest;
  final Widget? child;
  final double? childHorizontalInset;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final briefs = ref.watch(myBriefsProvider);
    final notifications = ref.watch(notificationsProvider);
    ref.listen(connectivityProvider, (previous, next) {
      if (previous?.value != false || next.value != true) return;
      if (briefs.hasError) ref.invalidate(myBriefsProvider);
      if (notifications.hasError) ref.invalidate(notificationsProvider);
    });
    final inset = childHorizontalInset ?? 16;
    if (briefs.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: CircularProgressIndicator(
            color: ProfessionalReferenceTheme.navy,
          ),
        ),
      );
    }
    if (briefs.hasError) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: inset),
        child: _UpdateState(
          title: context.l10n.homeLiveErrorTitle,
          message: ErrorMapper.map(briefs.error!),
          action: context.l10n.tryAgain,
          onAction: () => ref.invalidate(myBriefsProvider),
          secondaryAction: context.l10n.helpSupport,
          onSecondaryAction: () => openShattabSupport(context),
        ),
      );
    }
    final current = (briefs.asData?.value ?? const <Brief>[])
        .where(
          (brief) =>
              (brief.status == BriefStatus.open && !brief.isCompleted) ||
              brief.awaitsCompletionConfirmation,
        )
        .firstOrNull;
    final latest = notifications.asData?.value.firstOrNull;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: inset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (child != null)
            child!
          else
            _UpdateState(
              title: current == null
                  ? context.l10n.homeLiveEmptyTitle
                  : context.l10n.homeLiveActivityTitle,
              message: current == null
                  ? context.l10n.homeLiveEmptyMessage
                  : current.projectTitle ?? current.workDescription,
              action: current == null
                  ? context.l10n.homeLiveStartAction
                  : context.l10n.homeLiveOpenRequests,
              onAction: current == null ? onStartRequest : onOpenRequests,
            ),
          if (notifications.isLoading) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(
              color: ProfessionalReferenceTheme.navy,
            ),
          ],
          if (notifications.hasError) ...[
            const SizedBox(height: 12),
            _UpdateState(
              title: context.l10n.homeLiveErrorTitle,
              message: ErrorMapper.map(notifications.error!),
              action: context.l10n.tryAgain,
              onAction: () => ref.invalidate(notificationsProvider),
              compact: true,
            ),
          ] else if (latest != null) ...[
            const SizedBox(height: 12),
            _UpdateState(
              title: context.l10n.homeLiveLatestActivity,
              message:
                  '${notificationTitle(context, latest)}: ${notificationBody(context, latest)}',
              action: context.l10n.homeLiveOpenNotifications,
              onAction: onOpenNotifications,
              compact: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _UpdateState extends StatelessWidget {
  const _UpdateState({
    required this.title,
    required this.message,
    required this.action,
    required this.onAction,
    this.compact = false,
    this.secondaryAction,
    this.onSecondaryAction,
  });
  final String title, message, action;
  final String? secondaryAction;
  final VoidCallback? onSecondaryAction;
  final VoidCallback onAction;
  final bool compact;
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(compact ? 12 : 20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xffe7e5e0)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: ProfessionalReferenceTheme.text(
              compact ? 16 : 20,
              weight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: ProfessionalReferenceTheme.text(
            16,
            color: ProfessionalReferenceTheme.muted,
          ),
        ),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          child: Text(
            action,
            style: ProfessionalReferenceTheme.text(
              16,
              color: ProfessionalReferenceTheme.action,
              weight: FontWeight.w700,
            ),
          ),
        ),
        if (secondaryAction != null && onSecondaryAction != null)
          TextButton(
            onPressed: onSecondaryAction,
            child: Text(
              secondaryAction!,
              style: ProfessionalReferenceTheme.text(
                16,
                color: ProfessionalReferenceTheme.action,
                weight: FontWeight.w700,
              ),
            ),
          ),
      ],
    ),
  );
}
