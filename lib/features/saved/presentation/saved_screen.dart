import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/batsh_colors.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/widgets/batsh_button.dart';
import '../../../core/widgets/batsh_empty_state.dart';
import '../../../core/widgets/batsh_error.dart';
import '../../../core/widgets/batsh_scaffold.dart';
import '../../../core/widgets/batsh_shimmer.dart';
import '../../../core/widgets/contractor_card.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../auth/presentation/sign_in_sheet.dart';
import 'providers/saved_providers.dart';
import '../../../core/theme/batsh_motion.dart';

class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(savedContractorsProvider);
    final isGuest = ref.watch(currentSessionProvider) == null;

    return BatshScaffold(
      title: S.tabSaved,
      body: async.when(
        loading: () => const BatshListSkeleton(),
        error: (e, _) => BatshError(
          message: ErrorMapper.map(e),
          onRetry: () => ref.invalidate(savedContractorsProvider),
        ),
        data: (list) {
          return RefreshIndicator(
            backgroundColor: BatshColors.surface,
            onRefresh: () async => ref.invalidate(savedContractorsProvider),
            child: list.isEmpty
                ? LayoutBuilder(
                    builder: (context, constraints) => ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        // Fill the viewport so BatshEmptyState's internal Center
                        // truly centers instead of collapsing to the top.
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: isGuest
                              ? BatshEmptyState(
                                  title: S.signInToSeeSaved,
                                  message: S.signInEmptyMessage,
                                  icon: Icons.bookmark_border,
                                  action: BatshButton(
                                    label: S.signInSheetTitle,
                                    onPressed: () => showSignInSheet(
                                      context,
                                      reason: S.signInToSeeSaved,
                                    ),
                                  ),
                                )
                              : BatshEmptyState(
                                  title: S.noSavedContractors,
                                  message: S.noSavedContractorsMsg,
                                  icon: Icons.bookmark_border,
                                ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      vertical: BatshSpacing.md,
                    ),
                    itemCount: list.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: BatshSpacing.md),
                    itemBuilder: (context, i) {
                      final c = list[i];
                      final reduced = MediaQuery.disableAnimationsOf(context);
                      final card = ContractorCard(
                        listing: c,
                        isSaved: true,
                        onToggleSave: () => ref
                            .read(savedControllerProvider.notifier)
                            .toggle(c.id),
                        onTap: () => context.push(
                          Routes.homeownerContractorProfilePath(c.id),
                        ),
                      );
                      return reduced
                          ? card
                          : card
                                .animate()
                                .fadeIn(
                                  duration: 260.ms,
                                  delay: (60 * i.clamp(0, 7)).ms,
                                )
                                .slideY(
                                  begin: 0.06,
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
