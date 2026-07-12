import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/widgets/batsh_button.dart';
import '../../../core/widgets/batsh_empty_state.dart';
import '../../../core/widgets/batsh_loading.dart';
import '../../../core/widgets/batsh_scaffold.dart';
import '../../../core/widgets/batsh_shimmer.dart';
import '../../auth/presentation/sign_in_sheet.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import 'providers/explore_providers.dart';
import 'widgets/post_card.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(exploreFeedProvider.notifier).loadMore();
    }
  }

  String _explorePrefix() {
    final location = GoRouterState.of(context).matchedLocation;
    return location.startsWith('/c/')
        ? Routes.contractorExplore
        : Routes.homeownerExplore;
  }

  void _ensureAuth(BuildContext context, VoidCallback action) {
    final session = ref.read(currentSessionProvider);
    if (session != null) {
      action();
    } else {
      runSignedIn(context, ref, reason: S.signInToPost, action: action);
    }
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(exploreFeedProvider);
    final session = ref.watch(currentSessionProvider);

    return BatshScaffold(
      title: S.exploreTitle,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _ensureAuth(context, () => context.push('${_explorePrefix()}/new'));
        },
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(exploreFeedProvider.notifier).refresh(),
        child: feed.when(
          loading: () => const BatshListSkeleton(count: 4),
          error: (e, _) => BatshEmptyState(
            title: S.unknownErrorRetry,
            action: BatshButton(
              label: S.retry,
              onPressed: () => ref.read(exploreFeedProvider.notifier).refresh(),
            ),
          ),
          data: (posts) {
            if (posts.isEmpty) {
              return BatshEmptyState(
                title: S.noPostsYet,
                message: S.noPostsYetSub,
                icon: Icons.explore_outlined,
                action: session != null
                    ? BatshButton(
                        label: S.createPost,
                        onPressed: () => context.push('${_explorePrefix()}/new'),
                      )
                    : null,
              );
            }
            final hasMore = ref.read(exploreFeedProvider.notifier).hasMore;
            return ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.all(BatshSpacing.gutter),
              itemCount: posts.length + (hasMore ? 1 : 0),
              separatorBuilder: (_, __) =>
                  const SizedBox(height: BatshSpacing.gutter),
              itemBuilder: (_, i) {
                if (i == posts.length) {
                  return const Padding(
                    padding: EdgeInsets.all(BatshSpacing.gutter),
                    child: BatshLoading(),
                  );
                }
                return PostCard(
                  key: ValueKey(posts[i].id),
                  post: posts[i],
                  index: i,
                  onTap: () =>
                      context.push('${_explorePrefix()}/post/${posts[i].id}'),
                  onLike: () {
                    _ensureAuth(context, () {
                      ref.read(postControllerProvider.notifier)
                          .toggleLike(posts[i]);
                    });
                  },
                  onSave: () {
                    _ensureAuth(context, () {
                      ref.read(postControllerProvider.notifier)
                          .toggleSave(posts[i]);
                    });
                  },
                  onProfileTap: () {
                    // Contractor profiles live under /h/discover; the role
                    // guard bounces contractors off /h, so only homeowners
                    // (and guests) can open them.
                    if (posts[i].authorRole == 'contractor' &&
                        !_explorePrefix().startsWith('/c')) {
                      context.push(
                        '/h/discover/contractor/${posts[i].authorId}',
                      );
                    }
                  },
                  onCommentTap: () =>
                      context.push('${_explorePrefix()}/post/${posts[i].id}'),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
