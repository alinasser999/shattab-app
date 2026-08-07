import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/batsh_motion.dart';
import '../../../../core/theme/batsh_radius.dart';
import '../../../../core/theme/batsh_shadows.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../../core/widgets/batsh_button.dart';
import '../../../../core/widgets/batsh_error.dart';
import '../../../../core/widgets/batsh_scaffold.dart';
import '../../../../core/widgets/batsh_shimmer.dart';
import '../../../../core/widgets/brief_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/sign_in_sheet.dart';
import '../../domain/brief.dart';
import '../providers/briefs_providers.dart';

import 'package:batsh/core/theme/theme_extension.dart';

enum _OrderFilter { all, newOrders, active, completed }

class MyBriefsScreen extends ConsumerStatefulWidget {
  const MyBriefsScreen({super.key});

  @override
  ConsumerState<MyBriefsScreen> createState() => _MyBriefsScreenState();
}

class _MyBriefsScreenState extends ConsumerState<MyBriefsScreen> {
  _OrderFilter _filter = _OrderFilter.all;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(myBriefsProvider);
    final isGuest = ref.watch(currentSessionProvider) == null;

    return BatshScaffold(
      title: context.l10n.tabRequests,
      padding: EdgeInsets.zero,
      animateEntrance: false,
      body: async.when(
        loading: () => const BatshListSkeleton(count: 3),
        error: (e, _) => BatshError(
          message: ErrorMapper.map(e),
          onRetry: () => ref.invalidate(myBriefsProvider),
        ),
        data: (list) {
          final filtered = _filterBriefs(list);
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myBriefsProvider),
            backgroundColor: context.colorScheme.surfaceContainerLowest,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                BatshSpacing.md,
                BatshSpacing.sm,
                BatshSpacing.md,
                128,
              ),
              children: [
                _OrderFilterBar(
                  selected: _filter,
                  onChanged: (next) => setState(() => _filter = next),
                ),
                const SizedBox(height: BatshSpacing.md),
                if (filtered.isEmpty)
                  _HomeownerOrdersEmpty(
                    isGuest: isGuest,
                    filtered: list.isNotEmpty,
                    onDiscover: () => context.go(Routes.homeownerDiscover),
                    onBackToAccount: () => context.go(Routes.homeownerProfile),
                    onSignIn: () => showSignInSheet(
                      context,
                      reason: context.l10n.signInToSeeRequests,
                    ),
                    onCreate: isGuest
                        ? null
                        : () => context.push(Routes.homeownerNewPost),
                  )
                else ...[
                  Semantics(
                    header: true,
                    child: Text(
                      context.l10n.tabRequests,
                      style: BatshTypography.titleLg.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: BatshSpacing.sm),
                  for (var i = 0; i < filtered.length; i++) ...[
                    BriefCard(
                          key: ValueKey(filtered[i].id),
                          brief: filtered[i],
                          onTap: () => context.push(
                            Routes.homeownerBriefDetailPath(filtered[i].id),
                          ),
                        )
                        .animate(delay: (45 * i.clamp(0, 6)).ms)
                        .fadeIn(duration: 240.ms, curve: BatshMotion.easeOut)
                        .slideY(begin: 0.03, end: 0),
                    const SizedBox(height: BatshSpacing.sm),
                  ],
                  if (!isGuest)
                    OutlinedButton.icon(
                      onPressed: () => context.push(Routes.homeownerNewPost),
                      icon: const Icon(Icons.add_rounded),
                      label: Text(context.l10n.createNewPostButton),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        foregroundColor: context.colorScheme.primary,
                        side: BorderSide(color: context.colorScheme.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BatshRadius.brLg,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  List<Brief> _filterBriefs(List<Brief> briefs) {
    return switch (_filter) {
      _OrderFilter.all => briefs,
      _OrderFilter.newOrders =>
        briefs.where((brief) => brief.stage == BriefStage.open).toList(),
      _OrderFilter.active =>
        briefs
            .where(
              (brief) =>
                  brief.stage == BriefStage.hired ||
                  brief.stage == BriefStage.completionRequested,
            )
            .toList(),
      _OrderFilter.completed =>
        briefs
            .where(
              (brief) =>
                  brief.stage == BriefStage.completed ||
                  brief.status == BriefStatus.cancelled,
            )
            .toList(),
    };
  }
}

class _OrderFilterBar extends StatelessWidget {
  const _OrderFilterBar({required this.selected, required this.onChanged});

  final _OrderFilter selected;
  final ValueChanged<_OrderFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = [
      (_OrderFilter.all, context.l10n.homeownerOrdersAll),
      (_OrderFilter.newOrders, context.l10n.homeownerOrdersNew),
      (_OrderFilter.active, context.l10n.homeownerOrdersActive),
      (_OrderFilter.completed, context.l10n.homeownerOrdersCompleted),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerLowest,
        borderRadius: BatshRadius.brFull,
        border: Border.all(
          color: context.colorScheme.outlineVariant.withValues(alpha: 0.68),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
          children: [
            for (final option in options)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: option.$1 == selected,
                  label: option.$2,
                  child: InkWell(
                    onTap: () => onChanged(option.$1),
                    borderRadius: BatshRadius.brFull,
                    child: AnimatedContainer(
                      duration: BatshMotion.fast,
                      constraints: const BoxConstraints(minHeight: 40),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: option.$1 == selected
                            ? context.colorScheme.primary
                            : Colors.transparent,
                        borderRadius: BatshRadius.brFull,
                      ),
                      child: Text(
                        option.$2,
                        style: BatshTypography.labelMd.copyWith(
                          color: option.$1 == selected
                              ? context.colorScheme.onPrimary
                              : context.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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

class _HomeownerOrdersEmpty extends StatelessWidget {
  const _HomeownerOrdersEmpty({
    required this.isGuest,
    required this.filtered,
    required this.onDiscover,
    required this.onBackToAccount,
    required this.onSignIn,
    required this.onCreate,
  });

  final bool isGuest;
  final bool filtered;
  final VoidCallback onDiscover;
  final VoidCallback onBackToAccount;
  final VoidCallback onSignIn;
  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    final title = filtered
        ? context.l10n.homeownerOrdersEmptyTitle
        : isGuest
        ? context.l10n.signInToSeeRequests
        : context.l10n.homeownerOrdersEmptyTitle;
    final message = filtered
        ? context.l10n.homeownerOrdersEmptyMessage
        : isGuest
        ? context.l10n.signInEmptyMessage
        : context.l10n.homeownerOrdersEmptyMessage;

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
              size: const Size(170, 150),
              painter: _OrderEmptyIllustrationPainter(
                color: context.colorScheme.primary,
              ),
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: BatshTypography.headlineSm.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: BatshSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: BatshTypography.bodySm.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: BatshSpacing.lg),
            if (isGuest)
              BatshButton(
                label: context.l10n.signInSheetTitle,
                onPressed: onSignIn,
              )
            else
              BatshButton(
                label: context.l10n.homeownerOrdersDiscoverAction,
                onPressed: onDiscover,
              ),
            const SizedBox(height: BatshSpacing.xs),
            TextButton(
              onPressed: onCreate ?? onBackToAccount,
              child: Text(
                onCreate == null
                    ? context.l10n.homeownerOrdersBackToAccount
                    : context.l10n.createNewPostButton,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderEmptyIllustrationPainter extends CustomPainter {
  const _OrderEmptyIllustrationPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final ink = Paint()
      ..color = color.withValues(alpha: 0.78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final soft = Paint()
      ..color = color.withValues(alpha: 0.10)
      ..style = PaintingStyle.fill;
    final board = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.22, 26, size.width * 0.56, 98),
      const Radius.circular(8),
    );
    canvas.drawRRect(board, soft);
    canvas.drawRRect(board, ink);
    canvas.drawLine(
      Offset(size.width * 0.31, 46),
      Offset(size.width * 0.69, 46),
      ink,
    );
    for (var i = 0; i < 3; i++) {
      final y = 66 + i * 18.0;
      canvas.drawLine(
        Offset(size.width * 0.32, y),
        Offset(size.width * (0.52 + i * 0.05), y),
        ink,
      );
    }
    final arch = Path()
      ..moveTo(size.width * 0.35, 112)
      ..lineTo(size.width * 0.35, 86)
      ..quadraticBezierTo(size.width * 0.35, 70, size.width * 0.45, 70)
      ..quadraticBezierTo(size.width * 0.55, 70, size.width * 0.55, 86)
      ..lineTo(size.width * 0.55, 112);
    canvas.drawPath(arch, ink);
    canvas.drawLine(
      Offset(size.width * 0.28, 124),
      Offset(size.width * 0.72, 124),
      ink,
    );
  }

  @override
  bool shouldRepaint(covariant _OrderEmptyIllustrationPainter oldDelegate) =>
      oldDelegate.color != color;
}
