import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/batsh_colors.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/widgets/batsh_empty_state.dart';
import '../../../../core/widgets/batsh_error.dart';
import '../../../../core/widgets/batsh_loading.dart';
import '../../../../core/widgets/batsh_scaffold.dart';
import '../../../../core/widgets/brief_card.dart';
import '../providers/briefs_providers.dart';

class MyBriefsScreen extends ConsumerWidget {
  const MyBriefsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myBriefsProvider);

    return BatshScaffold(
      title: S.tabRequests,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.homeownerNewPost),
        backgroundColor: BatshColors.primary,
        foregroundColor: BatshColors.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text('اعمل بوست جديد'),
      ),
      body: async.when(
        loading: () => const BatshLoading(),
        error: (e, _) => BatshError(
            message: e.toString(),
            onRetry: () => ref.invalidate(myBriefsProvider)),
        data: (list) {
          if (list.isEmpty) {
            return BatshEmptyState(
              title: 'مفيش حاجة هنا لسه',
              message:
                  'ابعت طلب لمقاول معين من صفحته، أو اعمل بوست عام والمقاولين يتواصلوا معاك.',
              icon: Icons.assignment_outlined,
            );
          }
          final posts = list.where((b) => b.isPost).toList();
          final direct = list.where((b) => !b.isPost).toList();
          return ListView(
            padding: const EdgeInsets.only(bottom: 80),
            children: [
              if (posts.isNotEmpty) ...[
                const SizedBox(height: BatshSpacing.md),
                _Section('بوستات مفتوحة'),
                const SizedBox(height: BatshSpacing.sm),
                for (final b in posts) ...[
                  BriefCard(
                      brief: b,
                      onTap: () => context.push(
                          Routes.homeownerBriefDetailPath(b.id))),
                  const SizedBox(height: BatshSpacing.md),
                ],
              ],
              if (direct.isNotEmpty) ...[
                const SizedBox(height: BatshSpacing.md),
                _Section('طلبات مباشرة'),
                const SizedBox(height: BatshSpacing.sm),
                for (final b in direct) ...[
                  BriefCard(
                      brief: b,
                      onTap: () => context.push(
                          Routes.homeownerBriefDetailPath(b.id))),
                  const SizedBox(height: BatshSpacing.md),
                ],
              ],
            ],
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
    return Text(label,
        style: BatshTypography.titleLg
            .copyWith(color: BatshColors.onSurfaceVariant));
  }
}
