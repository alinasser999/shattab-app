import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/batsh_radius.dart';
import '../../../../core/theme/batsh_shadows.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/theme/theme_extension.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../../core/widgets/batsh_shimmer.dart';
import '../../../../core/widgets/batsh_snack.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/sign_in_sheet.dart';
import '../../domain/post.dart';
import '../providers/explore_providers.dart';
import 'post_card.dart';

/// Shows a contractor's latest public community posts on profile surfaces.
///
/// The feed query is intentionally limited to a small profile preview. Full
/// post interactions still open the existing post detail screen, so replies,
/// comment likes, and moderation keep one source of truth.
class ContractorCommunityPosts extends ConsumerWidget {
  const ContractorCommunityPosts({super.key, required this.contractorId});

  final String contractorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(contractorCommunityPostsProvider(contractorId));

    return posts.when(
      loading: () => const _CommunityPostsLoading(),
      error: (_, _) => _CommunityPostsMessage(
        icon: Icons.cloud_off_outlined,
        title: context.l10n.communityPostsLoadError,
        message: context.l10n.unknownErrorRetry,
        actionLabel: context.l10n.retry,
        onAction: () =>
            ref.invalidate(contractorCommunityPostsProvider(contractorId)),
      ),
      data: (items) {
        if (items.isEmpty) {
          return _CommunityPostsMessage(
            icon: Icons.forum_outlined,
            title: context.l10n.communityPostsEmptyTitle,
            message: context.l10n.communityPostsEmptyMessage,
          );
        }

        return Column(
          children: [
            for (var index = 0; index < items.length; index++) ...[
              if (index > 0) const SizedBox(height: BatshSpacing.md),
              _PostPreview(
                post: items[index],
                index: index,
                contractorId: contractorId,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _PostPreview extends ConsumerWidget {
  const _PostPreview({
    required this.post,
    required this.index,
    required this.contractorId,
  });

  final Post post;
  final int index;
  final String contractorId;

  bool _isContractorSide(BuildContext context) =>
      GoRouterState.of(context).matchedLocation.startsWith('/c/');

  void _openPost(BuildContext context) {
    context.push(
      _isContractorSide(context)
          ? Routes.contractorCommunityPostPath(post.id)
          : Routes.homeownerCommunityPostPath(post.id),
    );
  }

  void _openAuthor(BuildContext context, WidgetRef ref) {
    final isContractorSide = _isContractorSide(context);
    final currentUserId = ref.read(currentSessionProvider)?.user.id;
    if (post.authorId == currentUserId) {
      context.go(
        isContractorSide ? Routes.contractorProfile : Routes.homeownerProfile,
      );
      return;
    }

    context.push(
      isContractorSide
          ? Routes.contractorCommunityContractorProfilePath(post.authorId)
          : Routes.homeownerContractorProfilePath(post.authorId),
    );
  }

  void _toggleLike(BuildContext context, WidgetRef ref) {
    runSignedIn(
      context,
      ref,
      reason: context.l10n.signInToInteract,
      action: () async {
        try {
          await ref.read(postControllerProvider.notifier).toggleLike(post);
          ref.invalidate(contractorCommunityPostsProvider(contractorId));
        } catch (error) {
          if (context.mounted) {
            BatshSnack.error(context, ErrorMapper.map(error));
          }
        }
      },
    );
  }

  void _toggleSave(BuildContext context, WidgetRef ref) {
    runSignedIn(
      context,
      ref,
      reason: context.l10n.signInToSave,
      action: () async {
        try {
          await ref.read(postControllerProvider.notifier).toggleSave(post);
          ref.invalidate(contractorCommunityPostsProvider(contractorId));
        } catch (error) {
          if (context.mounted) {
            BatshSnack.error(context, ErrorMapper.map(error));
          }
        }
      },
    );
  }

  Future<void> _deletePost(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.deletePost),
        content: Text(context.l10n.deletePostConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              context.l10n.deletePost,
              style: TextStyle(color: context.colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(postControllerProvider.notifier).deletePost(post.id);
      ref.invalidate(contractorCommunityPostsProvider(contractorId));
      if (context.mounted) {
        BatshSnack.success(context, context.l10n.postDeleted);
      }
    } catch (error) {
      if (context.mounted) BatshSnack.error(context, ErrorMapper.map(error));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.read(currentSessionProvider)?.user.id;
    final isOwner = currentUserId == post.authorId;

    return PostCard(
      post: post,
      index: index,
      onTap: () => _openPost(context),
      onLike: () => _toggleLike(context, ref),
      onSave: () => _toggleSave(context, ref),
      onProfileTap: () => _openAuthor(context, ref),
      onCommentTap: () => _openPost(context),
      isOwner: isOwner,
      onEdit: isOwner ? () => _openPost(context) : null,
      onDelete: isOwner ? () => _deletePost(context, ref) : null,
    );
  }
}

class _CommunityPostsLoading extends StatelessWidget {
  const _CommunityPostsLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < 2; index++) ...[
          if (index > 0) const SizedBox(height: BatshSpacing.md),
          const SizedBox(
            height: 230,
            child: BatshShimmerBox(height: 230, borderRadius: BatshRadius.brXl),
          ),
        ],
      ],
    );
  }
}

class _CommunityPostsMessage extends StatelessWidget {
  const _CommunityPostsMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(BatshSpacing.md),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerLowest,
        borderRadius: BatshRadius.brXl,
        border: Border.all(color: context.colorScheme.outlineVariant),
        boxShadow: BatshShadows.soft,
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: context.colorScheme.secondaryContainer,
              borderRadius: BatshRadius.brMd,
            ),
            child: Padding(
              padding: const EdgeInsets.all(BatshSpacing.sm),
              child: Icon(icon, color: context.colorScheme.secondary),
            ),
          ),
          const SizedBox(width: BatshSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: BatshTypography.labelMd.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: BatshSpacing.xxs),
                Text(
                  message,
                  style: BatshTypography.bodySm.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (actionLabel != null && onAction != null)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                      onPressed: onAction,
                      child: Text(actionLabel!),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
