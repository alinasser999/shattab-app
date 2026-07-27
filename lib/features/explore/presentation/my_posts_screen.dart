import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/strings.dart';
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
      title: S.myPosts,
      body: posts.when(
        loading: () => const BatshListSkeleton(count: 3),
        error: (e, _) =>
            BatshError(onRetry: () => ref.invalidate(myPostsProvider)),
        data: (list) {
          if (list.isEmpty) {
            return BatshEmptyState(
              title: S.myPostsEmpty,
              message: S.myPostsEmptySub,
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
