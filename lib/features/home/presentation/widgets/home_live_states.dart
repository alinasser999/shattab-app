import '../../../quotes/presentation/providers/quotes_providers.dart';
import '../../../../core/widgets/batsh_loading.dart';
import '../../../../core/widgets/professional_reference_states.dart';
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
      return Padding(padding: EdgeInsets.all(24), child: const BatshLoading());
    }
    if (briefs.hasError) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: inset),
        child: ProfessionalReferenceReadError(
          message: ErrorMapper.map(briefs.error!),
          onRetry: () => ref.invalidate(myBriefsProvider),
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
    final quoteState = current == null
        ? null
        : ref.watch(quotesForBriefProvider(current.id));
    final latest = notifications.asData?.value.firstOrNull;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: inset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (child != null)
            child!
          else if (current == null)
            ProfessionalReferenceState(
              title: context.l10n.homeLiveEmptyTitle,
              message: context.l10n.homeLiveEmptyMessage,
              motif: ProfessionalReferenceMotif.house,
              primaryLabel: context.l10n.homeLiveStartAction,
              onPrimary: onStartRequest,
            )
          else
            _UpdateState(
              title: context.l10n.homeLiveActivityTitle,
              message: current.projectTitle ?? current.workDescription,
              action: context.l10n.homeLiveOpenRequests,
              onAction: () => onOpenRequests(),
            ),
          if (current != null && quoteState!.isLoading) ...[
            const Padding(padding: EdgeInsets.all(24), child: BatshLoading()),
          ] else if (current != null && quoteState!.hasError) ...[
            ProfessionalReferenceReadError(
              message: ErrorMapper.map(quoteState.error!),
              onRetry: () => ref.invalidate(quotesForBriefProvider(current.id)),
            ),
          ],
          if (notifications.isLoading) ...[
            const SizedBox(height: 12),
            Semantics(
              label: context.l10n.loading,
              liveRegion: true,
              child: const LinearProgressIndicator(
                color: ProfessionalReferenceTheme.navy,
              ),
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
  });
  final String title, message, action;
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
      ],
    ),
  );
}
