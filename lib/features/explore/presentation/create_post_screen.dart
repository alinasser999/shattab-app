import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../core/analytics/app_analytics.dart';
import '../../../core/theme/batsh_radius.dart';
import '../../../core/theme/batsh_shadows.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/theme/batsh_typography.dart';
import '../../../core/widgets/batsh_bottom_nav.dart';
import '../../../core/widgets/batsh_pressable.dart';
import '../../../core/widgets/batsh_scaffold.dart';
import '../../../core/widgets/batsh_shimmer.dart';
import '../../../core/widgets/batsh_success_checkmark.dart';
import '../../../core/widgets/batsh_text_field.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../data/post_repository.dart';
import '../domain/post.dart';
import 'providers/explore_providers.dart';
import 'widgets/community_feed_widgets.dart';
import '../../../core/theme/batsh_icon_size.dart';
import '../../../core/widgets/batsh_snack.dart';

import 'package:batsh/core/theme/theme_extension.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key, this.initialKind});

  final CommunityPostKind? initialKind;

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _captionCtrl = TextEditingController();
  final _picker = ImagePicker();
  late CommunityPostKind _selectedKind;
  List<Uint8List> _selectedImages = [];
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _selectedKind = widget.initialKind ?? CommunityPostKind.standard;
    // Re-evaluate the header Post button's enabled state while typing.
    _captionCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final files = await _picker.pickMultiImage(
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (files.isEmpty) return;
    final bytes = <Uint8List>[];
    for (final f in files) {
      final original = await f.readAsBytes();
      bytes.add(original);
    }
    setState(() => _selectedImages = [..._selectedImages, ...bytes]);
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  Future<void> _submit() async {
    final caption = _captionCtrl.text.trim();
    if (caption.isEmpty) {
      BatshSnack.error(context, context.l10n.captionRequired);
      return;
    }

    if (_selectedKind == CommunityPostKind.beforeAfter &&
        _selectedImages.length < 2) {
      BatshSnack.error(context, context.l10n.communityBeforeAfterNeedsImages);
      return;
    }

    final session = ref.read(currentSessionProvider);
    if (session == null) return;

    setState(() => _uploading = true);

    try {
      final repo = ref.read(postRepositoryProvider);
      final urls = <String>[];
      for (final bytes in _selectedImages) {
        final url = await repo.uploadImage(
          session.user.id,
          bytes,
          'post_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        urls.add(url);
      }

      // Role lives in the profiles table, not auth metadata.
      final role = ref.read(currentProfileProvider).value?.role.name;
      await ref
          .read(postControllerProvider.notifier)
          .createPost(
            authorId: session.user.id,
            authorRole: role ?? 'homeowner',
            postType: _selectedKind.storageType.dbValue,
            caption: caption,
            mediaUrls: urls,
            category: _selectedKind.categoryMarker,
          );
      unawaited(
        AppAnalytics.track(
          'community_post_created',
          properties: {
            'post_type': _selectedKind.storageType.dbValue,
            'has_media': urls.isNotEmpty,
          },
        ),
      );

      if (mounted) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogCtx) {
            // Auto-close via the dialog's own context: the screen's context
            // resolves to the shell branch navigator and would pop the
            // screen instead, leaving the dialog stuck.
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
            });
            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: BatshSuccessCheckmark(message: context.l10n.postCreated),
            );
          },
        );
        if (mounted) context.pop();
      }
    } catch (e) {
      if (mounted) {
        BatshSnack.error(context, context.l10n.unknownErrorRetry);
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPublish = !_uploading && _captionCtrl.text.trim().isNotEmpty;

    return BatshScaffold(
      showAppBar: false,
      padding: EdgeInsets.zero,
      body: Stack(
        children: [
          const Positioned.fill(child: CommunityPatternBackground()),
          Column(
            children: [
              _CreatePostHeader(
                title: context.l10n.createPost,
                publishLabel: context.l10n.postComment,
                canPublish: canPublish,
                uploading: _uploading,
                onBack: () => context.pop(),
                onPublish: _submit,
              ),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    BatshSpacing.md,
                    BatshSpacing.lg,
                    BatshSpacing.md,
                    BatshBottomNav.contentBottomInset(context) +
                        BatshSpacing.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _CreatePostSectionHeading(
                        title: context.l10n.communityCreatePostTypeTitle,
                        subtitle: context.l10n.communityCreatePostTypeSubtitle,
                        icon: Icons.architecture_outlined,
                      ),
                      const SizedBox(height: BatshSpacing.md),
                      _PostTypeSelector(
                        selected: _selectedKind,
                        onSelected: (kind) =>
                            setState(() => _selectedKind = kind),
                      ),
                      const SizedBox(height: BatshSpacing.md),
                      _SelectedKindNote(kind: _selectedKind),
                      const SizedBox(height: BatshSpacing.lg),
                      _CreatePostEditor(
                        controller: _captionCtrl,
                        hint: _captionHint(context),
                        selectedKind: _selectedKind,
                        selectedImages: _selectedImages,
                        onPickImages: _pickImages,
                        onRemoveImage: _removeImage,
                      ),
                      const SizedBox(height: BatshSpacing.lg),
                      SizedBox(
                        height: 56,
                        child: FilledButton.icon(
                          onPressed: canPublish ? _submit : null,
                          icon: _uploading
                              ? const BatshShimmerBox(width: 22, height: 18)
                              : const Icon(Icons.send_outlined),
                          label: Text(context.l10n.communityPublishCta),
                          style: FilledButton.styleFrom(
                            backgroundColor: context.colorScheme.primary,
                            foregroundColor: context.colorScheme.onPrimary,
                            disabledBackgroundColor:
                                context.colorScheme.surfaceContainerHighest,
                            disabledForegroundColor: context
                                .colorScheme
                                .onSurfaceVariant
                                .withValues(alpha: 0.55),
                            shape: RoundedRectangleBorder(
                              borderRadius: BatshRadius.brLg,
                            ),
                            textStyle: BatshTypography.labelLg.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _captionHint(BuildContext context) {
    switch (_selectedKind) {
      case CommunityPostKind.standard:
        return context.l10n.postCaptionHint;
      case CommunityPostKind.beforeAfter:
        return context.l10n.communityPostKindBeforeAfterDescription;
      case CommunityPostKind.tips:
        return context.l10n.communityPostKindTipsDescription;
      case CommunityPostKind.experiences:
        return context.l10n.communityPostKindExperiencesDescription;
      case CommunityPostKind.question:
        return context.l10n.communityPostKindQuestionDescription;
    }
  }
}

class _PostTypeSelector extends StatelessWidget {
  const _PostTypeSelector({required this.selected, required this.onSelected});

  final CommunityPostKind selected;
  final ValueChanged<CommunityPostKind> onSelected;

  String _label(BuildContext context, CommunityPostKind kind) {
    switch (kind) {
      case CommunityPostKind.standard:
        return context.l10n.communityPostKindStandard;
      case CommunityPostKind.beforeAfter:
        return context.l10n.communityPostKindBeforeAfter;
      case CommunityPostKind.tips:
        return context.l10n.communityPostKindTips;
      case CommunityPostKind.experiences:
        return context.l10n.communityPostKindExperiences;
      case CommunityPostKind.question:
        return context.l10n.communityPostKindQuestion;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final singleColumn = constraints.maxWidth < 360;
        final halfWidth = (constraints.maxWidth - BatshSpacing.sm) / 2;
        return Wrap(
          spacing: BatshSpacing.sm,
          runSpacing: BatshSpacing.sm,
          children: [
            SizedBox(
              width: constraints.maxWidth,
              child: _PostKindCard(
                kind: CommunityPostKind.standard,
                title: _label(context, CommunityPostKind.standard),
                onTap: () => onSelected(CommunityPostKind.standard),
                selected: selected == CommunityPostKind.standard,
              ),
            ),
            for (final kind in CommunityPostKind.values.skip(1))
              SizedBox(
                width: singleColumn ? constraints.maxWidth : halfWidth,
                child: _PostKindCard(
                  kind: kind,
                  title: _label(context, kind),
                  onTap: () => onSelected(kind),
                  selected: selected == kind,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CreatePostHeader extends StatelessWidget {
  const _CreatePostHeader({
    required this.title,
    required this.publishLabel,
    required this.canPublish,
    required this.uploading,
    required this.onBack,
    required this.onPublish,
  });

  final String title;
  final String publishLabel;
  final bool canPublish;
  final bool uploading;
  final VoidCallback onBack;
  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.sm),
      decoration: BoxDecoration(
        color: context.colorScheme.surface.withValues(alpha: 0.94),
        border: Border(
          bottom: BorderSide(color: context.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          IconButton(
            onPressed: onBack,
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            icon: const Icon(Icons.arrow_forward_rounded),
            color: context.colorScheme.onSurface,
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: BatshTypography.titleLg.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: canPublish ? onPublish : null,
            style: TextButton.styleFrom(
              minimumSize: const Size(64, BatshSpacing.xxxl),
              padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.sm),
              foregroundColor: context.colorScheme.primary,
            ),
            child: uploading
                ? const BatshShimmerBox(width: 30, height: 16)
                : Text(
                    publishLabel,
                    style: BatshTypography.labelLg.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CreatePostSectionHeading extends StatelessWidget {
  const _CreatePostSectionHeading({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: context.colorScheme.primaryContainer,
            borderRadius: BatshRadius.brMd,
            border: Border.all(
              color: context.colorScheme.primary.withValues(alpha: 0.24),
            ),
          ),
          child: Icon(icon, size: 21, color: context.colorScheme.primary),
        ),
        const SizedBox(width: BatshSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                title,
                textAlign: TextAlign.right,
                style: BatshTypography.titleMd.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: BatshSpacing.xxs),
              Text(
                subtitle,
                textAlign: TextAlign.right,
                style: BatshTypography.bodySm.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PostKindCard extends StatelessWidget {
  const _PostKindCard({
    required this.kind,
    required this.title,
    required this.onTap,
    required this.selected,
  });

  final CommunityPostKind kind;
  final String title;
  final VoidCallback onTap;
  final bool selected;

  IconData get _icon {
    switch (kind) {
      case CommunityPostKind.standard:
        return Icons.edit_note_outlined;
      case CommunityPostKind.beforeAfter:
        return Icons.compare_arrows_outlined;
      case CommunityPostKind.tips:
        return Icons.lightbulb_outline_rounded;
      case CommunityPostKind.experiences:
        return Icons.auto_awesome_outlined;
      case CommunityPostKind.question:
        return Icons.help_outline_rounded;
    }
  }

  String _description(BuildContext context) {
    switch (kind) {
      case CommunityPostKind.standard:
        return context.l10n.communityPostKindStandardDescription;
      case CommunityPostKind.beforeAfter:
        return context.l10n.communityPostKindBeforeAfterDescription;
      case CommunityPostKind.tips:
        return context.l10n.communityPostKindTipsDescription;
      case CommunityPostKind.experiences:
        return context.l10n.communityPostKindExperiencesDescription;
      case CommunityPostKind.question:
        return context.l10n.communityPostKindQuestionDescription;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = context.colorScheme.primary;
    final foreground = selected
        ? context.colorScheme.onPrimary
        : context.colorScheme.onSurface;
    final secondary = selected
        ? context.colorScheme.onPrimary.withValues(alpha: 0.82)
        : context.colorScheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: '$title، ${_description(context)}',
      child: BatshPressable(
        onTap: onTap,
        semanticLabel: title,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          constraints: const BoxConstraints(minHeight: 92),
          padding: const EdgeInsets.all(BatshSpacing.md),
          decoration: BoxDecoration(
            color: selected
                ? primary
                : context.colorScheme.surfaceContainerLowest,
            borderRadius: BatshRadius.brXl,
            border: Border.all(
              color: selected ? primary : context.colorScheme.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected ? BatshShadows.subtle : BatshShadows.none,
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? context.colorScheme.onPrimary.withValues(alpha: 0.16)
                      : context.colorScheme.primaryContainer,
                  borderRadius: BatshRadius.brMd,
                ),
                child: Icon(_icon, color: foreground, size: 21),
              ),
              const SizedBox(width: BatshSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: BatshTypography.labelLg.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: BatshSpacing.xxs),
                    Text(
                      _description(context),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: BatshTypography.bodySm.copyWith(color: secondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: BatshSpacing.xs),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? context.colorScheme.onPrimary : secondary,
                size: 19,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedKindNote extends StatelessWidget {
  const _SelectedKindNote({required this.kind});

  final CommunityPostKind kind;

  String _description(BuildContext context) {
    switch (kind) {
      case CommunityPostKind.standard:
        return context.l10n.communityPostKindStandardDescription;
      case CommunityPostKind.beforeAfter:
        return context.l10n.communityPostKindBeforeAfterDescription;
      case CommunityPostKind.tips:
        return context.l10n.communityPostKindTipsDescription;
      case CommunityPostKind.experiences:
        return context.l10n.communityPostKindExperiencesDescription;
      case CommunityPostKind.question:
        return context.l10n.communityPostKindQuestionDescription;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(
        horizontal: BatshSpacing.md,
        vertical: BatshSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: context.colorScheme.secondaryContainer.withValues(alpha: 0.72),
        borderRadius: BatshRadius.brLg,
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 19,
            color: context.colorScheme.secondary,
          ),
          const SizedBox(width: BatshSpacing.sm),
          Expanded(
            child: Text(
              _description(context),
              textAlign: TextAlign.right,
              style: BatshTypography.bodySm.copyWith(
                color: context.colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreatePostEditor extends StatelessWidget {
  const _CreatePostEditor({
    required this.controller,
    required this.hint,
    required this.selectedKind,
    required this.selectedImages,
    required this.onPickImages,
    required this.onRemoveImage,
  });

  final TextEditingController controller;
  final String hint;
  final CommunityPostKind selectedKind;
  final List<Uint8List> selectedImages;
  final VoidCallback onPickImages;
  final ValueChanged<int> onRemoveImage;

  @override
  Widget build(BuildContext context) {
    final isBeforeAfter = selectedKind == CommunityPostKind.beforeAfter;
    return Container(
      padding: const EdgeInsets.all(BatshSpacing.md),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerLowest,
        borderRadius: BatshRadius.brXxl,
        border: Border.all(color: context.colorScheme.outlineVariant),
        boxShadow: BatshShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.colorScheme.primaryContainer,
                  borderRadius: BatshRadius.brMd,
                ),
                child: Icon(
                  Icons.draw_outlined,
                  size: 20,
                  color: context.colorScheme.primary,
                ),
              ),
              const SizedBox(width: BatshSpacing.sm),
              Expanded(
                child: Text(
                  context.l10n.communityWritePostTitle,
                  textAlign: TextAlign.right,
                  style: BatshTypography.titleMd.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: BatshSpacing.sm),
          BatshTextField(
            controller: controller,
            hint: hint,
            maxLines: 6,
            maxLength: 2000,
            semanticLabel: context.l10n.communityWritePostTitle,
          ),
          const SizedBox(height: BatshSpacing.md),
          if (selectedImages.isNotEmpty) ...[
            SizedBox(
              height: 112,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: selectedImages.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: BatshSpacing.sm),
                itemBuilder: (_, i) => Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BatshRadius.brLg,
                      child: Image.memory(
                        selectedImages[i],
                        width: 112,
                        height: 112,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Semantics(
                        button: true,
                        label: context.l10n.removePhoto,
                        child: GestureDetector(
                          onTap: () => onRemoveImage(i),
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.all(BatshSpacing.sm),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: context.colorScheme.error,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                size: BatshIconSize.sm,
                                color: context.colorScheme.onError,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: BatshSpacing.sm),
          ],
          _MediaAction(
            label: isBeforeAfter
                ? context.l10n.communityPostKindBeforeAfterDescription
                : context.l10n.addMedia,
            icon: isBeforeAfter
                ? Icons.compare_arrows_outlined
                : Icons.add_photo_alternate_outlined,
            onTap: onPickImages,
          ),
          if (isBeforeAfter && selectedImages.length < 2) ...[
            const SizedBox(height: BatshSpacing.sm),
            Text(
              context.l10n.communityBeforeAfterNeedsImages,
              textAlign: TextAlign.right,
              style: BatshTypography.labelSm.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MediaAction extends StatelessWidget {
  const _MediaAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BatshPressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: BatshSpacing.md),
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          borderRadius: BatshRadius.brLg,
          border: Border.all(color: context.colorScheme.outline),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.colorScheme.primaryContainer,
                borderRadius: BatshRadius.brMd,
              ),
              child: Icon(icon, color: context.colorScheme.primary, size: 19),
            ),
            const SizedBox(width: BatshSpacing.sm),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: BatshTypography.labelLg.copyWith(
                  color: context.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: BatshSpacing.sm),
            Icon(
              Icons.chevron_left_rounded,
              color: context.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
