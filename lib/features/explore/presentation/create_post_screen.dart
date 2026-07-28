import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:batsh/core/l10n/l10n_extension.dart';
import '../../../core/theme/batsh_colors.dart';
import '../../../core/theme/batsh_radius.dart';
import '../../../core/theme/batsh_spacing.dart';
import '../../../core/theme/batsh_typography.dart';
import '../../../core/widgets/batsh_scaffold.dart';
import '../../../core/widgets/batsh_shimmer.dart';
import '../../../core/widgets/batsh_success_checkmark.dart';
import '../../../core/widgets/batsh_text_field.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../data/post_repository.dart';
import '../domain/post.dart';
import 'providers/explore_providers.dart';
import '../../../core/theme/batsh_icon_size.dart';
import '../../../core/widgets/batsh_snack.dart';

import 'package:batsh/core/theme/theme_extension.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _captionCtrl = TextEditingController();
  final _picker = ImagePicker();
  PostType? _selectedType;
  List<Uint8List> _selectedImages = [];
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    // Re-evaluate the header Post button's enabled state while typing.
    _captionCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final files = await _picker.pickMultiImage();
    if (files.isEmpty) return;
    final bytes = <Uint8List>[];
    for (final f in files) {
      final original = await f.readAsBytes();
      final compressed = await FlutterImageCompress.compressWithList(
        original,
        minWidth: 1200,
        minHeight: 1200,
        quality: 75,
      );
      bytes.add(compressed);
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
            postType: (_selectedType ?? PostType.renovationUpdate).dbValue,
            caption: caption,
            mediaUrls: urls,
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
    final profile = ref.watch(currentProfileProvider).value;
    final isContractor = profile?.role.name == 'contractor';

    return BatshScaffold(
      title: context.l10n.createPost,
      actions: [
        TextButton(
          onPressed: (_uploading || _captionCtrl.text.trim().isEmpty)
              ? null
              : _submit,
          child: _uploading
              ? const BatshShimmerBox(width: 40, height: 16)
              : Text(
                  context.l10n.postComment,
                  style: TextStyle(color: context.colorScheme.primary),
                ),
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(BatshSpacing.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isContractor) ...[
              Text(context.l10n.postTypeLabel, style: BatshTypography.labelMd),
              const SizedBox(height: BatshSpacing.sm),
              Wrap(
                spacing: BatshSpacing.sm,
                runSpacing: BatshSpacing.sm,
                children: PostType.values
                    .where((t) => t != PostType.renovationUpdate)
                    .map(
                      (t) => ChoiceChip(
                        label: Text(_typeLabel(t)),
                        selected: _selectedType == t,
                        onSelected: (_) => setState(() => _selectedType = t),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: BatshSpacing.gutter),
            ],
            BatshTextField(
              controller: _captionCtrl,
              hint: context.l10n.postCaptionHint,
              maxLines: 5,
              maxLength: 2000,
            ),
            const SizedBox(height: BatshSpacing.gutter),
            if (_selectedImages.isNotEmpty) ...[
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: BatshSpacing.sm),
                  itemBuilder: (_, i) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BatshRadius.brMd,
                        child: Image.memory(
                          _selectedImages[i],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        // The visible dot stays small, but padding inside an
                        // opaque hit test grows the tap target to ~40px. At the
                        // drawn size alone it was near 20px — half the minimum,
                        // for an action that destroys a photo.
                        child: Semantics(
                          button: true,
                          label: context.l10n.removePhoto,
                          child: GestureDetector(
                            onTap: () => _removeImage(i),
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
            OutlinedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.add_photo_alternate),
              label: Text(context.l10n.addMedia),
            ),
          ],
        ),
      ),
    );
  }

  String _typeLabel(PostType t) {
    switch (t) {
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
