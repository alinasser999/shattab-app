import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/l10n/strings.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.captionRequired)),
      );
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

      await ref.read(postControllerProvider.notifier).createPost(
        authorId: session.user.id,
        authorRole: session.user.userMetadata?['role'] as String? ?? 'homeowner',
        postType: (_selectedType ?? PostType.renovationUpdate).dbValue,
        caption: caption,
        mediaUrls: urls,
      );

      if (mounted) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) Navigator.of(context).pop();
        });
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: BatshSuccessCheckmark(message: S.postCreated),
          ),
        );
        if (mounted) context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.unknownErrorRetry)),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(currentSessionProvider);
    final isContractor =
        session?.user.userMetadata?['role'] == 'contractor';

    return BatshScaffold(
      title: S.createPost,
      actions: [
        TextButton(
          onPressed: (_uploading || _captionCtrl.text.trim().isEmpty)
              ? null
              : _submit,
          child: _uploading
              ? const BatshShimmerBox(width: 40, height: 16)
              : Text(S.postComment, style: TextStyle(color: BatshColors.primary)),
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(BatshSpacing.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isContractor) ...[
              Text(S.postTypeLabel, style: BatshTypography.labelMd),
              const SizedBox(height: BatshSpacing.sm),
              Wrap(
                spacing: BatshSpacing.sm,
                runSpacing: BatshSpacing.sm,
                children: PostType.values
                    .where((t) => t != PostType.renovationUpdate)
                    .map((t) => ChoiceChip(
                          label: Text(_typeLabel(t)),
                          selected: _selectedType == t,
                          onSelected: (_) => setState(() => _selectedType = t),
                        ))
                    .toList(),
              ),
              const SizedBox(height: BatshSpacing.gutter),
            ],
            BatshTextField(
              controller: _captionCtrl,
              hint: S.postCaptionHint,
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
                        child: GestureDetector(
                          onTap: () => _removeImage(i),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: BatshColors.error,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                size: 14, color: BatshColors.onError),
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
              label: Text(S.addMedia),
            ),
          ],
        ),
      ),
    );
  }

  String _typeLabel(PostType t) {
    switch (t) {
      case PostType.projectShowcase: return S.postTypeProjectShowcase;
      case PostType.tip: return S.postTypeTip;
      case PostType.milestone: return S.postTypeMilestone;
      case PostType.renovationUpdate: return S.postTypeRenovationUpdate;
    }
  }
}
