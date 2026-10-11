import '../../../../core/widgets/professional_reference_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/batsh_motion.dart';
import '../../../../core/theme/batsh_radius.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/utils/error_mapper.dart';
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
                    filtered: _filter != _OrderFilter.all,
                    onClear: () => setState(() => _filter = _OrderFilter.all),
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
    required this.onClear,
    required this.onDiscover,
    required this.onBackToAccount,
    required this.onSignIn,
    required this.onCreate,
  });

  final bool isGuest;
  final bool filtered;
  final VoidCallback onClear;
  final VoidCallback onDiscover;
  final VoidCallback onBackToAccount;
  final VoidCallback onSignIn;
  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ProfessionalReferenceState(
        kind: isGuest
            ? ProfessionalReferenceStateKind.access
            : filtered
            ? ProfessionalReferenceStateKind.noResults
            : ProfessionalReferenceStateKind.empty,
        motif: ProfessionalReferenceMotif.house,
        title: isGuest
            ? context.l10n.signInToSeeRequests
            : filtered
            ? context.l10n.noResultsFound
            : context.l10n.homeownerOrdersEmptyTitle,
        message: isGuest
            ? context.l10n.signInEmptyMessage
            : filtered
            ? context.l10n.stateProjectsNoResultsMessage
            : context.l10n.homeownerOrdersEmptyMessage,
        primaryLabel: isGuest
            ? context.l10n.signInSheetTitle
            : filtered
            ? context.l10n.clearFilters
            : context.l10n.homeLiveStartAction,
        onPrimary: isGuest
            ? onSignIn
            : filtered
            ? onClear
            : onCreate,
        secondaryLabel: context.l10n.homeownerOrdersDiscoverAction,
        onSecondary: onDiscover,
      ),
      TextButton(
        onPressed: onBackToAccount,
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
        child: Text(context.l10n.homeownerOrdersBackToAccount),
      ),
    ],
  );
}
