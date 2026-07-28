import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/widgets/batsh_empty_state.dart';
import '../../../core/widgets/batsh_error.dart';
import '../../../core/widgets/batsh_scaffold.dart';
import '../../../core/widgets/batsh_shimmer.dart';
import 'providers/explore_providers.dart';
import 'widgets/post_card.dart';

class MyPostsScreen extends ConsumerWidget {
  const MyPostsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(myPostsProvider);

    return BatshScaffold(
      title: context.l10n.myPosts,
      body: posts.when(
        loading: () => const BatshListSkeleton(count: 3),
        error: (e, _) =>
            BatshError(onRetry: () => ref.invalidate(myPostsProvider)),
        data: (list) {
          if (list.isEmpty) {
            return BatshEmptyState(
              title: context.l10n.myPostsEmpty,
              message: context.l10n.myPostsEmptySub,
              icon: Icons.article_outlined,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(BatshSpacing.gutter),
            itemCount: list.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: BatshSpacing.gutter),
            itemBuilder: (_, i) => PostCard(
              post: list[i],
              onTap: () => context.push('../post/${list[i].id}'),
            ),
          );
        },
      ),
    );
  }
}
