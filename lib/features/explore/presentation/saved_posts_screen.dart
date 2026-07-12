import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/widgets/batsh_empty_state.dart';
import '../../../core/widgets/batsh_scaffold.dart';
import '../../../core/widgets/batsh_shimmer.dart';
import 'providers/explore_providers.dart';
import 'widgets/post_card.dart';

class SavedPostsScreen extends ConsumerWidget {
  const SavedPostsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(savedPostsProvider);

    return BatshScaffold(
      title: S.savedPosts,
      body: posts.when(
        loading: () => const BatshListSkeleton(count: 3),
        error: (e, _) => BatshEmptyState(
          title: S.unknownErrorRetry,
          icon: Icons.error_outline,
        ),
        data: (list) {
          if (list.isEmpty) {
            return BatshEmptyState(
              title: S.savedPostsEmpty,
              icon: Icons.bookmark_border,
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
