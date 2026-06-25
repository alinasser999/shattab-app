import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/widgets/batsh_empty_state.dart';
import '../../../../core/widgets/batsh_error.dart';
import '../../../../core/widgets/batsh_loading.dart';
import '../../../../core/widgets/batsh_scaffold.dart';
import '../../../../core/widgets/brief_card.dart';
import '../providers/briefs_providers.dart';

class JobOpportunitiesScreen extends ConsumerWidget {
  const JobOpportunitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(contractorOpportunitiesProvider);

    return BatshScaffold(
      title: 'فرص شغل',
      body: async.when(
        loading: () => const BatshLoading(),
        error: (e, _) => BatshError(
            message: e.toString(),
            onRetry: () => ref.invalidate(contractorOpportunitiesProvider)),
        data: (list) {
          if (list.isEmpty) {
            return const BatshEmptyState(
              title: 'مفيش بوستات دلوقتي',
              message:
                  'لو في عملاء بدورين على شغلك هتلاقي بوستاتهم هنا فور ما تتنشر.',
              icon: Icons.work_outline,
            );
          }
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(contractorOpportunitiesProvider),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: BatshSpacing.md),
              itemCount: list.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: BatshSpacing.md),
              itemBuilder: (context, i) {
                final b = list[i];
                return BriefCard(
                  brief: b,
                  onTap: () =>
                      context.push(Routes.contractorPostDetailPath(b.id)),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
