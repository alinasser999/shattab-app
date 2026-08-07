import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../../core/theme/batsh_motion.dart';
import '../../../../core/theme/batsh_radius.dart';
import '../../../../core/theme/batsh_shadows.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/utils/image_url.dart';
import '../../../../core/widgets/avatar_with_initials.dart';
import '../../../../core/widgets/batsh_pressable.dart';
import '../../../moderation/data/moderation_repository.dart';
import '../../../moderation/presentation/report_sheet.dart';
import '../../domain/post.dart';
import '../providers/explore_providers.dart';
import 'package:batsh/core/theme/theme_extension.dart';

const _communityBeforeAfterAsset = 'assets/images/community_before_after.jpg';
const _communityKitchenAsset = 'assets/images/community_kitchen.jpg';

class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.onTap,
    this.index,
    this.onLike,
    this.onSave,
    this.onProfileTap,
    this.onCommentTap,
    this.isOwner = false,
    this.onEdit,
    this.onDelete,
  });

  final Post post;
  final VoidCallback onTap;
  final int? index;
  final VoidCallback? onLike;
  final VoidCallback? onSave;
  final VoidCallback? onProfileTap;
  final VoidCallback? onCommentTap;
  final bool isOwner;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  String get _shareUrl => 'https://shattab.app/explore/post/${post.id}';

  void _share() {
    Share.share(_shareUrl, subject: post.caption);
  }

  String _timeAgo(BuildContext context, DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return context.l10n.agoNow;
    if (diff.inMinutes < 60) {
      final minutes = diff.inMinutes;
      return minutes == 1
          ? context.l10n.agoMin
          : context.l10n.agoMins.replaceFirst('%s', _arabicDigits(minutes));
    }
    if (diff.inHours < 24) {
      final hours = diff.inHours;
      return hours == 1
          ? context.l10n.agoHour
          : context.l10n.agoHours.replaceFirst('%s', _arabicDigits(hours));
    }
    final days = diff.inDays;
    return days == 1
        ? context.l10n.agoDay
        : context.l10n.agoDays.replaceFirst('%s', _arabicDigits(days));
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final authorName = post.authorName?.trim().isNotEmpty == true
        ? post.authorName!.trim()
        : context.l10n.communityMemberFallback;
    final time = _timeAgo(context, post.createdAt);

    final surface = Semantics(
      container: true,
      label: '$authorName، $time',
      child: Container(
        decoration: BoxDecoration(
          color: context.colorScheme.surfaceContainerLowest,
          borderRadius: BatshRadius.brXl,
          border: Border.all(
            color: context.colorScheme.outlineVariant.withValues(alpha: 0.65),
          ),
          boxShadow: BatshShadows.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context, authorName, time),
            _buildOpenableContent(context),
            _buildActions(context),
          ],
        ),
      ),
    );

    if (index == null || reduced) return surface;
    return surface
        .animate(delay: BatshMotion.staggerClamped(index!))
        .fadeIn(duration: BatshMotion.normal, curve: BatshMotion.easeOut)
        .slideY(
          begin: 0.035,
          end: 0,
          duration: BatshMotion.normal,
          curve: BatshMotion.easeOut,
        );
  }

  Widget _buildHeader(BuildContext context, String authorName, String time) {
    final avatarUrl = isDisplayableImageUrl(post.authorAvatarUrl)
        ? sizedImageUrl(post.authorAvatarUrl!, width: 96)
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BatshSpacing.md,
        BatshSpacing.md,
        BatshSpacing.md,
        BatshSpacing.sm,
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BatshPressable(
            onTap: onProfileTap,
            semanticLabel: authorName,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.colorScheme.surface,
                border: Border.all(color: context.colorScheme.outlineVariant),
              ),
              child: AvatarWithInitials(
                imageUrl: avatarUrl,
                name: authorName,
                radius: 22,
              ),
            ),
          ),
          const SizedBox(width: BatshSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  textDirection: TextDirection.rtl,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: BatshPressable(
                        onTap: onProfileTap,
                        semanticLabel: authorName,
                        child: Text(
                          authorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: BatshTypography.labelLg.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: BatshSpacing.xs),
                    _CommunityRoleBadge(role: post.authorRole),
                  ],
                ),
                const SizedBox(height: BatshSpacing.xxs),
                Row(
                  textDirection: TextDirection.rtl,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.public_outlined,
                      size: 14,
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: BatshTypography.bodySm.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: BatshSpacing.xs),
          if (isOwner && (onEdit != null || onDelete != null))
            _OwnerMenu(onEdit: onEdit, onDelete: onDelete)
          else
            _ModerationMenu(postId: post.id, authorId: post.authorId),
        ],
      ),
    );
  }

  Widget _buildOpenableContent(BuildContext context) {
    final hasCaption = post.caption.trim().isNotEmpty;
    final media = _buildMedia(context);
    final List<Widget> mediaChildren = media == null ? const [] : [media];
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          BatshSpacing.md,
          0,
          BatshSpacing.md,
          BatshSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasCaption) ...[
              Text(
                post.caption,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: BatshTypography.bodyMd.copyWith(
                  color: context.colorScheme.onSurface,
                  height: 1.65,
                ),
              ),
              if (media != null) const SizedBox(height: BatshSpacing.md),
            ],
            ...mediaChildren,
          ],
        ),
      ),
    );
  }

  Widget? _buildMedia(BuildContext context) {
    final urls = post.mediaUrls;
    if (urls.length >= 2) {
      return BeforeAfterMedia(beforeUrl: urls[0], afterUrl: urls[1]);
    }
    if (urls.length == 1) {
      return _SinglePostMedia(url: urls.first);
    }

    // Development rows often predate media uploads. Keep the feed image-led
    // without replacing real user media or changing the post schema.
    if (post.postType == PostType.projectShowcase || index == 0) {
      return const _FallbackBeforeAfterMedia();
    }
    return const _SinglePostMedia(url: _communityKitchenAsset);
  }

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BatshSpacing.sm,
        0,
        BatshSpacing.sm,
        BatshSpacing.xs,
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Expanded(
            child: _PostAction(
              icon: post.isLiked
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              label: post.likeCount > 0
                  ? _arabicDigits(post.likeCount)
                  : context.l10n.communityLikePost,
              semanticLabel: post.isLiked
                  ? context.l10n.communityUnlikePost
                  : context.l10n.communityLikePost,
              color: post.isLiked
                  ? context.colorScheme.primary
                  : context.colorScheme.onSurfaceVariant,
              onTap: onLike,
            ),
          ),
          Expanded(
            child: _PostAction(
              icon: Icons.chat_bubble_outline_rounded,
              label: post.commentCount > 0
                  ? _arabicDigits(post.commentCount)
                  : context.l10n.communityCommentPost,
              semanticLabel: context.l10n.communityCommentPost,
              onTap: onCommentTap,
            ),
          ),
          Expanded(
            child: _PostAction(
              icon: Icons.share_outlined,
              label: context.l10n.communitySharePost,
              semanticLabel: context.l10n.communitySharePost,
              onTap: _share,
            ),
          ),
          Expanded(
            child: _PostAction(
              icon: post.isSaved
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              label: null,
              semanticLabel: post.isSaved
                  ? context.l10n.communityUnsavePost
                  : context.l10n.communitySavePost,
              color: post.isSaved
                  ? context.colorScheme.primary
                  : context.colorScheme.onSurfaceVariant,
              onTap: onSave,
            ),
          ),
        ],
      ),
    );
  }
}

class BeforeAfterMedia extends StatelessWidget {
  const BeforeAfterMedia({
    super.key,
    required this.beforeUrl,
    required this.afterUrl,
  });

  final String beforeUrl;
  final String afterUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BatshRadius.brLg,
      child: AspectRatio(
        aspectRatio: 1.58,
        child: Row(
          textDirection: TextDirection.ltr,
          children: [
            Expanded(
              child: _LabeledMedia(
                url: beforeUrl,
                label: context.l10n.communityBeforeLabel,
              ),
            ),
            Container(
              width: 2,
              color: context.colorScheme.surface.withValues(alpha: 0.9),
            ),
            Expanded(
              child: _LabeledMedia(
                url: afterUrl,
                label: context.l10n.communityAfterLabel,
                isAfter: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LabeledMedia extends StatelessWidget {
  const _LabeledMedia({
    required this.url,
    required this.label,
    this.isAfter = false,
  });

  final String url;
  final String label;
  final bool isAfter;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _PostImage(url: url),
        Positioned(
          top: BatshSpacing.sm,
          left: isAfter ? null : BatshSpacing.sm,
          right: isAfter ? BatshSpacing.sm : null,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isAfter
                  ? context.colorScheme.primary
                  : context.colorScheme.onSurface.withValues(alpha: 0.42),
              borderRadius: BatshRadius.brSm,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: BatshSpacing.sm,
                vertical: BatshSpacing.xxs,
              ),
              child: Text(
                label,
                style: BatshTypography.labelSm.copyWith(
                  color: context.colorScheme.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FallbackBeforeAfterMedia extends StatelessWidget {
  const _FallbackBeforeAfterMedia();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BatshRadius.brLg,
      child: AspectRatio(
        aspectRatio: 1.58,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const _PostImage(url: _communityBeforeAfterAsset),
            Align(
              alignment: Alignment.center,
              child: Container(
                width: 2,
                color: context.colorScheme.surface.withValues(alpha: 0.9),
              ),
            ),
            Positioned(
              top: BatshSpacing.sm,
              left: BatshSpacing.sm,
              child: _MediaLabel(
                label: context.l10n.communityBeforeLabel,
                color: context.colorScheme.onSurface.withValues(alpha: 0.42),
              ),
            ),
            Positioned(
              top: BatshSpacing.sm,
              right: BatshSpacing.sm,
              child: _MediaLabel(
                label: context.l10n.communityAfterLabel,
                color: context.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaLabel extends StatelessWidget {
  const _MediaLabel({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: color, borderRadius: BatshRadius.brSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BatshSpacing.sm,
          vertical: BatshSpacing.xxs,
        ),
        child: Text(
          label,
          style: BatshTypography.labelSm.copyWith(
            color: context.colorScheme.onPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _SinglePostMedia extends StatelessWidget {
  const _SinglePostMedia({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BatshRadius.brLg,
      child: AspectRatio(aspectRatio: 1.58, child: _PostImage(url: url)),
    );
  }
}

class _PostImage extends StatelessWidget {
  const _PostImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.startsWith('assets/')) {
      return Image.asset(url, fit: BoxFit.cover);
    }

    final displayable = isDisplayableImageUrl(url);
    if (!displayable) return const _PostImagePlaceholder();

    return CachedNetworkImage(
      imageUrl: sizedImageUrl(url, width: 900),
      fit: BoxFit.cover,
      memCacheWidth: 900,
      placeholder: (_, __) => const _PostImagePlaceholder(),
      errorWidget: (_, __, ___) => const _PostImagePlaceholder(),
    );
  }
}

class _PostImagePlaceholder extends StatelessWidget {
  const _PostImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHigh,
        border: Border.all(
          color: context.colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Center(
        child: Icon(
          Icons.home_work_outlined,
          size: 30,
          color: context.colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}

class _CommunityRoleBadge extends StatelessWidget {
  const _CommunityRoleBadge({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final contractor = role == 'contractor';
    final color = contractor
        ? context.colorScheme.secondary
        : context.colorScheme.secondary;
    final background = context.colorScheme.secondaryContainer.withValues(
      alpha: contractor ? 0.9 : 0.72,
    );
    return Container(
      constraints: const BoxConstraints(maxWidth: 145),
      padding: const EdgeInsets.symmetric(
        horizontal: BatshSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BatshRadius.brFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.rtl,
        children: [
          Icon(
            contractor ? Icons.verified_rounded : Icons.home_rounded,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              contractor
                  ? context.l10n.communityAuthorProfessional
                  : context.l10n.communityAuthorHomeowner,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: BatshTypography.labelSm.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostAction extends StatelessWidget {
  const _PostAction({
    required this.icon,
    required this.label,
    required this.semanticLabel,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String? label;
  final String semanticLabel;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      child: InkWell(
        onTap: onTap,
        borderRadius: BatshRadius.brMd,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              textDirection: TextDirection.rtl,
              children: [
                Icon(
                  icon,
                  size: 21,
                  color: color ?? context.colorScheme.onSurfaceVariant,
                ),
                if (label != null) ...[
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      label!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BatshTypography.labelSm.copyWith(
                        color: color ?? context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModerationMenu extends ConsumerWidget {
  const _ModerationMenu({required this.postId, required this.authorId});

  final String postId;
  final String authorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      tooltip: context.l10n.communityPostMenuLabel,
      icon: const Icon(Icons.more_horiz_rounded, size: 23),
      onSelected: (value) async {
        if (value == 'report') {
          showReportSheet(context, target: ReportTarget.post, targetId: postId);
        } else if (value == 'block') {
          final blocked = await confirmAndBlock(context, ref, authorId);
          if (blocked) ref.invalidate(exploreFeedProvider);
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'report',
          child: Row(
            children: [
              const Icon(Icons.flag_outlined, size: 20),
              const SizedBox(width: BatshSpacing.sm),
              Text(context.l10n.reportPostAction),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'block',
          child: Row(
            children: [
              Icon(Icons.block, size: 20, color: context.colorScheme.error),
              const SizedBox(width: BatshSpacing.sm),
              Text(
                context.l10n.blockUser,
                style: TextStyle(color: context.colorScheme.error),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OwnerMenu extends StatelessWidget {
  const _OwnerMenu({this.onEdit, this.onDelete});

  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: context.l10n.communityPostMenuLabel,
      icon: const Icon(Icons.more_horiz_rounded, size: 23),
      onSelected: (value) {
        if (value == 'edit') onEdit?.call();
        if (value == 'delete') onDelete?.call();
      },
      itemBuilder: (_) => [
        if (onEdit != null)
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                const Icon(Icons.edit_outlined, size: 20),
                const SizedBox(width: BatshSpacing.sm),
                Text(context.l10n.editPost),
              ],
            ),
          ),
        if (onDelete != null)
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: context.colorScheme.error,
                ),
                const SizedBox(width: BatshSpacing.sm),
                Text(
                  context.l10n.deletePost,
                  style: TextStyle(color: context.colorScheme.error),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

String _arabicDigits(int value) {
  const western = '0123456789';
  const eastern = '٠١٢٣٤٥٦٧٨٩';
  return value
      .toString()
      .split('')
      .map((digit) => eastern[western.indexOf(digit)])
      .join();
}
