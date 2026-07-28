import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/batsh_colors.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/widgets/batsh_button.dart';
import '../../../../core/widgets/batsh_empty_state.dart';
import '../../../../core/widgets/batsh_error.dart';
import '../../../../core/widgets/batsh_scaffold.dart';
import '../../../../core/widgets/batsh_shimmer.dart';
import '../../../../core/widgets/brief_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/sign_in_sheet.dart';
import '../providers/briefs_providers.dart';

import 'package:batsh/core/theme/theme_extension.dart';

class MyBriefsScreen extends ConsumerWidget {
  const MyBriefsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myBriefsProvider);
    final isGuest = ref.watch(currentSessionProvider) == null;

    return BatshScaffold(
      title: context.l10n.tabRequests,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.homeownerNewPost),
        backgroundColor: context.colorScheme.primary,
        foregroundColor: context.colorScheme.onPrimary,
        icon: const Icon(Icons.add),
        label: Text(context.l10n.createNewPostButton),
      ),
      body: async.when(
        loading: () => const BatshListSkeleton(),
        error: (e, _) => BatshError(
          message: ErrorMapper.map(e),
          onRetry: () => ref.invalidate(myBriefsProvider),
        ),
        data: (list) {
          final posts = list.where((b) => b.isPost).toList();
          final direct = list.where((b) => !b.isPost).toList();
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myBriefsProvider),
            child: list.isEmpty
                ? ListView(
                    children: [
                      isGuest
                          ? BatshEmptyState(
                              title: context.l10n.signInToSeeRequests,
                              message: context.l10n.signInEmptyMessage,
                              icon: Icons.assignment_outlined,
                              action: BatshButton(
                                label: context.l10n.signInSheetTitle,
                                onPressed: () => showSignInSheet(
                                  context,
                                  reason: context.l10n.signInToSeeRequests,
                                ),
                              ),
                            )
                          : BatshEmptyState(
                              title: context.l10n.noBriefsHere,
                              message: context.l10n.noBriefsHereMessage,
                              icon: Icons.assignment_outlined,
                            ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.only(bottom: 80),
                    children: [
                      if (posts.isNotEmpty) ...[
                        const SizedBox(height: BatshSpacing.md),
                        _Section(context.l10n.sectionOpenPosts),
                        const SizedBox(height: BatshSpacing.sm),
                        for (final b in posts) ...[
                          BriefCard(
                            brief: b,
                            onTap: () => context.push(
                              Routes.homeownerBriefDetailPath(b.id),
                            ),
                          ),
                          const SizedBox(height: BatshSpacing.md),
                        ],
                      ],
                      if (direct.isNotEmpty) ...[
                        const SizedBox(height: BatshSpacing.md),
                        _Section(context.l10n.sectionDirectRequests),
                        const SizedBox(height: BatshSpacing.sm),
                        for (final b in direct) ...[
                          BriefCard(
                            brief: b,
                            onTap: () => context.push(
                              Routes.homeownerBriefDetailPath(b.id),
                            ),
                          ),
                          const SizedBox(height: BatshSpacing.md),
                        ],
                      ],
                    ],
                  ),
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.label);
  final String label;
  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: BatshTypography.titleLg.copyWith(
        color: context.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
