import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/l10n/strings.dart';
import '../../../../core/theme/batsh_colors.dart';
import '../../../../core/theme/batsh_motion.dart';
import '../../../../core/theme/batsh_radius.dart';
import '../../../../core/theme/batsh_spacing.dart';
import '../../../../core/theme/batsh_typography.dart';
import '../../../../core/widgets/batsh_card.dart';
import '../../../discovery/presentation/widgets/avatar_with_initials.dart';
import '../../domain/post.dart';
import 'post_type_icon.dart';

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
  });

  final Post post;
  final VoidCallback onTap;
  final int? index;
  final VoidCallback? onLike;
  final VoidCallback? onSave;
  final VoidCallback? onProfileTap;
  final VoidCallback? onCommentTap;

  String get _shareUrl => 'https://shattab.app/explore/post/${post.id}';

  void _share() {
    Share.share(_shareUrl, subject: post.caption);
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return S.agoNow;
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return m == 1 ? S.agoMin : S.agoMins.replaceFirst('%s', '$m');
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return h == 1 ? S.agoHour : S.agoHours.replaceFirst('%s', '$h');
    }
    final d = diff.inDays;
    return d == 1 ? S.agoDay : S.agoDays.replaceFirst('%s', '$d');
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
                BatshSpacing.gutter, BatshSpacing.sm,
                BatshSpacing.gutter, BatshSpacing.xs,
              ),
              child: Text(post.caption,
                style: BatshTypography.bodyMd,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (post.mediaUrls.isNotEmpty) _buildMedia(context),
          _buildActions(),
        ],
      ),
    ).animate(
      delay: index != null ? BatshMotion.stagger(index!) : Duration.zero,
    ).fadeIn(
      duration: BatshMotion.normal,
      curve: BatshMotion.easeOut,
    ).slideY(
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
          GestureDetector(
            onTap: onProfileTap,
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
                GestureDetector(
                  onTap: onProfileTap,
                  child: Text(
                    post.authorName ?? '',
                    style: BatshTypography.labelMd,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    PostTypeIcon(postType: post.postType),
                    const SizedBox(width: 4),
                    Text(_postTypeLabel(post.postType),
                      style: BatshTypography.bodySm,
                    ),
                    const SizedBox(width: BatshSpacing.xs),
                    Text('•', style: BatshTypography.bodySm),
                    const SizedBox(width: BatshSpacing.xs),
                    Text(_timeAgo(post.createdAt),
                      style: BatshTypography.bodySm,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedia(BuildContext context) {
    if (post.mediaUrls.length == 1) {
      return ClipRRect(
        borderRadius: BatshRadius.brSm,
        child: CachedNetworkImage(
          imageUrl: post.mediaUrls.first,
          width: double.infinity,
          height: 260,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            height: 260,
            color: BatshColors.surfaceVariant,
          ),
          errorWidget: (_, __, ___) => Container(
            height: 260,
            color: BatshColors.surfaceVariant,
            child: Icon(Icons.broken_image, color: BatshColors.onSurfaceVariant),
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
            imageUrl: post.mediaUrls[i],
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              color: BatshColors.surfaceVariant,
            ),
            errorWidget: (_, __, ___) => Container(
              color: BatshColors.surfaceVariant,
              child: Icon(Icons.broken_image, color: BatshColors.onSurfaceVariant),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BatshSpacing.sm,
        vertical: BatshSpacing.xs,
      ),
      child: Row(
        children: [
          _ActionButton(
            icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
            color: post.isLiked ? BatshColors.error : null,
            label: post.likeCount > 0 ? '${post.likeCount}' : S.likeLabel,
            onTap: onLike,
          ),
          const SizedBox(width: BatshSpacing.sm),
          _ActionButton(
            icon: Icons.chat_bubble_outline,
            label: post.commentCount > 0 ? '${post.commentCount}' : S.commentLabel,
            onTap: onCommentTap,
          ),
          const Spacer(),
          _ActionButton(
            icon: Icons.share_outlined,
            label: S.sharePost,
            onTap: _share,
          ),
          const SizedBox(width: BatshSpacing.xs),
          _ActionButton(
            icon: post.isSaved ? Icons.bookmark : Icons.bookmark_border,
            color: post.isSaved ? BatshColors.tertiary : null,
            onTap: onSave,
          ),
        ],
      ),
    );
  }

  String _postTypeLabel(PostType type) {
    switch (type) {
      case PostType.projectShowcase: return S.postTypeProjectShowcase;
      case PostType.tip: return S.postTypeTip;
      case PostType.milestone: return S.postTypeMilestone;
      case PostType.renovationUpdate: return S.postTypeRenovationUpdate;
    }
  }
}

class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.icon,
    this.label,
    this.color,
    this.onTap,
  });

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
                Icon(widget.icon, size: 20, color: widget.color ?? BatshColors.onSurfaceVariant),
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
