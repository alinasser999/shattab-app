import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../moderation/data/moderation_repository.dart';
import '../../../moderation/presentation/report_sheet.dart';
import '../providers/explore_providers.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../../core/theme/batsh_colors.dart';
import '../../../../core/theme/batsh_motion.dart';
import '../../../../core/theme/batsh_radius.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/utils/image_url.dart';
import '../../../../core/widgets/batsh_card.dart';
import '../../../../core/widgets/role_badge.dart';
import '../../../../core/widgets/avatar_with_initials.dart';
import '../../domain/post.dart';
import 'post_type_icon.dart';
import '../../../../core/theme/batsh_icon_size.dart';
import '../../../../core/widgets/batsh_pressable.dart';

import 'package:batsh/core/theme/theme_extension.dart';

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

  /// True when the signed-in user wrote this post. Controls the overflow menu —
  /// the feed previously offered no way to fix a typo without opening the post.
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
      final m = diff.inMinutes;
      return m == 1
          ? context.l10n.agoMin
          : context.l10n.agoMins.replaceFirst('%s', '$m');
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return h == 1
          ? context.l10n.agoHour
          : context.l10n.agoHours.replaceFirst('%s', '$h');
    }
    final d = diff.inDays;
    return d == 1
        ? context.l10n.agoDay
        : context.l10n.agoDays.replaceFirst('%s', '$d');
  }

  @override
  Widget build(BuildContext context) {
    return BatshCard(
          padding: EdgeInsets.zero,
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              if (post.caption.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    BatshSpacing.gutter,
                    BatshSpacing.sm,
                    BatshSpacing.gutter,
                    BatshSpacing.xs,
                  ),
                  child: Text(
                    post.caption,
                    style: BatshTypography.bodyMd,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (post.mediaUrls.isNotEmpty) _buildMedia(context),
              _buildActions(context),
            ],
          ),
        )
        .animate(
          delay: index != null ? BatshMotion.stagger(index!) : Duration.zero,
        )
        .fadeIn(duration: BatshMotion.normal, curve: BatshMotion.easeOut)
        .slideY(
          begin: 0.1,
          duration: BatshMotion.normal,
          curve: BatshMotion.easeOut,
        );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(BatshSpacing.gutter),
      child: Row(
        children: [
          BatshPressable(
            onTap: onProfileTap,
            semanticLabel: post.authorName ?? '',
            child: AvatarWithInitials(
              imageUrl: post.authorAvatarUrl,
              name: post.authorName ?? '',
              radius: 20,
            ),
          ),
          const SizedBox(width: BatshSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: BatshPressable(
                        onTap: onProfileTap,
                        child: Text(
                          post.authorName ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: BatshTypography.labelMd,
                        ),
                      ),
                    ),
                    const SizedBox(width: BatshSpacing.xs),
                    // Sits beside the name, not under it: whether the author is
                    // a contractor or a homeowner changes how the whole post
                    // reads, so it has to arrive with the name.
                    RoleBadge(role: post.authorRole, compact: true),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    PostTypeIcon(postType: post.postType),
                    const SizedBox(width: 4),
                    Text(
                      _postTypeLabel(context, post.postType),
                      style: BatshTypography.bodySm,
                    ),
                    const SizedBox(width: BatshSpacing.xs),
                    Text('•', style: BatshTypography.bodySm),
                    const SizedBox(width: BatshSpacing.xs),
                    Text(
                      _timeAgo(context, post.createdAt),
                      style: BatshTypography.bodySm,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isOwner && (onEdit != null || onDelete != null))
            _OwnerMenu(onEdit: onEdit, onDelete: onDelete)
          else if (!isOwner)
            // Every post someone else wrote needs a way out: report it, or stop
            // seeing this person entirely.
            _ModerationMenu(postId: post.id, authorId: post.authorId),
        ],
      ),
    );
  }

  Widget _buildMedia(BuildContext context) {
    if (post.mediaUrls.length == 1) {
      return ClipRRect(
        borderRadius: BatshRadius.brSm,
        child: CachedNetworkImage(
          imageUrl: sizedImageUrl(post.mediaUrls.first, width: 900),
          width: double.infinity,
          height: 260,
          fit: BoxFit.cover,
          memCacheWidth: 800, // decode at display size, not source resolution
          placeholder: (_, __) =>
              Container(height: 260, color: context.colorScheme.surfaceVariant),
          errorWidget: (_, __, ___) => Container(
            height: 260,
            color: context.colorScheme.surfaceVariant,
            child: Icon(
              Icons.broken_image,
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 260,
      child: PageView.builder(
        itemCount: post.mediaUrls.length,
        itemBuilder: (_, i) => ClipRRect(
          borderRadius: BatshRadius.brSm,
          child: CachedNetworkImage(
            imageUrl: sizedImageUrl(post.mediaUrls[i], width: 800),
            width: double.infinity,
            fit: BoxFit.cover,
            memCacheWidth: 800,
            placeholder: (_, __) =>
                Container(color: context.colorScheme.surfaceVariant),
            errorWidget: (_, __, ___) => Container(
              color: context.colorScheme.surfaceVariant,
              child: Icon(
                Icons.broken_image,
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BatshSpacing.sm,
        vertical: BatshSpacing.xs,
      ),
      child: Row(
        children: [
          _ActionButton(
            icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
            color: post.isLiked ? context.colorScheme.error : null,
            label: post.likeCount > 0
                ? '${post.likeCount}'
                : context.l10n.likeLabel,
            onTap: onLike,
          ),
          const SizedBox(width: BatshSpacing.sm),
          _ActionButton(
            icon: Icons.chat_bubble_outline,
            label: post.commentCount > 0
                ? '${post.commentCount}'
                : context.l10n.commentLabel,
            onTap: onCommentTap,
          ),
          const Spacer(),
          _ActionButton(
            icon: Icons.share_outlined,
            label: context.l10n.sharePost,
            onTap: _share,
          ),
          const SizedBox(width: BatshSpacing.xs),
          _ActionButton(
            icon: post.isSaved ? Icons.bookmark : Icons.bookmark_border,
            color: post.isSaved ? context.colorScheme.tertiary : null,
            onTap: onSave,
          ),
        ],
      ),
    );
  }

  String _postTypeLabel(BuildContext context, PostType type) {
    switch (type) {
      case PostType.projectShowcase:
        return context.l10n.postTypeProjectShowcase;
      case PostType.tip:
        return context.l10n.postTypeTip;
      case PostType.milestone:
        return context.l10n.postTypeMilestone;
      case PostType.renovationUpdate:
        return context.l10n.postTypeRenovationUpdate;
    }
  }
}

/// Overflow menu for someone else's post: report the content, or block the
/// author. Blocking refreshes the feed, since the RPC filters blocked authors
/// server-side and the post should disappear immediately rather than at the
/// next pull-to-refresh.
class _ModerationMenu extends ConsumerWidget {
  const _ModerationMenu({required this.postId, required this.authorId});

  final String postId;
  final String authorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      tooltip: context.l10n.reportTitle,
      icon: Icon(
        Icons.more_horiz_rounded,
        size: BatshIconSize.md,
        color: context.colorScheme.onSurfaceVariant,
      ),
      onSelected: (v) async {
        if (v == 'report') {
          showReportSheet(context, target: ReportTarget.post, targetId: postId);
        } else if (v == 'block') {
          final blocked = await confirmAndBlock(context, ref, authorId);
          if (blocked) ref.invalidate(exploreFeedProvider);
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'report',
          child: Row(
            children: [
              const Icon(Icons.flag_outlined, size: BatshIconSize.md),
              const SizedBox(width: BatshSpacing.sm),
              Text(context.l10n.reportPostAction),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'block',
          child: Row(
            children: [
              Icon(
                Icons.block,
                size: BatshIconSize.md,
                color: context.colorScheme.error,
              ),
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

/// Overflow menu for a post you wrote. Delete is styled as destructive and
/// listed last, so the two entries can't be confused by muscle memory.
class _OwnerMenu extends StatelessWidget {
  const _OwnerMenu({this.onEdit, this.onDelete});

  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: context.l10n.editPost,
      icon: Icon(
        Icons.more_horiz_rounded,
        size: BatshIconSize.md,
        color: context.colorScheme.onSurfaceVariant,
      ),
      onSelected: (v) {
        if (v == 'edit') onEdit?.call();
        if (v == 'delete') onDelete?.call();
      },
      itemBuilder: (_) => [
        if (onEdit != null)
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                const Icon(Icons.edit_outlined, size: BatshIconSize.md),
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
                  size: BatshIconSize.md,
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

class _ActionButton extends StatefulWidget {
  const _ActionButton({required this.icon, this.label, this.color, this.onTap});

  final IconData icon;
  final String? label;
  final Color? color;
  final VoidCallback? onTap;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: BatshMotion.fast,
    lowerBound: 0.9,
    upperBound: 1.0,
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.reverse(),
      onTapUp: (_) => _ctrl.forward(),
      onTapCancel: () => _ctrl.forward(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) => Transform.scale(
          scale: _ctrl.value,
          child: Padding(
            padding: const EdgeInsets.all(BatshSpacing.xs),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: BatshIconSize.md,
                  color: widget.color ?? context.colorScheme.onSurfaceVariant,
                ),
                if (widget.label != null) ...[
                  const SizedBox(width: 3),
                  Text(widget.label!, style: BatshTypography.labelSm),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
