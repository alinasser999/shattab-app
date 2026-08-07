import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/batsh_motion.dart';
import '../../../core/theme/batsh_radius.dart';
import '../../../core/theme/batsh_shadows.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/theme/batsh_typography.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../core/widgets/batsh_button.dart';
import '../../../core/widgets/batsh_error.dart';
import '../../../core/widgets/batsh_scaffold.dart';
import '../../../core/widgets/batsh_shimmer.dart';
import '../../../core/widgets/contractor_card.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../auth/presentation/sign_in_sheet.dart';
import 'providers/saved_providers.dart';

import 'package:batsh/core/theme/theme_extension.dart';

class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(savedContractorsProvider);
    final isGuest = ref.watch(currentSessionProvider) == null;

    return BatshScaffold(
      title: context.l10n.tabSaved,
      padding: EdgeInsets.zero,
      animateEntrance: false,
      body: async.when(
        loading: () => const BatshListSkeleton(count: 3),
        error: (e, _) => BatshError(
          message: ErrorMapper.map(e),
          onRetry: () => ref.invalidate(savedContractorsProvider),
        ),
        data: (list) {
          return RefreshIndicator(
            backgroundColor: context.colorScheme.surfaceContainerLowest,
            onRefresh: () async => ref.invalidate(savedContractorsProvider),
            child: list.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      BatshSpacing.md,
                      BatshSpacing.sm,
                      BatshSpacing.md,
                      128,
                    ),
                    children: [
                      _SavedEmptyState(
                        isGuest: isGuest,
                        onDiscover: () => context.go(Routes.homeownerDiscover),
                        onSignIn: () => showSignInSheet(
                          context,
                          reason: context.l10n.signInToSeeSaved,
                        ),
                        onBackToAccount: () =>
                            context.go(Routes.homeownerProfile),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      BatshSpacing.md,
                      BatshSpacing.sm,
                      BatshSpacing.md,
                      128,
                    ),
                    itemCount: list.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: BatshSpacing.sm),
                    itemBuilder: (context, i) {
                      final contractor = list[i];
                      final reduced = MediaQuery.disableAnimationsOf(context);
                      final card = ContractorCard(
                        key: ValueKey(contractor.id),
                        listing: contractor,
                        isSaved: true,
                        onToggleSave: () => ref
                            .read(savedControllerProvider.notifier)
                            .toggle(contractor.id),
                        onTap: () => context.push(
                          Routes.homeownerContractorProfilePath(contractor.id),
                        ),
                      );
                      if (reduced) return card;
                      return card
                          .animate(delay: (55 * i.clamp(0, 6)).ms)
                          .fadeIn(duration: 240.ms, curve: BatshMotion.easeOut)
                          .slideY(begin: 0.03, end: 0);
                    },
                  ),
          );
        },
      ),
    );
  }
}

class _SavedEmptyState extends StatelessWidget {
  const _SavedEmptyState({
    required this.isGuest,
    required this.onDiscover,
    required this.onSignIn,
    required this.onBackToAccount,
  });

  final bool isGuest;
  final VoidCallback onDiscover;
  final VoidCallback onSignIn;
  final VoidCallback onBackToAccount;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerLowest,
        borderRadius: BatshRadius.brXxl,
        border: Border.all(
          color: context.colorScheme.outlineVariant.withValues(alpha: 0.62),
        ),
        boxShadow: BatshShadows.soft,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          BatshSpacing.lg,
          BatshSpacing.xl,
          BatshSpacing.lg,
          BatshSpacing.lg,
        ),
        child: Column(
          children: [
            CustomPaint(
              size: const Size(180, 150),
              painter: _SavedEmptyIllustrationPainter(
                color: context.colorScheme.primary,
              ),
            ),
            Text(
              isGuest
                  ? context.l10n.signInToSeeSaved
                  : context.l10n.homeownerSavedEmptyTitle,
              textAlign: TextAlign.center,
              style: BatshTypography.headlineSm.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: BatshSpacing.xs),
            Text(
              isGuest
                  ? context.l10n.signInEmptyMessage
                  : context.l10n.homeownerSavedEmptyMessage,
              textAlign: TextAlign.center,
              style: BatshTypography.bodySm.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: BatshSpacing.lg),
            BatshButton(
              label: isGuest
                  ? context.l10n.signInSheetTitle
                  : context.l10n.homeownerSavedDiscoverAction,
              onPressed: isGuest ? onSignIn : onDiscover,
            ),
            const SizedBox(height: BatshSpacing.xs),
            TextButton(
              onPressed: onBackToAccount,
              child: Text(context.l10n.homeownerOrdersBackToAccount),
            ),
            if (!isGuest) ...[
              const SizedBox(height: BatshSpacing.md),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: context.colorScheme.surfaceContainerLow,
                  borderRadius: BatshRadius.brLg,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(BatshSpacing.sm),
                  child: Row(
                    children: [
                      Icon(
                        Icons.bookmark_border,
                        color: context.colorScheme.primary,
                      ),
                      const SizedBox(width: BatshSpacing.sm),
                      Expanded(
                        child: Text(
                          context.l10n.homeownerSavedHint,
                          style: BatshTypography.labelSm.copyWith(
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SavedEmptyIllustrationPainter extends CustomPainter {
  const _SavedEmptyIllustrationPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final ink = Paint()
      ..color = color.withValues(alpha: 0.78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final soft = Paint()
      ..color = color.withValues(alpha: 0.09)
      ..style = PaintingStyle.fill;
    final bookmark = Path()
      ..moveTo(size.width * 0.32, 20)
      ..lineTo(size.width * 0.68, 20)
      ..lineTo(size.width * 0.68, 116)
      ..lineTo(size.width * 0.50, 96)
      ..lineTo(size.width * 0.32, 116)
      ..close();
    canvas.drawPath(bookmark, soft);
    canvas.drawPath(bookmark, ink);
    canvas.drawLine(
      Offset(size.width * 0.18, 126),
      Offset(size.width * 0.82, 126),
      ink,
    );
    canvas.drawLine(
      Offset(size.width * 0.22, 136),
      Offset(size.width * 0.78, 136),
      ink,
    );
    canvas.drawCircle(Offset(size.width * 0.2, 44), 14, soft);
    canvas.drawCircle(Offset(size.width * 0.8, 58), 18, soft);
  }

  @override
  bool shouldRepaint(covariant _SavedEmptyIllustrationPainter oldDelegate) =>
      oldDelegate.color != color;
}
