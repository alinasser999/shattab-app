import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../core/analytics/app_analytics.dart';
import '../../../core/analytics/marketplace_events.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/batsh_radius.dart';
import '../../../core/theme/batsh_shadows.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/theme/batsh_typography.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../core/widgets/batsh_bottom_nav.dart';
import '../../../core/widgets/batsh_button.dart';
import '../../../core/widgets/batsh_dialog.dart';
import '../../../core/widgets/batsh_snack.dart';
import '../../../core/widgets/batsh_shimmer.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../auth/presentation/sign_in_sheet.dart';
import '../domain/post.dart';
import 'providers/explore_providers.dart';
import '../../notifications/presentation/providers/notifications_providers.dart';
import 'widgets/community_feed_widgets.dart';
import 'widgets/post_card.dart';
import 'package:batsh/core/theme/theme_extension.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _scrollController = ScrollController();
  CommunityFeedFilter _selectedFilter = CommunityFeedFilter.all;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter < 360) {
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
      runSignedIn(
        context,
        ref,
        reason: context.l10n.signInToPost,
        action: action,
      );
    }
  }

  void _openCreatePost() {
    _ensureAuth(context, () {
      _chooseCreatePostType();
    });
  }

  Future<void> _signInForFeed() async {
    await showSignInSheet(context, reason: context.l10n.signInToInteract);
    if (!mounted) return;
    if (ref.read(currentSessionProvider) != null) {
      ref.invalidate(exploreFeedProvider);
    }
  }

  void _openTypedCreatePost(CommunityPostKind kind) {
    _ensureAuth(
      context,
      () => context.push('${_explorePrefix()}/new?type=${kind.routeValue}'),
    );
  }

  void _openPostAuthor(Post post) {
    unawaited(
      AppAnalytics.track(
        MarketplaceEvents.communityAuthorProfileOpened,
        properties: {'author_role': post.authorRole},
      ),
    );
    final onContractorSide = _explorePrefix().startsWith('/c/');
    final currentUserId = ref.read(currentSessionProvider)?.user.id;

    if (post.authorId == currentUserId) {
      context.go(
        onContractorSide ? Routes.contractorProfile : Routes.homeownerProfile,
      );
      return;
    }

    if (post.authorRole == 'contractor') {
      context.push(
        onContractorSide
            ? Routes.contractorCommunityContractorProfilePath(post.authorId)
            : Routes.homeownerContractorProfilePath(post.authorId),
      );
      return;
    }

    context.push(
      onContractorSide
          ? Routes.contractorHomeownerProfilePath(post.authorId)
          : Routes.homeownerCommunityMemberPath(post.authorId),
    );
  }

  Future<void> _chooseCreatePostType() async {
    final kind = await showModalBottomSheet<CommunityPostKind>(
      context: context,
      backgroundColor: context.colorScheme.surfaceContainerLowest,
      showDragHandle: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(BatshRadius.xxl),
        ),
      ),
      builder: (_) => const CommunityPostTypeSheet(),
    );
    if (!mounted || kind == null) return;
    context.push('${_explorePrefix()}/new?type=${kind.routeValue}');
  }

  Future<void> _openFilterSheet() async {
    final selection = await showModalBottomSheet<CommunityFeedFilter>(
      context: context,
      backgroundColor: context.colorScheme.surfaceContainerLowest,
      showDragHandle: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(BatshRadius.xxl),
        ),
      ),
      builder: (_) => CommunityFilterSheet(selected: _selectedFilter),
    );
    if (!mounted || selection == null) return;
    setState(() => _selectedFilter = selection);
  }

  Future<void> _confirmDeletePost(String postId) async {
    final ok = await BatshDialog.confirm(
      context,
      title: context.l10n.deletePost,
      message: context.l10n.deletePostConfirm,
      confirmLabel: context.l10n.deletePost,
      cancelLabel: context.l10n.cancel,
      isDestructive: true,
    );
    if (ok != true || !mounted) return;

    try {
      await ref.read(postControllerProvider.notifier).deletePost(postId);
      if (mounted) BatshSnack.success(context, context.l10n.postDeleted);
    } catch (error) {
      if (mounted) BatshSnack.error(context, ErrorMapper.map(error));
    }
  }

  List<Post> _filterPosts(List<Post> posts) {
    return posts
        .where((post) {
          switch (_selectedFilter) {
            case CommunityFeedFilter.all:
              return true;
            case CommunityFeedFilter.beforeAfter:
              return post.postType.name == 'projectShowcase';
            case CommunityFeedFilter.tips:
              return post.postType.name == 'tip';
            case CommunityFeedFilter.experiences:
              return post.postType.name == 'renovationUpdate' ||
                  post.postType.name == 'milestone';
            case CommunityFeedFilter.requests:
              // The current posts schema has no request post type. Requests are
              // still a useful reference filter, so treat milestone updates as
              // the closest existing, user-authored experience instead of making
              // a database change just for presentation.
              return post.postType.name == 'milestone';
          }
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(exploreFeedProvider);
    final profile = ref.watch(currentProfileProvider).value;
    final session = ref.watch(currentSessionProvider);
    final content = RefreshIndicator(
      color: context.colorScheme.primary,
      backgroundColor: context.colorScheme.surfaceContainerLowest,
      onRefresh: () => ref.read(exploreFeedProvider.notifier).refresh(),
      child: ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          BatshSpacing.md,
          BatshSpacing.sm,
          BatshSpacing.md,
          BatshBottomNav.contentBottomInset(context),
        ),
        children: [
          CommunityFeedHeader(
            unreadCount: ref.watch(unreadNotificationsProvider),
            onNotifications: () => context.push(Routes.notifications),
            onFilters: _openFilterSheet,
          ),
          FeedFilterChips(
            selected: _selectedFilter,
            onSelected: (filter) => setState(() => _selectedFilter = filter),
          ),
          const SizedBox(height: BatshSpacing.md),
          CreatePostComposer(
            name: profile?.fullName ?? 'م',
            avatarUrl: profile?.avatarUrl,
            onCreate: () => _openCreatePost(),
            onPhoto: () => _openTypedCreatePost(CommunityPostKind.standard),
            onBeforeAfter: () =>
                _openTypedCreatePost(CommunityPostKind.beforeAfter),
            onQuestion: () => _openTypedCreatePost(CommunityPostKind.question),
          ),
          const SizedBox(height: BatshSpacing.lg),
          feed.when(
            loading: () => const _CommunityFeedSkeleton(),
            error: (error, _) => _CommunityFeedError(
              requiresSignIn: _feedRequiresSignIn(
                error,
                isGuest: session == null,
              ),
              onRetry: () => ref.invalidate(exploreFeedProvider),
              onSignIn: _signInForFeed,
            ),
            data: (posts) {
              final visiblePosts = _filterPosts(posts);
              if (visiblePosts.isEmpty) {
                return CommunityEmptyState(
                  onClear: () =>
                      setState(() => _selectedFilter = CommunityFeedFilter.all),
                );
              }

              final hasMore = ref.read(exploreFeedProvider.notifier).hasMore;
              final paginationError = ref
                  .read(exploreFeedProvider.notifier)
                  .paginationError;
              return Column(
                children: [
                  for (var i = 0; i < visiblePosts.length; i++) ...[
                    PostCard(
                      key: ValueKey(visiblePosts[i].id),
                      post: visiblePosts[i],
                      index: i,
                      onTap: () => context.push(
                        '${_explorePrefix()}/post/${visiblePosts[i].id}',
                      ),
                      onLike: () {
                        _ensureAuth(context, () async {
                          try {
                            await ref
                                .read(postControllerProvider.notifier)
                                .toggleLike(visiblePosts[i]);
                            unawaited(
                              AppAnalytics.track(
                                MarketplaceEvents.communityPostLiked,
                                properties: {'liked': !visiblePosts[i].isLiked},
                              ),
                            );
                          } catch (error) {
                            if (context.mounted) {
                              BatshSnack.error(context, ErrorMapper.map(error));
                            }
                          }
                        });
                      },
                      onSave: () {
                        _ensureAuth(context, () async {
                          try {
                            await ref
                                .read(postControllerProvider.notifier)
                                .toggleSave(visiblePosts[i]);
                            unawaited(
                              AppAnalytics.track(
                                MarketplaceEvents.communityPostSaved,
                                properties: {'saved': !visiblePosts[i].isSaved},
                              ),
                            );
                          } catch (error) {
                            if (context.mounted) {
                              BatshSnack.error(context, ErrorMapper.map(error));
                            }
                          }
                        });
                      },
                      onProfileTap: () {
                        _openPostAuthor(visiblePosts[i]);
                      },
                      onCommentTap: () => context.push(
                        '${_explorePrefix()}/post/${visiblePosts[i].id}',
                      ),
                      isOwner: session?.user.id == visiblePosts[i].authorId,
                      onEdit: () => context.push(
                        '${_explorePrefix()}/post/${visiblePosts[i].id}',
                      ),
                      onDelete: () => _confirmDeletePost(visiblePosts[i].id),
                    ),
                    if (i != visiblePosts.length - 1)
                      const SizedBox(height: BatshSpacing.md),
                  ],
                  if (paginationError != null) ...[
                    const SizedBox(height: BatshSpacing.lg),
                    _PaginationError(
                      onRetry: () =>
                          ref.read(exploreFeedProvider.notifier).loadMore(),
                    ),
                  ] else if (hasMore) ...[
                    const SizedBox(height: BatshSpacing.lg),
                    const _PaginationHint(),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      body: Stack(
        children: [
          const Positioned.fill(child: CommunityPatternBackground()),
          SafeArea(child: content),
        ],
      ),
    );
  }
}

bool _feedRequiresSignIn(Object error, {required bool isGuest}) {
  if (!isGuest) return false;
  final message = error.toString().toLowerCase();
  return message.contains('permission') ||
      message.contains('unauthorized') ||
      message.contains('not_authorized') ||
      message.contains('jwt') ||
      message.contains('session') ||
      message.contains('invalid input syntax for type uuid');
}

class _CommunityFeedSkeleton extends StatelessWidget {
  const _CommunityFeedSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 2; i++) ...[
          Container(
            padding: const EdgeInsets.all(BatshSpacing.md),
            decoration: BoxDecoration(
              color: context.colorScheme.surfaceContainerLowest,
              borderRadius: BatshRadius.brXl,
              border: Border.all(
                color: context.colorScheme.outlineVariant.withValues(
                  alpha: 0.55,
                ),
              ),
              boxShadow: BatshShadows.soft,
            ),
            child: Column(
              children: [
                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    const BatshShimmerBox(
                      width: 44,
                      height: 44,
                      borderRadius: BatshRadius.brFull,
                    ),
                    const SizedBox(width: BatshSpacing.sm),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          BatshShimmerBox(width: double.infinity, height: 14),
                          SizedBox(height: BatshSpacing.xs),
                          BatshShimmerBox(width: 110, height: 10),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: BatshSpacing.md),
                const BatshShimmerBox(width: double.infinity, height: 16),
                const SizedBox(height: BatshSpacing.xs),
                const BatshShimmerBox(width: 190, height: 16),
                const SizedBox(height: BatshSpacing.md),
                const BatshShimmerBox(
                  width: double.infinity,
                  height: 184,
                  borderRadius: BatshRadius.brLg,
                ),
              ],
            ),
          ),
          if (i == 0) const SizedBox(height: BatshSpacing.md),
        ],
      ],
    );
  }
}

class _CommunityFeedError extends StatelessWidget {
  const _CommunityFeedError({
    required this.requiresSignIn,
    required this.onRetry,
    required this.onSignIn,
  });

  final bool requiresSignIn;
  final VoidCallback onRetry;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final title = requiresSignIn
        ? context.l10n.communityFeedGuestErrorTitle
        : context.l10n.communityFeedErrorTitle;
    final message = requiresSignIn
        ? context.l10n.communityFeedGuestErrorMessage
        : context.l10n.communityFeedErrorMessage;
    final actionLabel = requiresSignIn
        ? context.l10n.signInAction
        : context.l10n.tryAgain;

    return Semantics(
      container: true,
      liveRegion: true,
      label: '$title. $message',
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BatshSpacing.lg,
          vertical: BatshSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.colorScheme.error.withValues(alpha: 0.10),
                shape: BoxShape.circle,
                border: Border.all(
                  color: context.colorScheme.error.withValues(alpha: 0.20),
                ),
              ),
              child: Icon(
                requiresSignIn
                    ? Icons.lock_outline_rounded
                    : Icons.error_outline_rounded,
                color: context.colorScheme.error,
                size: 34,
              ),
            ),
            const SizedBox(height: BatshSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: BatshTypography.titleLg.copyWith(
                color: context.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: BatshSpacing.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 310),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: BatshTypography.bodyMd.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                  height: 1.55,
                ),
              ),
            ),
            const SizedBox(height: BatshSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: BatshButton(
                label: actionLabel,
                onPressed: requiresSignIn ? onSignIn : onRetry,
                fullWidth: true,
                icon: requiresSignIn
                    ? Icons.login_rounded
                    : Icons.refresh_rounded,
              ),
            ),
            if (requiresSignIn) ...[
              const SizedBox(height: BatshSpacing.xs),
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  minimumSize: const Size.fromHeight(BatshSpacing.minHitArea),
                  foregroundColor: context.colorScheme.primary,
                ),
                child: Text(context.l10n.tryAgain),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PaginationHint extends StatelessWidget {
  const _PaginationHint();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: BatshSpacing.lg),
      child: BatshPaginationSkeleton(
        key: const ValueKey('community-pagination-loading'),
      ),
    );
  }
}

class _PaginationError extends StatelessWidget {
  const _PaginationError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: context.l10n.loadMoreError,
      child: OutlinedButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded),
        label: Text(context.l10n.tryAgain),
      ),
    );
  }
}
