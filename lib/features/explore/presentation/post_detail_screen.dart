import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/batsh_colors.dart';
import '../../../core/theme/batsh_motion.dart';
import '../../../core/theme/batsh_radius.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/theme/batsh_typography.dart';
import '../../../core/router/routes.dart';
import '../../../core/widgets/batsh_card.dart';
import '../../../core/widgets/role_badge.dart';
import '../../../core/widgets/batsh_empty_state.dart';
import '../../../core/widgets/batsh_error.dart';
import '../../../core/widgets/batsh_shimmer.dart';
import '../../../core/widgets/batsh_scaffold.dart';
import '../../../core/widgets/contact_buttons.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../auth/presentation/sign_in_sheet.dart';
import '../../../core/widgets/avatar_with_initials.dart';
import '../domain/post.dart';
import 'providers/explore_providers.dart';
import 'widgets/post_type_icon.dart';
import '../../../core/theme/batsh_icon_size.dart';
import '../../../core/widgets/batsh_snack.dart';

class PostDetailScreen extends ConsumerWidget {
  const PostDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postAsync = ref.watch(postByIdProvider(postId));
    final commentsAsync = ref.watch(postCommentsProvider(postId));

    return BatshScaffold(
      title: S.exploreTitle,
      body: postAsync.when(
        loading: () => const BatshPostSkeleton(),
        error: (e, _) =>
            BatshError(onRetry: () => ref.invalidate(postByIdProvider(postId))),
        data: (post) {
          if (post == null) {
            // Not a failure: the post is gone. Nothing to retry — retrying
            // resolves to null again — so this stays an absence, not an error.
            return BatshEmptyState(
              title: S.postUnavailable,
              message: S.postUnavailableSub,
              icon: Icons.hide_source_outlined,
            );
          }
          return commentsAsync.when(
            // The post is already loaded. Blocking the whole screen on its
            // comments hid content the user could have been reading — the
            // error branch below never did that, and neither does this now.
            loading: () => _PostDetailContent(
              post: post,
              comments: const [],
              commentsLoading: true,
            ),
            // Comments failing shouldn't hide the post — show it with none.
            error: (_, __) =>
                _PostDetailContent(post: post, comments: const []),
            data: (comments) =>
                _PostDetailContent(post: post, comments: comments),
          );
        },
      ),
    );
  }
}

class _PostDetailContent extends ConsumerStatefulWidget {
  const _PostDetailContent({
    required this.post,
    required this.comments,
    this.commentsLoading = false,
  });

  final Post post;
  final List<PostComment> comments;

  /// Comments are still in flight. The post itself is already here, so only
  /// the comment list is stood in for.
  final bool commentsLoading;

  @override
  ConsumerState<_PostDetailContent> createState() => _PostDetailContentState();
}

class _PostDetailContentState extends ConsumerState<_PostDetailContent> {
  final _commentCtrl = TextEditingController();
  final _commentFocus = FocusNode();
  final _mediaCtrl = PageController();
  bool _sending = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    _commentFocus.dispose();
    _mediaCtrl.dispose();
    super.dispose();
  }

  void _ensureAuth(VoidCallback action) {
    runSignedIn(context, ref, reason: S.signInToInteract, action: action);
  }

  void _sharePost(Post post) {
    Share.share(
      'https://shattab.app/explore/post/${post.id}',
      subject: post.caption,
    );
  }

  void _navigateToProfile(Post post) {
    // Contractor profiles live under /h/discover; the role guard bounces
    // contractors off /h, so only homeowners/guests can open them.
    final onContractorSide = GoRouterState.of(
      context,
    ).matchedLocation.startsWith('/c/');
    if (post.authorRole == 'contractor' && !onContractorSide) {
      context.push(Routes.homeownerContractorProfilePath(post.authorId));
    }
  }

  void _sendComment() {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    ref
        .read(postControllerProvider.notifier)
        .addComment(widget.post.id, text)
        .then((_) {
          _commentCtrl.clear();
          _commentFocus.unfocus();
          if (mounted) {
            BatshSnack.success(context, S.commentPosted);
          }
        })
        .catchError((e) {
          if (mounted) {
            final msg = e.toString().contains('rate_limit')
                ? S.commentRateLimitError
                : S.unknownErrorRetry;
            BatshSnack.error(context, msg);
          }
        })
        .whenComplete(() {
          if (mounted) setState(() => _sending = false);
        });
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final session = ref.read(currentSessionProvider);
    final isOwner = session?.user.id == post.authorId;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(BatshSpacing.gutter),
            children: [
              _buildHeader(post),
              if (post.caption.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: BatshSpacing.gutter),
                  child: Text(post.caption, style: BatshTypography.bodyMd),
                ),
              if (post.mediaUrls.isNotEmpty) ...[
                SizedBox(
                  height: 300,
                  child: PageView.builder(
                    controller: _mediaCtrl,
                    itemCount: post.mediaUrls.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: BatshSpacing.sm),
                      child: ClipRRect(
                        borderRadius: BatshRadius.brMd,
                        child: CachedNetworkImage(
                          imageUrl: post.mediaUrls[i],
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: BatshColors.surfaceVariant),
                          errorWidget: (_, __, ___) => Container(
                            color: BatshColors.surfaceVariant,
                            child: Icon(
                              Icons.broken_image,
                              color: BatshColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (post.mediaUrls.length > 1)
                  Center(
                    child: Text(
                      S.photoCount.replaceFirst(
                        '%s',
                        '${post.mediaUrls.length}',
                      ),
                      style: BatshTypography.bodySm,
                    ),
                  ),
                const SizedBox(height: BatshSpacing.sm),
              ],
              _buildActions(post),
              if (post.authorPhone != null && !isOwner) ...[
                const SizedBox(height: BatshSpacing.gutter),
                WhatsAppButton(
                  phone: post.authorPhone!,
                  message: S.whatsappPostGreeting,
                ),
                const SizedBox(height: BatshSpacing.sm),
                CallButton(phone: post.authorPhone!),
              ],
              const SizedBox(height: BatshSpacing.gutter),
              Text(S.commentsTitle, style: BatshTypography.labelMd),
              const SizedBox(height: BatshSpacing.sm),
              if (widget.commentsLoading)
                const BatshCommentsSkeleton()
              else if (widget.comments.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: BatshSpacing.gutter,
                  ),
                  child: Text(
                    S.noComments,
                    style: BatshTypography.bodyMd,
                    textAlign: TextAlign.center,
                  ),
                ),
              ...widget.comments.asMap().entries.map(
                (e) => _buildComment(e.value)
                    .animate()
                    .fadeIn(
                      duration: BatshMotion.normal,
                      delay: BatshMotion.stagger(e.key),
                      curve: BatshMotion.easeOut,
                    )
                    .slideX(
                      begin: 0.05,
                      duration: BatshMotion.normal,
                      delay: BatshMotion.stagger(e.key),
                      curve: BatshMotion.easeOut,
                    ),
              ),
            ],
          ),
        ),
        _buildCommentInput(),
      ],
    );
  }

  Widget _buildHeader(Post post) {
    final session = ref.read(currentSessionProvider);
    final isOwner = session?.user.id == post.authorId;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _navigateToProfile(post),
          child: AvatarWithInitials(
            imageUrl: post.authorAvatarUrl,
            name: post.authorName ?? '',
            radius: 22,
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
                    child: GestureDetector(
                      onTap: () => _navigateToProfile(post),
                      child: Text(
                        post.authorName ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: BatshTypography.labelMd,
                      ),
                    ),
                  ),
                  const SizedBox(width: BatshSpacing.xs),
                  RoleBadge(role: post.authorRole, compact: true),
                  if (isOwner) ...[
                    const Spacer(),
                    PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'delete') {
                          showDialog(
                            context: context,
                            // Pop with the dialog's own context: the screen's
                            // context resolves to the shell branch navigator
                            // and would pop the screen, not the dialog.
                            builder: (ctx) => AlertDialog(
                              title: Text(S.deletePost),
                              content: Text(S.deletePostConfirm),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text(S.cancel),
                                ),
                                TextButton(
                                  onPressed: () {
                                    ref
                                        .read(postControllerProvider.notifier)
                                        .deletePost(post.id);
                                    Navigator.pop(ctx);
                                    context.pop();
                                  },
                                  child: Text(
                                    S.deletePost,
                                    style: const TextStyle(
                                      color: BatshColors.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                size: BatshIconSize.md,
                                color: BatshColors.error,
                              ),
                              const SizedBox(width: 8),
                              Text(S.deletePost),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  PostTypeIcon(postType: post.postType),
                  const SizedBox(width: 4),
                  Text(
                    _postTypeLabel(post.postType),
                    style: BatshTypography.bodySm,
                  ),
                  const SizedBox(width: BatshSpacing.xs),
                  if (post.governorate != null) ...[
                    Text(
                      '• ${post.governorate}',
                      style: BatshTypography.bodySm,
                    ),
                    const SizedBox(width: BatshSpacing.xs),
                  ],
                  Text(
                    '• ${_timeAgo(post.createdAt)}',
                    style: BatshTypography.bodySm,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActions(Post post) {
    return Row(
      children: [
        _ActionBtn(
          icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
          color: post.isLiked ? BatshColors.error : null,
          label: post.likeCount > 0 ? '${post.likeCount}' : S.likeLabel,
          onTap: () => _ensureAuth(
            () => ref.read(postControllerProvider.notifier).toggleLike(post),
          ),
        ),
        const SizedBox(width: BatshSpacing.sm),
        _ActionBtn(
          icon: Icons.chat_bubble_outline,
          label: post.commentCount > 0
              ? '${post.commentCount}'
              : S.commentLabel,
          onTap: () => _commentFocus.requestFocus(),
        ),
        const Spacer(),
        _ActionBtn(
          icon: Icons.share_outlined,
          label: S.sharePost,
          onTap: () => _sharePost(post),
        ),
        const SizedBox(width: BatshSpacing.xs),
        _ActionBtn(
          icon: post.isSaved ? Icons.bookmark : Icons.bookmark_border,
          color: post.isSaved ? BatshColors.tertiary : null,
          onTap: () => _ensureAuth(
            () => ref.read(postControllerProvider.notifier).toggleSave(post),
          ),
        ),
      ],
    );
  }

  Widget _buildComment(PostComment c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: BatshSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AvatarWithInitials(
            imageUrl: c.userAvatarUrl,
            name: c.userName ?? '',
            radius: 16,
          ),
          const SizedBox(width: BatshSpacing.sm),
          Expanded(
            child: BatshCard(
              padding: const EdgeInsets.all(BatshSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(c.userName ?? '', style: BatshTypography.labelSm),
                      const Spacer(),
                      Text(
                        _timeAgo(c.createdAt),
                        style: BatshTypography.labelSm,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(c.content, style: BatshTypography.bodySm),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    final session = ref.read(currentSessionProvider);
    if (session == null) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.only(
        left: BatshSpacing.gutter,
        right: BatshSpacing.gutter,
        top: BatshSpacing.sm,
        bottom: MediaQuery.of(context).padding.bottom + BatshSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: BatshColors.surface,
        border: Border(top: BorderSide(color: BatshColors.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentCtrl,
              focusNode: _commentFocus,
              decoration: InputDecoration(
                hintText: S.commentHint,
                border: InputBorder.none,
                isDense: true,
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendComment(),
            ),
          ),
          GestureDetector(
            onTap: _sending ? null : _sendComment,
            child: Padding(
              padding: const EdgeInsets.all(BatshSpacing.xs),
              child: _sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      S.postComment,
                      style: BatshTypography.labelMd.copyWith(
                        color: BatshColors.primary,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _postTypeLabel(PostType type) {
    switch (type) {
      case PostType.projectShowcase:
        return S.postTypeProjectShowcase;
      case PostType.tip:
        return S.postTypeTip;
      case PostType.milestone:
        return S.postTypeMilestone;
      case PostType.renovationUpdate:
        return S.postTypeRenovationUpdate;
    }
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
}

class _ActionBtn extends StatefulWidget {
  const _ActionBtn({required this.icon, this.label, this.color, this.onTap});

  final IconData icon;
  final String? label;
  final Color? color;
  final VoidCallback? onTap;

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn>
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
                  color: widget.color ?? BatshColors.onSurfaceVariant,
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
