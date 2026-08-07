import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
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
import '../../../core/widgets/batsh_pressable.dart';

import 'package:batsh/core/theme/theme_extension.dart';

class PostDetailScreen extends ConsumerWidget {
  const PostDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postAsync = ref.watch(postByIdProvider(postId));
    final commentsAsync = ref.watch(postCommentsProvider(postId));

    return BatshScaffold(
      title: context.l10n.exploreTitle,
      body: postAsync.when(
        loading: () => const BatshPostSkeleton(),
        error: (e, _) =>
            BatshError(onRetry: () => ref.invalidate(postByIdProvider(postId))),
        data: (post) {
          if (post == null) {
            // Not a failure: the post is gone. Nothing to retry — retrying
            // resolves to null again — so this stays an absence, not an error.
            return BatshEmptyState(
              title: context.l10n.postUnavailable,
              message: context.l10n.postUnavailableSub,
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
  PostComment? _replyingTo;
  PostComment? _editingComment;

  @override
  void dispose() {
    _commentCtrl.dispose();
    _commentFocus.dispose();
    _mediaCtrl.dispose();
    super.dispose();
  }

  void _ensureAuth(VoidCallback action) {
    runSignedIn(
      context,
      ref,
      reason: context.l10n.signInToInteract,
      action: action,
    );
  }

  /// Runs an optimistic toggle, and says so when the write behind it fails.
  ///
  /// The controller has already rolled the flip back by the time this catches.
  /// Without a message, that undo is indistinguishable from a tap that missed.
  void _optimistic(Future<void> Function() op) => _ensureAuth(() async {
    try {
      await op();
    } catch (_) {
      if (mounted) BatshSnack.error(context, context.l10n.unknownErrorRetry);
    }
  });

  void _sharePost(Post post) {
    Share.share(
      'https://shattab.app/explore/post/${post.id}',
      subject: post.caption,
    );
  }

  void _navigateToProfile(Post post) {
    final onContractorSide = GoRouterState.of(
      context,
    ).matchedLocation.startsWith('/c/');
    final current = ref.read(currentSessionProvider)?.user.id;
    if (post.authorId == current) {
      context.go(
        onContractorSide ? Routes.contractorProfile : Routes.homeownerProfile,
      );
    } else if (post.authorRole == 'contractor') {
      context.push(
        onContractorSide
            ? Routes.contractorCommunityContractorProfilePath(post.authorId)
            : Routes.homeownerContractorProfilePath(post.authorId),
      );
    } else if (onContractorSide) {
      context.push(Routes.contractorHomeownerProfilePath(post.authorId));
    } else {
      context.push(Routes.homeownerCommunityMemberPath(post.authorId));
    }
  }

  void _navigateToCommenter(PostComment comment) {
    final current = ref.read(currentSessionProvider)?.user.id;
    final onContractorSide = GoRouterState.of(
      context,
    ).matchedLocation.startsWith('/c/');
    if (comment.userId == current) {
      context.go(
        onContractorSide ? Routes.contractorProfile : Routes.homeownerProfile,
      );
      return;
    }

    if (comment.userRole == 'contractor') {
      context.push(
        onContractorSide
            ? Routes.contractorCommunityContractorProfilePath(comment.userId)
            : Routes.homeownerContractorProfilePath(comment.userId),
      );
    } else if (onContractorSide) {
      context.push(Routes.contractorHomeownerProfilePath(comment.userId));
    } else {
      context.push(Routes.homeownerCommunityMemberPath(comment.userId));
    }
  }

  Future<void> _sendComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    final editing = _editingComment;
    final replyingTo = _replyingTo;
    setState(() => _sending = true);
    try {
      final controller = ref.read(postControllerProvider.notifier);
      if (editing != null) {
        await controller.updateComment(
          postId: widget.post.id,
          commentId: editing.id,
          content: text,
        );
      } else {
        await controller.addComment(
          widget.post.id,
          text,
          parentCommentId: replyingTo?.id,
        );
      }
      _commentCtrl.clear();
      _commentFocus.unfocus();
      if (mounted) {
        setState(() {
          _replyingTo = null;
          _editingComment = null;
        });
        BatshSnack.success(
          context,
          editing == null
              ? context.l10n.commentPosted
              : context.l10n.commentUpdated,
        );
      }
    } catch (error) {
      if (mounted) {
        final msg = error.toString().contains('rate_limit')
            ? context.l10n.commentRateLimitError
            : context.l10n.unknownErrorRetry;
        BatshSnack.error(context, msg);
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _replyTo(PostComment comment) {
    setState(() {
      _replyingTo = comment;
      _editingComment = null;
      _commentCtrl.clear();
    });
    _commentFocus.requestFocus();
  }

  void _editComment(PostComment comment) {
    setState(() {
      _editingComment = comment;
      _replyingTo = null;
      _commentCtrl.text = comment.content;
      _commentCtrl.selection = TextSelection.collapsed(
        offset: _commentCtrl.text.length,
      );
    });
    _commentFocus.requestFocus();
  }

  void _cancelCommentMode() {
    _commentCtrl.clear();
    _commentFocus.unfocus();
    setState(() {
      _replyingTo = null;
      _editingComment = null;
    });
  }

  void _toggleCommentLike(PostComment comment) {
    _ensureAuth(() async {
      try {
        await ref
            .read(postControllerProvider.notifier)
            .toggleCommentLike(postId: widget.post.id, comment: comment);
      } catch (_) {
        if (mounted) BatshSnack.error(context, context.l10n.unknownErrorRetry);
      }
    });
  }

  Future<void> _confirmDeleteComment(PostComment comment) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.deleteComment),
        content: Text(context.l10n.deleteCommentConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              context.l10n.deleteComment,
              style: TextStyle(color: context.colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !mounted) return;
    try {
      await ref
          .read(postControllerProvider.notifier)
          .deleteComment(postId: widget.post.id, commentId: comment.id);
      if (mounted) BatshSnack.success(context, context.l10n.commentDeleted);
    } catch (_) {
      if (mounted) BatshSnack.error(context, context.l10n.unknownErrorRetry);
    }
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
                          placeholder: (_, __) => Container(
                            color: context.colorScheme.surfaceContainerHighest,
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: context.colorScheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.broken_image,
                              color: context.colorScheme.onSurfaceVariant,
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
                      context.l10n.photoCount.replaceFirst(
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
                  message: context.l10n.whatsappPostGreeting,
                ),
                const SizedBox(height: BatshSpacing.sm),
                CallButton(phone: post.authorPhone!),
              ],
              const SizedBox(height: BatshSpacing.gutter),
              Text(context.l10n.commentsTitle, style: BatshTypography.labelMd),
              const SizedBox(height: BatshSpacing.sm),
              if (widget.commentsLoading)
                const BatshCommentsSkeleton()
              else if (widget.comments.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: BatshSpacing.gutter,
                  ),
                  child: Text(
                    context.l10n.noComments,
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
        BatshPressable(
          onTap: () => _navigateToProfile(post),
          semanticLabel: post.authorName ?? '',
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
                    child: BatshPressable(
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
                              title: Text(context.l10n.deletePost),
                              content: Text(context.l10n.deletePostConfirm),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text(context.l10n.cancel),
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
                                    context.l10n.deletePost,
                                    style: TextStyle(
                                      color: context.colorScheme.error,
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
                                color: context.colorScheme.error,
                              ),
                              const SizedBox(width: 8),
                              Text(context.l10n.deletePost),
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
                  PostTypeIcon(
                    postType: post.postType,
                    isQuestion: post.isQuestion,
                  ),
                  const SizedBox(width: 4),
                  Text(_postTypeLabel(post), style: BatshTypography.bodySm),
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
          color: post.isLiked ? context.colorScheme.error : null,
          label: post.likeCount > 0
              ? '${post.likeCount}'
              : context.l10n.likeLabel,
          onTap: () => _optimistic(
            () => ref.read(postControllerProvider.notifier).toggleLike(post),
          ),
          haptic: HapticStrength.light,
        ),
        const SizedBox(width: BatshSpacing.sm),
        _ActionBtn(
          icon: Icons.chat_bubble_outline,
          label: post.commentCount > 0
              ? '${post.commentCount}'
              : context.l10n.commentLabel,
          onTap: () => _commentFocus.requestFocus(),
        ),
        const Spacer(),
        _ActionBtn(
          icon: Icons.share_outlined,
          label: context.l10n.sharePost,
          onTap: () => _sharePost(post),
        ),
        const SizedBox(width: BatshSpacing.xs),
        _ActionBtn(
          icon: post.isSaved ? Icons.bookmark : Icons.bookmark_border,
          color: post.isSaved ? context.colorScheme.tertiary : null,
          onTap: () => _optimistic(
            () => ref.read(postControllerProvider.notifier).toggleSave(post),
          ),
          haptic: HapticStrength.light,
        ),
      ],
    );
  }

  Widget _buildComment(PostComment c) {
    final session = ref.read(currentSessionProvider);
    final isOwner = session?.user.id == c.userId;
    final name = c.userName?.trim().isNotEmpty == true
        ? c.userName!.trim()
        : context.l10n.communityMemberFallback;
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: c.parentCommentId == null ? 0 : BatshSpacing.lg,
        bottom: BatshSpacing.sm,
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BatshPressable(
            onTap: () => _navigateToCommenter(c),
            semanticLabel: name,
            child: AvatarWithInitials(
              imageUrl: c.userAvatarUrl,
              name: name,
              radius: 16,
            ),
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
                      Expanded(
                        child: BatshPressable(
                          onTap: () => _navigateToCommenter(c),
                          semanticLabel: name,
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: BatshTypography.labelSm,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _timeAgo(c.createdAt),
                        style: BatshTypography.labelSm,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(c.content, style: BatshTypography.bodySm),
                  if (c.wasEdited) ...[
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.commentEditedLabel,
                      style: BatshTypography.labelSm.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: BatshSpacing.xs),
                  Wrap(
                    spacing: BatshSpacing.xs,
                    runSpacing: BatshSpacing.xxs,
                    children: [
                      _ActionBtn(
                        icon: c.isLiked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: c.isLiked ? context.colorScheme.error : null,
                        label: c.likeCount > 0
                            ? '${c.likeCount}'
                            : c.isLiked
                            ? context.l10n.commentUnlike
                            : context.l10n.commentLike,
                        onTap: () => _toggleCommentLike(c),
                        haptic: HapticStrength.light,
                      ),
                      _ActionBtn(
                        icon: Icons.reply_outlined,
                        label: context.l10n.commentReply,
                        onTap: () => _replyTo(c),
                      ),
                      if (isOwner)
                        PopupMenuButton<String>(
                          tooltip: context.l10n.editComment,
                          padding: EdgeInsets.zero,
                          onSelected: (value) {
                            if (value == 'edit') _editComment(c);
                            if (value == 'delete') {
                              _confirmDeleteComment(c);
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text(context.l10n.editComment),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(
                                context.l10n.deleteComment,
                                style: TextStyle(
                                  color: context.colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                          child: const Padding(
                            padding: EdgeInsets.all(BatshSpacing.xs),
                            child: Icon(Icons.more_horiz_rounded),
                          ),
                        ),
                    ],
                  ),
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
        color: context.colorScheme.surface,
        border: Border(
          top: BorderSide(color: context.colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_editingComment != null || _replyingTo != null)
            Row(
              children: [
                Icon(
                  _editingComment != null
                      ? Icons.edit_outlined
                      : Icons.reply_outlined,
                  size: BatshIconSize.sm,
                  color: context.colorScheme.primary,
                ),
                const SizedBox(width: BatshSpacing.xs),
                Expanded(
                  child: Text(
                    _editingComment != null
                        ? context.l10n.editComment
                        : '${context.l10n.replyingToComment}: ${_replyingTo!.userName ?? context.l10n.communityMemberFallback}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BatshTypography.labelSm.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: context.l10n.cancel,
                  onPressed: _cancelCommentMode,
                  icon: const Icon(Icons.close_rounded),
                  iconSize: BatshIconSize.sm,
                ),
              ],
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentCtrl,
                  focusNode: _commentFocus,
                  decoration: InputDecoration(
                    hintText: context.l10n.commentHint,
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendComment(),
                ),
              ),
              Semantics(
                button: true,
                label: _editingComment != null
                    ? context.l10n.saveChanges
                    : context.l10n.postComment,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  child: GestureDetector(
                    onTap: _sending ? null : _sendComment,
                    child: Center(
                      child: _sending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _editingComment != null
                                  ? context.l10n.saveChanges
                                  : context.l10n.postComment,
                              style: BatshTypography.labelMd.copyWith(
                                color: context.colorScheme.primary,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _postTypeLabel(Post post) {
    if (post.isQuestion) return context.l10n.communityPostKindQuestion;

    switch (post.postType) {
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

  String _timeAgo(DateTime dt) {
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
}

class _ActionBtn extends StatefulWidget {
  const _ActionBtn({
    required this.icon,
    this.label,
    this.color,
    this.onTap,
    this.haptic = HapticStrength.selection,
  });

  final IconData icon;
  final String? label;
  final Color? color;
  final VoidCallback? onTap;

  /// Liking and saving are the two taps here that mean something to the person
  /// making them, so they answer back harder than share or comment.
  final HapticStrength haptic;

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn>
    with SingleTickerProviderStateMixin {
  // `value` matters: AnimationController defaults it to `lowerBound`, so
  // without it every one of these buttons painted at 0.9 forever and only
  // reached full size after its first tap.
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: BatshMotion.fast,
    lowerBound: 0.9,
    upperBound: 1.0,
    value: 1.0,
  );

  bool get _reduced => MediaQuery.disableAnimationsOf(context);

  void _press() {
    if (!_reduced) _ctrl.reverse();
  }

  void _release() {
    if (!_reduced) _ctrl.forward();
  }

  void _tap() {
    final onTap = widget.onTap;
    if (onTap == null) return;
    switch (widget.haptic) {
      case HapticStrength.selection:
        HapticFeedback.selectionClick();
      case HapticStrength.light:
        HapticFeedback.lightImpact();
    }
    onTap();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _press(),
      onTapUp: (_) => _release(),
      onTapCancel: _release,
      onTap: _tap,
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
